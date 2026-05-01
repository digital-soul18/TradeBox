"""
mplfinance chart renderer — generates base64-encoded PNG images for the Claude Vision API.

The Agg backend MUST be activated before importing pyplot.
This module does that at import time, which is safe in all contexts
(Streamlit, FastAPI, scripts) because we never display interactively.
"""
from __future__ import annotations

import base64
import io
from typing import Optional

import matplotlib
matplotlib.use("Agg")  # non-interactive backend — must be before pyplot import

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import mplfinance as mpf
import pandas as pd
from loguru import logger

from trading_system.config.settings import settings
from .zone_overlay import add_zone_rectangles

# ── Dark theme matching the MQ4 chart color scheme ──
_DARK_STYLE = mpf.make_mpf_style(
    base_mpf_style="nightclouds",
    marketcolors=mpf.make_marketcolors(
        up="#26a69a",      # teal — bullish candles
        down="#ef5350",    # red  — bearish candles
        edge="inherit",
        wick="inherit",
        volume={"up": "#26a69a", "down": "#ef5350"},
    ),
    facecolor="#131722",   # TradingView dark background
    figcolor="#131722",
    gridcolor="#1e2533",
    gridstyle="--",
    gridaxis="both",
    y_on_right=True,
)


def render_chart_to_base64(
    df: pd.DataFrame,
    symbol: str,
    timeframe: str,
    zones: Optional[list[dict]] = None,
    n_bars: int = 120,
    show_volume: bool = True,
) -> str:
    """
    Render an OHLCV candlestick chart with optional S&D zone overlays.
    Returns a base64-encoded PNG string suitable for the Claude Vision API.

    df:        DataFrame with columns open, high, low, close, volume; UTC-aware DatetimeIndex.
    zones:     List of zone dicts (zone_type, price_high, price_low, freshness, is_strong, formed_at).
    n_bars:    Number of bars to display (sliced from the right / most recent).
    """
    if df.empty:
        raise ValueError(f"Cannot render chart: DataFrame is empty for {symbol} {timeframe}")

    # Slice to the most recent n_bars
    plot_df = df.tail(n_bars).copy()

    # mplfinance needs a DatetimeIndex; convert tz-aware → naive for rendering
    if plot_df.index.tz is not None:
        plot_df.index = plot_df.index.tz_convert(None)

    fig_w = settings.chart_image_width / 100   # pixels → inches at 100 DPI
    fig_h = settings.chart_image_height / 100

    fig, axes = mpf.plot(
        plot_df,
        type="candle",
        style=_DARK_STYLE,
        volume=show_volume,
        figsize=(fig_w, fig_h),
        returnfig=True,
        panel_ratios=(4, 1),     # main chart 4× taller than volume panel
        tight_layout=True,
        datetime_format="%H:%M\n%d %b",
        xrotation=0,
        warn_too_much_data=5000,
    )

    ax_main = axes[0]

    # Overlay S&D zones onto the main price axis
    if zones:
        add_zone_rectangles(ax_main, plot_df, zones)

    ax_main.set_title(
        f"{symbol} {timeframe} — S&D Zones (UTC)",
        color="#d1d4dc",
        fontsize=11,
        pad=6,
    )

    # Render to bytes
    buf = io.BytesIO()
    fig.savefig(
        buf,
        format="png",
        dpi=100,
        bbox_inches="tight",
        facecolor=fig.get_facecolor(),
    )
    plt.close(fig)
    buf.seek(0)

    encoded = base64.b64encode(buf.read()).decode("utf-8")
    logger.debug(
        f"Chart rendered: {symbol} {timeframe} | {len(plot_df)} bars | "
        f"{len(zones or [])} zones | {len(encoded)} chars"
    )
    return encoded


def save_chart_to_file(
    df: pd.DataFrame,
    symbol: str,
    timeframe: str,
    zones: Optional[list[dict]] = None,
    path: str = "chart_debug.png",
    n_bars: int = 120,
) -> None:
    """Debug helper — renders chart and saves directly to a PNG file."""
    b64 = render_chart_to_base64(df, symbol, timeframe, zones=zones, n_bars=n_bars)
    raw = base64.b64decode(b64)
    with open(path, "wb") as f:
        f.write(raw)
    logger.info(f"Chart saved to {path} ({len(raw):,} bytes)")
