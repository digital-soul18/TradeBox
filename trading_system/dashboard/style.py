"""Shared CSS injection and HTML card helpers for the TradeBox dashboard."""
import streamlit as st


def inject_global_css() -> None:
    st.markdown(
        """
<style>
/* ── Google Font ── */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

/* ── App shell ── */
html, body, [data-testid="stApp"], .stApp {
    background-color: #0b0e18 !important;
    font-family: 'Inter', sans-serif !important;
    color: #e2e8f0 !important;
}

/* ── Sidebar ── */
[data-testid="stSidebar"] {
    background-color: #080b14 !important;
    border-right: 1px solid #1a2035 !important;
}
[data-testid="stSidebar"] * {
    color: #94a3b8 !important;
}
[data-testid="stSidebarNav"] {
    background-color: transparent !important;
}
/* Active page link highlight */
[data-testid="stSidebarNavLink"][aria-current="page"],
[data-testid="stSidebarNavLink"]:hover {
    background-color: #7c3aed !important;
    border-radius: 8px !important;
    color: #ffffff !important;
}
[data-testid="stSidebarNavLink"][aria-current="page"] *,
[data-testid="stSidebarNavLink"]:hover * {
    color: #ffffff !important;
}

/* ── Top-level headings ── */
h1, .stTitle {
    color: #f1f5f9 !important;
    font-weight: 700 !important;
    letter-spacing: -0.02em !important;
}
h2, h3 {
    color: #e2e8f0 !important;
    font-weight: 600 !important;
}

/* ── Tabs ── */
[data-testid="stTabs"] [data-baseweb="tab-list"] {
    background-color: #111827 !important;
    border-radius: 10px !important;
    padding: 4px !important;
    gap: 2px !important;
}
[data-testid="stTabs"] [data-baseweb="tab"] {
    background-color: transparent !important;
    color: #64748b !important;
    border-radius: 8px !important;
    font-weight: 500 !important;
    padding: 8px 16px !important;
}
[data-testid="stTabs"] [aria-selected="true"] {
    background-color: #7c3aed !important;
    color: #ffffff !important;
}

/* ── Selectbox ── */
[data-testid="stSelectbox"] > div > div {
    background-color: #111827 !important;
    border: 1px solid #1e2d40 !important;
    border-radius: 8px !important;
    color: #e2e8f0 !important;
}

/* ── Dataframe / table ── */
[data-testid="stDataFrame"] {
    background-color: #111827 !important;
    border-radius: 12px !important;
    border: 1px solid #1e2d40 !important;
}
[data-testid="stDataFrame"] thead tr th {
    background-color: #0f172a !important;
    color: #64748b !important;
    font-size: 12px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.05em !important;
}
[data-testid="stDataFrame"] tbody tr:hover {
    background-color: #1e2d40 !important;
}

/* ── Form elements ── */
[data-testid="stNumberInput"] input,
[data-testid="stTextInput"] input,
[data-testid="stTextArea"] textarea {
    background-color: #111827 !important;
    border: 1px solid #1e2d40 !important;
    border-radius: 8px !important;
    color: #e2e8f0 !important;
}

/* ── Buttons ── */
[data-testid="stButton"] button {
    background-color: #7c3aed !important;
    color: #ffffff !important;
    border: none !important;
    border-radius: 8px !important;
    font-weight: 500 !important;
    padding: 8px 20px !important;
}
[data-testid="stButton"] button:hover {
    background-color: #6d28d9 !important;
}
[data-testid="stButton"] button:disabled {
    background-color: #1e2d40 !important;
    color: #4b5563 !important;
}

/* ── Divider ── */
hr {
    border-color: #1a2035 !important;
    margin: 16px 0 !important;
}

/* ── Alert / info boxes ── */
[data-testid="stAlert"] {
    background-color: #111827 !important;
    border: 1px solid #1e2d40 !important;
    border-radius: 10px !important;
    color: #94a3b8 !important;
}

/* ── Caption / small text ── */
[data-testid="stCaptionContainer"] {
    color: #64748b !important;
}

/* ── Metric containers ── */
[data-testid="metric-container"] {
    background-color: #111827 !important;
    border: 1px solid #1e2d40 !important;
    border-radius: 12px !important;
    padding: 20px !important;
}
[data-testid="metric-container"] label {
    color: #64748b !important;
    font-size: 13px !important;
    font-weight: 500 !important;
    text-transform: uppercase !important;
    letter-spacing: 0.05em !important;
}
[data-testid="metric-container"] [data-testid="stMetricValue"] {
    color: #f1f5f9 !important;
    font-size: 28px !important;
    font-weight: 700 !important;
}

/* ── Scrollbar ── */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: #0b0e18; }
::-webkit-scrollbar-thumb { background: #1e2d40; border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #2d3f5a; }

/* ── File uploader ── */
[data-testid="stFileUploader"] {
    background-color: #111827 !important;
    border: 1px dashed #1e2d40 !important;
    border-radius: 10px !important;
}
</style>
""",
        unsafe_allow_html=True,
    )


def metric_card(
    label: str,
    value: str,
    icon: str,
    color: str,
    subtitle: str = "",
) -> str:
    """
    Returns HTML for a styled metric card matching the VANTAGE design.
    color: one of 'green', 'red', 'cyan', 'yellow', 'purple'
    """
    color_map = {
        "green":  "#10b981",
        "red":    "#ef4444",
        "cyan":   "#06b6d4",
        "yellow": "#f59e0b",
        "purple": "#a78bfa",
        "white":  "#f1f5f9",
    }
    hex_color = color_map.get(color, "#f1f5f9")
    subtitle_html = (
        f'<div style="color:#64748b;font-size:12px;margin-top:4px;">{subtitle}</div>'
        if subtitle
        else ""
    )
    return f"""
<div style="
    background: #111827;
    border: 1px solid #1e2d40;
    border-radius: 14px;
    padding: 22px 24px;
    height: 100%;
">
    <div style="
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 36px;
        height: 36px;
        background: {hex_color}22;
        border-radius: 8px;
        margin-bottom: 14px;
        font-size: 18px;
    ">{icon}</div>
    <div style="color:#64748b;font-size:12px;font-weight:500;
                text-transform:uppercase;letter-spacing:0.06em;margin-bottom:6px;">
        {label}
    </div>
    <div style="color:{hex_color};font-size:30px;font-weight:700;line-height:1;">
        {value}
    </div>
    {subtitle_html}
</div>
"""


def section_card(title: str, content_fn, *args, **kwargs) -> None:
    """Wraps a content function in a styled dark card."""
    st.markdown(
        f"""
<div style="
    background: #111827;
    border: 1px solid #1e2d40;
    border-radius: 14px;
    padding: 24px;
    margin-bottom: 16px;
">
    <div style="color:#e2e8f0;font-size:16px;font-weight:600;margin-bottom:16px;">
        {title}
    </div>
""",
        unsafe_allow_html=True,
    )
    content_fn(*args, **kwargs)
    st.markdown("</div>", unsafe_allow_html=True)


def sidebar_logo() -> None:
    st.sidebar.markdown(
        """
<div style="padding: 8px 0 20px 0;">
    <div style="
        display: flex;
        align-items: center;
        gap: 10px;
        margin-bottom: 4px;
    ">
        <div style="
            width: 34px; height: 34px;
            background: linear-gradient(135deg, #7c3aed, #a855f7);
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px;
        ">📈</div>
        <div>
            <div style="color:#f1f5f9;font-size:15px;font-weight:700;line-height:1.2;">
                TradeBox
            </div>
            <div style="color:#475569;font-size:11px;font-weight:500;
                        text-transform:uppercase;letter-spacing:0.08em;">
                S&amp;D Algo Trading
            </div>
        </div>
    </div>
</div>
""",
        unsafe_allow_html=True,
    )


def status_dot(label: str, connected: bool) -> str:
    color = "#10b981" if connected else "#ef4444"
    status = "Online" if connected else "Offline"
    return f"""
<div style="
    display: flex; align-items: center; justify-content: space-between;
    padding: 8px 12px;
    background: #0f172a;
    border-radius: 8px;
    margin-bottom: 6px;
    border: 1px solid #1a2035;
">
    <span style="color:#94a3b8;font-size:13px;">{label}</span>
    <div style="display:flex;align-items:center;gap:6px;">
        <div style="width:7px;height:7px;border-radius:50%;background:{color};
                    box-shadow: 0 0 6px {color};"></div>
        <span style="color:{color};font-size:12px;font-weight:500;">{status}</span>
    </div>
</div>
"""
