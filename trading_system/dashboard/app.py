"""
TradeBox — Main Streamlit dashboard entry point.
Run with: streamlit run trading_system/dashboard/app.py
"""
from __future__ import annotations

import os
import sys
import threading

# Ensure fullstack/ is on the path so trading_system imports work
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

import streamlit as st
from style import inject_global_css, metric_card, sidebar_logo, status_dot

st.set_page_config(
    page_title="TradeBox",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded",
)

inject_global_css()

# ── IBKR background thread (module-level, starts once per process) ──
_ibkr_lock = threading.Lock()
_ibkr_thread_started = False


def _ensure_ibkr_running() -> None:
    """Start the IBKR event-loop thread if not already connected or running."""
    global _ibkr_thread_started
    from trading_system.data.ibkr_client import ibkr_client

    with _ibkr_lock:
        if ibkr_client.connected:
            return
        if _ibkr_thread_started:
            return
        _ibkr_thread_started = True

    def _run() -> None:
        global _ibkr_thread_started
        try:
            import asyncio
            from ib_insync import util
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            util.patchAsyncio()
            ibkr_client.connect()
            ibkr_client.ib.run()
        except Exception:
            pass
        finally:
            with _ibkr_lock:
                _ibkr_thread_started = False

    threading.Thread(target=_run, daemon=True).start()


def _ibkr_connected() -> bool:
    try:
        from trading_system.data.ibkr_client import ibkr_client
        return ibkr_client.connected
    except Exception:
        return False


def _db_connected() -> bool:
    try:
        from sqlalchemy import text
        from trading_system.database import engine
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


@st.cache_data(ttl=60, show_spinner=False)
def _render_chart_cached(symbol: str, timeframe: str) -> tuple[str, str]:
    """Fetch OHLCV from IBKR and render to base64 PNG. Cached 60s per (symbol, timeframe)."""
    try:
        from trading_system.config.instruments import INSTRUMENTS, resolve_front_month
        from trading_system.data.historical import fetch_ohlcv
        from trading_system.data.ibkr_client import ibkr_client
        from trading_system.charting.chart_renderer import render_chart_to_base64

        contract = INSTRUMENTS[symbol]()
        contract = resolve_front_month(ibkr_client.ib, contract)
        df = fetch_ohlcv(contract, timeframe=timeframe)
        if df.empty:
            return "", f"No data returned for {symbol} {timeframe}"
        b64 = render_chart_to_base64(df, symbol, timeframe)
        return b64, ""
    except Exception as exc:
        return "", str(exc)


def main() -> None:
    _ensure_ibkr_running()

    ibkr_ok = _ibkr_connected()
    db_ok = _db_connected()

    # ── Sidebar ──
    sidebar_logo()

    st.sidebar.markdown(
        "<div style='color:#475569;font-size:11px;font-weight:600;"
        "text-transform:uppercase;letter-spacing:0.08em;"
        "padding: 0 4px 8px 4px;'>System Status</div>",
        unsafe_allow_html=True,
    )
    st.sidebar.markdown(status_dot("IBKR Paper", ibkr_ok), unsafe_allow_html=True)
    st.sidebar.markdown(status_dot("PostgreSQL", db_ok), unsafe_allow_html=True)

    if st.sidebar.button("Refresh Status", use_container_width=True):
        _render_chart_cached.clear()
        st.rerun()

    st.sidebar.markdown("<div style='margin: 16px 0 8px 0;border-top:1px solid #1a2035;'></div>", unsafe_allow_html=True)

    st.sidebar.markdown(
        "<div style='color:#475569;font-size:11px;font-weight:600;"
        "text-transform:uppercase;letter-spacing:0.08em;"
        "padding: 0 4px 8px 4px;'>Instrument</div>",
        unsafe_allow_html=True,
    )
    symbol = st.sidebar.selectbox("Symbol", ["MHI", "MGC", "MCL"], index=0, label_visibility="collapsed")
    timeframe = st.sidebar.selectbox(
        "Timeframe", ["M1", "M5", "M15", "H1", "H4", "D1"], index=2, label_visibility="collapsed"
    )

    st.sidebar.markdown("<div style='margin: 16px 0 8px 0;border-top:1px solid #1a2035;'></div>", unsafe_allow_html=True)

    st.sidebar.markdown(
        "<div style='color:#475569;font-size:11px;font-weight:600;"
        "text-transform:uppercase;letter-spacing:0.08em;"
        "padding: 0 4px 8px 4px;'>Navigation</div>",
        unsafe_allow_html=True,
    )
    st.sidebar.page_link("app.py",                   label="Dashboard",    icon="🏠")
    st.sidebar.page_link("pages/01_live_trading.py", label="Live Trading", icon="📊")
    st.sidebar.page_link("pages/02_agent_config.py", label="Agent Config", icon="🤖")
    st.sidebar.page_link("pages/03_trade_log.py",    label="Trade Log",    icon="📋")

    # ── Page header ──
    st.markdown(
        "<h1 style='margin-bottom:4px;'>Dashboard</h1>"
        "<p style='color:#475569;margin-top:0;margin-bottom:28px;font-size:14px;'>"
        f"Monitoring <b style='color:#a78bfa;'>{symbol}</b> · "
        f"<b style='color:#a78bfa;'>{timeframe}</b></p>",
        unsafe_allow_html=True,
    )

    # ── Top metric cards ──
    c1, c2, c3, c4 = st.columns(4, gap="medium")
    with c1:
        st.markdown(metric_card("Last Price", "—", "📉", "red"), unsafe_allow_html=True)
    with c2:
        st.markdown(metric_card("Daily P&L", "—", "📈", "green"), unsafe_allow_html=True)
    with c3:
        st.markdown(metric_card("Net Position", "Flat", "💼", "cyan"), unsafe_allow_html=True)
    with c4:
        st.markdown(metric_card("Account Balance", "—", "🕐", "yellow"), unsafe_allow_html=True)

    st.markdown("<div style='margin: 24px 0 0 0;'></div>", unsafe_allow_html=True)

    # ── Main content tabs ──
    tab_overview, tab_zones, tab_perf = st.tabs(["Overview", "Active Zones", "Performance"])

    with tab_overview:
        st.markdown("<div style='margin:16px 0 0 0;'></div>", unsafe_allow_html=True)

        col_left, col_right = st.columns([3, 2], gap="medium")

        with col_left:
            if not ibkr_ok:
                st.markdown(
                    """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:16px;">Live Chart</div>
    <div style="background:#0f172a;border:1px dashed #1e2d40;border-radius:10px;height:340px;
                display:flex;align-items:center;justify-content:center;flex-direction:column;gap:10px;">
        <div style="font-size:32px;">📡</div>
        <div style="color:#475569;font-size:14px;font-weight:500;">Connect to IBKR to load live chart</div>
        <div style="color:#334155;font-size:12px;">Start IB Gateway on port 4002 (paper) or TWS on 7497</div>
    </div>
</div>""",
                    unsafe_allow_html=True,
                )
            else:
                with st.spinner(f"Loading {symbol} {timeframe}…"):
                    b64, err = _render_chart_cached(symbol, timeframe)

                if err:
                    st.markdown(
                        f"""
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:12px;">Live Chart</div>
    <div style="color:#ef4444;font-size:13px;font-family:monospace;">{err}</div>
</div>""",
                        unsafe_allow_html=True,
                    )
                else:
                    st.markdown(
                        f"""
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:20px 24px 12px 24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:12px;">
        {symbol} · {timeframe}
    </div>
    <img src="data:image/png;base64,{b64}"
         style="width:100%;border-radius:8px;display:block;" />
</div>""",
                        unsafe_allow_html=True,
                    )

        with col_right:
            st.markdown(
                """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:16px;">
        Active Zones
    </div>
""",
                unsafe_allow_html=True,
            )
            for i, (label, color) in enumerate([
                ("No zones loaded", "#334155"),
            ], 1):
                st.markdown(
                    f"""
<div style="display:flex;align-items:center;justify-content:space-between;
            padding:10px 0;border-bottom:1px solid #1a2035;">
    <div style="display:flex;align-items:center;gap:10px;">
        <span style="color:#475569;font-size:13px;">{i}</span>
        <div style="width:8px;height:8px;border-radius:50%;background:{color};"></div>
        <span style="color:#94a3b8;font-size:13px;">{label}</span>
    </div>
</div>""",
                    unsafe_allow_html=True,
                )
            st.markdown(
                "<p style='color:#475569;font-size:12px;margin-top:12px;'>"
                "Zones will appear once IBKR is connected and historical data is fetched.</p>"
                "</div>",
                unsafe_allow_html=True,
            )

    with tab_zones:
        st.markdown("<div style='margin:16px 0 0 0;'></div>", unsafe_allow_html=True)
        st.markdown(
            """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:4px;">
        Active S&amp;D Zones
    </div>
    <div style="color:#475569;font-size:13px;margin-bottom:20px;">
        ZigZag zones across H4 · M15 · M1 — virgin zones only are tradeable
    </div>
""",
            unsafe_allow_html=True,
        )
        st.dataframe(
            data=[],
            column_config={
                "symbol":         st.column_config.TextColumn("Symbol"),
                "timeframe":      st.column_config.TextColumn("TF"),
                "zone_type":      st.column_config.TextColumn("Type"),
                "price_high":     st.column_config.NumberColumn("High", format="%.2f"),
                "price_low":      st.column_config.NumberColumn("Low", format="%.2f"),
                "freshness":      st.column_config.TextColumn("Freshness"),
                "is_strong":      st.column_config.CheckboxColumn("Strong"),
                "strength_score": st.column_config.NumberColumn("Score", format="%.2f"),
            },
            width="stretch",
            hide_index=True,
        )
        st.markdown("</div>", unsafe_allow_html=True)

    with tab_perf:
        st.markdown("<div style='margin:16px 0 0 0;'></div>", unsafe_allow_html=True)

        pc1, pc2, pc3, pc4 = st.columns(4, gap="medium")
        with pc1:
            st.markdown(metric_card("Win Rate", "—", "🎯", "green"), unsafe_allow_html=True)
        with pc2:
            st.markdown(metric_card("Avg R", "—", "📊", "cyan"), unsafe_allow_html=True)
        with pc3:
            st.markdown(metric_card("Total Trades", "0", "🔁", "purple"), unsafe_allow_html=True)
        with pc4:
            st.markdown(metric_card("Max Drawdown", "—", "⚠️", "red"), unsafe_allow_html=True)

        st.markdown("<div style='margin:20px 0 0 0;'></div>", unsafe_allow_html=True)
        st.markdown(
            """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;
            padding:40px 24px;text-align:center;">
    <div style="font-size:28px;margin-bottom:10px;">📋</div>
    <div style="color:#475569;font-size:14px;">
        Performance data will populate after your first closed trades.
    </div>
</div>
""",
            unsafe_allow_html=True,
        )


main()
