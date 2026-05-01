"""Agent Configuration — view and edit agent system prompts."""
import streamlit as st

st.set_page_config(page_title="Agent Config", layout="wide")
st.title("🤖 Agent Configuration")

st.caption(
    "Each agent's system prompt is stored in the `agent_prompts` table. "
    "Changes take effect immediately for the next pipeline run."
)

# Agent selector
agent_name = st.selectbox(
    "Select Agent",
    [
        "htf_agent",
        "sd_agent",
        "gap_agent",
        "candle_agent",
        "risk_agent",
        "trade_mgmt_agent",
        "executor_agent",
        "exit_agent",
        "learning_agent",
    ],
)

col_prompt, col_docs = st.columns([1, 1])

with col_prompt:
    st.subheader("System Prompt")
    prompt_text = st.text_area(
        "Prompt",
        height=350,
        placeholder="Agent prompts will be loaded from the database once connected.",
        help="This is the system prompt sent to Claude for every pipeline run.",
    )
    st.button("Save Prompt", disabled=True, help="Connect to database to enable saving")

with col_docs:
    st.subheader("Training Documents")
    st.caption(
        "Training docs are injected into the prompt at runtime. "
        "Upload the S&D strategy documentation here."
    )
    uploaded = st.file_uploader(
        "Upload training document",
        type=["pdf", "txt", "md"],
        help="This document is appended to the agent's system prompt.",
    )

st.divider()
st.subheader("Recent Agent Runs")
st.caption(f"Last 50 runs for **{agent_name}**")
st.dataframe(
    data=[],
    column_config={
        "created_at":   st.column_config.DatetimeColumn("Time"),
        "symbol":       st.column_config.TextColumn("Symbol"),
        "timeframe":    st.column_config.TextColumn("TF"),
        "approved":     st.column_config.CheckboxColumn("Approved"),
        "confidence":   st.column_config.TextColumn("Confidence"),
        "bias":         st.column_config.TextColumn("Bias"),
        "duration_ms":  st.column_config.NumberColumn("Duration (ms)"),
    },
    use_container_width=True,
)
