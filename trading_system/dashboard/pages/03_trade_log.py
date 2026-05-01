"""Trade Log — full trade history with P&L in R multiples."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import streamlit as st
from datetime import date, timedelta
from style import inject_global_css, metric_card, sidebar_logo

st.set_page_config(page_title="Trade Log · TradeBox", layout="wide")
inject_global_css()
sidebar_logo()

st.markdown(
    "<h1 style='margin-bottom:4px;'>Trade Log</h1>"
    "<p style='color:#475569;margin-top:0;margin-bottom:24px;font-size:14px;'>"
    "Full trade history · P&amp;L in R multiples · Daily performance</p>",
    unsafe_allow_html=True,
)

# ── Summary metrics ──
c1, c2, c3, c4 = st.columns(4, gap="medium")
with c1:
    st.markdown(metric_card("Total Trades", "0", "🔁", "purple"), unsafe_allow_html=True)
with c2:
    st.markdown(metric_card("Win Rate", "—", "🎯", "green"), unsafe_allow_html=True)
with c3:
    st.markdown(metric_card("Total P&L", "—", "💰", "cyan"), unsafe_allow_html=True)
with c4:
    st.markdown(metric_card("Avg R", "—", "📊", "yellow"), unsafe_allow_html=True)

st.markdown("<div style='margin:24px 0 0 0;'></div>", unsafe_allow_html=True)

# ── Filters ──
st.markdown(
    """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:20px 24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:16px;">Filters</div>
""",
    unsafe_allow_html=True,
)
f1, f2, f3, f4 = st.columns(4)
with f1:
    date_from = st.date_input("From", value=date.today() - timedelta(days=30), label_visibility="visible")
with f2:
    date_to = st.date_input("To", value=date.today(), label_visibility="visible")
with f3:
    symbol_filter = st.selectbox("Symbol", ["All", "MHI", "MGC", "MCL"])
with f4:
    status_filter = st.selectbox("Status", ["All", "open", "closed", "cancelled"])
st.markdown("</div>", unsafe_allow_html=True)

st.markdown("<div style='margin:16px 0 0 0;'></div>", unsafe_allow_html=True)

# ── Trade table ──
st.markdown(
    """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:16px;">Trades</div>
""",
    unsafe_allow_html=True,
)
st.dataframe(
    data=[],
    column_config={
        "open_time":   st.column_config.DatetimeColumn("Opened"),
        "close_time":  st.column_config.DatetimeColumn("Closed"),
        "symbol":      st.column_config.TextColumn("Symbol"),
        "direction":   st.column_config.TextColumn("Dir"),
        "setup_type":  st.column_config.TextColumn("Setup"),
        "entry_price": st.column_config.NumberColumn("Entry", format="%.2f"),
        "close_price": st.column_config.NumberColumn("Exit", format="%.2f"),
        "lots":        st.column_config.NumberColumn("Qty", format="%.1f"),
        "pnl":         st.column_config.NumberColumn("P&L $", format="%.2f"),
        "pnl_r":       st.column_config.NumberColumn("P&L R", format="%.2f R"),
        "status":      st.column_config.TextColumn("Status"),
        "session":     st.column_config.TextColumn("Session"),
    },
    width="stretch",
    hide_index=True,
)
st.markdown("</div>", unsafe_allow_html=True)

st.markdown("<div style='margin:16px 0 0 0;'></div>", unsafe_allow_html=True)

# ── Daily performance ──
st.markdown(
    """
<div style="background:#111827;border:1px solid #1e2d40;border-radius:14px;padding:24px;">
    <div style="color:#e2e8f0;font-size:15px;font-weight:600;margin-bottom:16px;">
        Daily Performance
    </div>
""",
    unsafe_allow_html=True,
)
st.dataframe(
    data=[],
    column_config={
        "date":           st.column_config.DateColumn("Date"),
        "daily_pnl":      st.column_config.NumberColumn("Daily P&L", format="$%.2f"),
        "trades_taken":   st.column_config.NumberColumn("Trades", format="%d"),
        "win_rate":       st.column_config.NumberColumn("Win %", format="%.1f%%"),
        "avg_r":          st.column_config.NumberColumn("Avg R", format="%.2f R"),
        "max_drawdown":   st.column_config.NumberColumn("Max DD", format="%.2f%%"),
        "ending_balance": st.column_config.NumberColumn("Balance", format="$%.2f"),
    },
    width="stretch",
    hide_index=True,
)
st.markdown("</div>", unsafe_allow_html=True)
