"""
TradeBox — Main Streamlit dashboard entry point.
Run with: streamlit run trading_system/dashboard/app.py
"""
import streamlit as st

st.set_page_config(
    page_title="TradeBox — Algorithmic Trading",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded",
)


def _connection_badge(label: str, connected: bool) -> None:
    if connected:
        st.sidebar.success(f"✓ {label}")
    else:
        st.sidebar.error(f"✗ {label}")


def main() -> None:
    # ── Sidebar ──
    st.sidebar.title("TradeBox")
    st.sidebar.caption("Supply & Demand Algorithmic Trading")
    st.sidebar.divider()

    st.sidebar.subheader("System Status")
    _connection_badge("IBKR Paper", False)
    _connection_badge("PostgreSQL", False)

    st.sidebar.divider()
    st.sidebar.subheader("Instrument")
    symbol = st.sidebar.selectbox("Symbol", ["MHI", "MGC", "MCL"], index=0)
    timeframe = st.sidebar.selectbox(
        "Timeframe", ["M1", "M5", "M15", "H1", "H4", "D1"], index=2
    )

    st.sidebar.divider()
    st.sidebar.subheader("Navigation")
    st.sidebar.page_link("pages/01_live_trading.py", label="📊 Live Trading")
    st.sidebar.page_link("pages/02_agent_config.py", label="🤖 Agent Config")
    st.sidebar.page_link("pages/03_trade_log.py",    label="📋 Trade Log")

    # ── Main area ──
    st.title("TradeBox — Algorithmic Trading")

    tab_overview, tab_zones, tab_perf = st.tabs(
        ["Overview", "Active Zones", "Performance"]
    )

    with tab_overview:
        st.subheader("Live Market Overview")
        col1, col2, col3, col4 = st.columns(4)
        col1.metric("Last Price",      "—")
        col2.metric("Daily P&L",       "—")
        col3.metric("Open Trades",     "—")
        col4.metric("Account Balance", "—")

        st.divider()
        st.info(
            "Connect to IBKR paper account to load live chart.\n\n"
            "Start TWS or IB Gateway on port **7497** (paper), then restart the dashboard."
        )

    with tab_zones:
        st.subheader("Active S&D Zones")
        st.caption(
            "Zones detected by the ZigZag algorithm across H4, M15, and M1 timeframes."
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
            use_container_width=True,
        )

    with tab_perf:
        st.subheader("Performance Summary")
        pcol1, pcol2, pcol3, pcol4 = st.columns(4)
        pcol1.metric("Win Rate",     "—")
        pcol2.metric("Avg R",        "—")
        pcol3.metric("Total Trades", "—")
        pcol4.metric("Max Drawdown", "—")
        st.info("Performance data will populate after your first closed trades.")


if __name__ == "__main__":
    main()
