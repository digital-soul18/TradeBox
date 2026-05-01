"""
S&D zone overlay for mplfinance charts.

mplfinance uses integer x-coordinates (0-based bar indices), NOT datetime objects.
All zone rectangles must use integer left edges computed from the DataFrame index.
"""
from __future__ import annotations

import pandas as pd
import matplotlib.patches as mpatches
from matplotlib.axes import Axes

# Colors matching the MQ4 dark palette from II_SupDemMOD
SUPPLY_STRONG_COLOR = "#004a4a"   # C'0,74,74' — dark teal
SUPPLY_WEAK_COLOR   = "#003737"   # C'0,55,55'
DEMAND_STRONG_COLOR = "#263c6c"   # C'38,60,108' — dark blue
DEMAND_WEAK_COLOR   = "#1d2f58"   # C'29,47,88'
DEAD_COLOR          = "#2a2a2a"   # dim grey

FRESHNESS_ALPHA = {
    "virgin":      0.55,
    "stale":       0.40,
    "dead":        0.20,
    "deactivated": 0.10,
}


def add_zone_rectangles(
    ax: Axes,
    df: pd.DataFrame,
    zones: list[dict],
) -> None:
    """
    Draw filled rectangles for each S&D zone on a mplfinance axis.

    Each zone dict must contain:
        zone_type:  "supply" | "demand"
        price_high: float
        price_low:  float
        freshness:  "virgin" | "stale" | "dead" | "deactivated"
        is_strong:  bool
        formed_at:  pd.Timestamp  (used to compute left edge x-position)

    The right edge of every zone extends to the last bar (current time).
    """
    if not zones:
        return

    n = len(df)
    last_x = n - 1

    # Precompute naive index for timestamp lookups
    try:
        naive_index = df.index.tz_convert(None)
    except Exception:
        naive_index = df.index

    for zone in zones:
        freshness  = zone.get("freshness", "virgin")
        is_strong  = zone.get("is_strong", False)
        zone_type  = zone["zone_type"]
        price_high = float(zone["price_high"])
        price_low  = float(zone["price_low"])
        formed_at  = zone.get("formed_at")

        # Determine left x-position from formed_at timestamp
        left_x = 0
        if formed_at is not None:
            try:
                formed_ts = pd.Timestamp(formed_at)
                if formed_ts.tzinfo is not None:
                    formed_ts = formed_ts.tz_convert(None)
                idxs = naive_index.get_indexer([formed_ts], method="nearest")
                left_x = max(0, int(idxs[0]))
            except Exception:
                left_x = 0

        width  = last_x - left_x
        height = price_high - price_low

        if width <= 0 or height <= 0:
            continue

        # Choose color based on zone type, strength, and freshness
        if freshness in ("dead", "deactivated"):
            color = DEAD_COLOR
        elif zone_type == "supply":
            color = SUPPLY_STRONG_COLOR if is_strong else SUPPLY_WEAK_COLOR
        else:
            color = DEMAND_STRONG_COLOR if is_strong else DEMAND_WEAK_COLOR

        alpha = FRESHNESS_ALPHA.get(freshness, 0.4)

        rect = mpatches.FancyBboxPatch(
            (left_x, price_low),
            width,
            height,
            boxstyle="square,pad=0",
            linewidth=0.5,
            edgecolor=color,
            facecolor=color,
            alpha=alpha,
            transform=ax.transData,
            zorder=2,
        )
        ax.add_patch(rect)

        # Short label at the right edge of each zone
        freshness_initial = freshness[0].upper()  # V / S / D / X
        zone_initial = "D" if zone_type == "demand" else "S"
        label_text = f"{zone_initial}{freshness_initial}"

        label_color = "#4db6ac" if zone_type == "demand" else "#80cbc4"
        y_pos = price_low if zone_type == "demand" else price_high
        va = "top" if zone_type == "demand" else "bottom"

        ax.annotate(
            label_text,
            xy=(last_x, y_pos),
            fontsize=6,
            color=label_color,
            alpha=min(alpha + 0.25, 1.0),
            ha="right",
            va=va,
            zorder=3,
        )
