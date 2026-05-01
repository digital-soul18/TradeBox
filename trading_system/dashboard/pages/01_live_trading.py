"""Live Trading — chart view + order panel."""
import streamlit as st

st.set_page_config(page_title="Live Trading", layout="wide")
st.title("📊 Live Trading")

col_chart, col_panel = st.columns([2, 1])

with col_chart:
    st.subheader("Chart")
    chart_area = st.empty()
    chart_area.info(
        "No chart data — connect to IBKR paper account (TWS on port 7497).\n\n"
        "Once connected, this panel will show live candlesticks with S&D zone overlays."
    )

    st.subheader("Agent Pipeline Feed")
    st.caption("Agent decisions will stream here in real time during a trade setup.")
    st.dataframe(data=[], use_container_width=True)

with col_panel:
    st.subheader("Active Zones")
    st.empty()

    st.subheader("Order Panel")
    with st.form("order_form"):
        direction = st.selectbox("Direction", ["Long (Buy)", "Short (Sell)"])
        quantity  = st.number_input("Quantity (contracts)", min_value=1, value=1, step=1)
        entry     = st.number_input("Entry Price", min_value=0.0, format="%.2f")
        sl        = st.number_input("Stop Loss", min_value=0.0, format="%.2f")
        tp        = st.number_input("Take Profit", min_value=0.0, format="%.2f")

        submitted = st.form_submit_button(
            "Place Order (Paper)",
            disabled=True,
            help="Connect to IBKR paper account to enable order placement",
        )
        if submitted:
            st.success(f"Order submitted — {direction} {quantity} @ {entry}")
