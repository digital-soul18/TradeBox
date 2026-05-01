"""Trade Log — full trade history with P&L in R multiples."""
import streamlit as st
from datetime import date, timedelta

st.set_page_config(page_title="Trade Log", layout="wide")
st.title("📋 Trade Log")

# ── Filters ──
filter_col1, filter_col2, filter_col3, filter_col4 = st.columns(4)

with filter_col1:
    date_from = st.date_input("From", value=date.today() - timedelta(days=30))
with filter_col2:
    date_to = st.date_input("To", value=date.today())
with filter_col3:
    symbol_filter = st.selectbox("Symbol", ["All", "MHI", "MGC", "MCL"])
with filter_col4:
    status_filter = st.selectbox("Status", ["All", "open", "closed", "cancelled"])

st.divider()

# ── Trade table ──
st.subheader("Trades")
st.dataframe(
    data=[],
    column_config={
        "open_time":    st.column_config.DatetimeColumn("Open"),
        "close_time":   st.column_config.DatetimeColumn("Close"),
        "symbol":       st.column_config.TextColumn("Symbol"),
        "direction":    st.column_config.TextColumn("Dir"),
        "setup_type":   st.column_config.TextColumn("Setup"),
        "entry_price":  st.column_config.NumberColumn("Entry", format="%.2f"),
        "close_price":  st.column_config.NumberColumn("Close", format="%.2f"),
        "lots":         st.column_config.NumberColumn("Lots", format="%.2f"),
        "pnl":          st.column_config.NumberColumn("P&L $", format="%.2f"),
        "pnl_r":        st.column_config.NumberColumn("P&L R", format="%.2fR"),
        "status":       st.column_config.TextColumn("Status"),
        "session":      st.column_config.TextColumn("Session"),
    },
    use_container_width=True,
)

st.divider()

# ── Daily performance ──
st.subheader("Daily Performance")
st.dataframe(
    data=[],
    column_config={
        "date":             st.column_config.DateColumn("Date"),
        "daily_pnl":        st.column_config.NumberColumn("Daily P&L", format="%.2f"),
        "trades_taken":     st.column_config.NumberColumn("Trades"),
        "win_rate":         st.column_config.NumberColumn("Win %", format="%.1f%%"),
        "avg_r":            st.column_config.NumberColumn("Avg R", format="%.2fR"),
        "max_drawdown":     st.column_config.NumberColumn("Max DD", format="%.2f%%"),
        "ending_balance":   st.column_config.NumberColumn("Balance", format="%.2f"),
    },
    use_container_width=True,
)
