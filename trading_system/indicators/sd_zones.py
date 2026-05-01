"""
Supply & Demand zone detection — Python port of II_SupDemMOD_DarkBG_SolidFill_Sow.mq4.

Key index convention difference:
  MQ4:    bar[0] = newest bar, bar[N] = oldest
  Python: df.iloc[0] = oldest bar, df.iloc[-1] = newest

All loops here use chronological (ascending) order — oldest → newest.

The `point` parameter is the minimum price increment for the instrument.
Fetch it from IBKR via ibkr_client.get_min_tick(contract), do NOT hardcode.
  MHI:  1.0 (HKD per index point)
  MGC:  0.10 (USD per troy oz)
  MCL:  0.01 (USD per barrel)
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

import numpy as np
import pandas as pd

ZoneType = Literal["supply", "demand"]

# ZigZag parameters from II_SupDemMOD lines 87-89
# iPeriod[4]={3,8,13,34}, Dev[4]={2,5,8,13}, Step[4]={2,3,5,8}
ZIGZAG_PERIODS = [3, 8, 13, 34]
ZIGZAG_DEVIATIONS = [2, 5, 8, 13]  # in points
ZIGZAG_BACKSTEPS = [2, 3, 5, 8]


@dataclass
class RawZone:
    zone_type: ZoneType
    price_high: float  # supply: swing high; demand: zone top (body edge)
    price_low: float   # supply: zone bottom (body edge); demand: swing low
    bar_index: int     # chronological index in the source df
    formed_at: pd.Timestamp


def count_zz(
    df: pd.DataFrame,
    depth: int,
    deviation: int,
    backstep: int,
    point: float,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Port of CountZZ() from MQ4.

    Two-pass ZigZag algorithm:
    Pass 1 — find local pivot lows and highs, apply deviation + backstep filters.
    Pass 2 — enforce alternating highs and lows (no two consecutive same-direction pivots).

    Returns (lows_buf, highs_buf):
      lows_buf[i]  > 0  → demand pivot at bar i (swing low price)
      highs_buf[i] > 0  → supply pivot at bar i (swing high price)
    """
    n = len(df)
    lows_buf = np.zeros(n, dtype=float)
    highs_buf = np.zeros(n, dtype=float)

    low_arr = df["low"].to_numpy()
    high_arr = df["high"].to_numpy()

    last_low = 0.0
    last_high = 0.0

    # ── Pass 1: local pivot detection with deviation + backstep filters ──
    for shift in range(depth, n):
        window_start = shift - depth
        window_slice_low = low_arr[window_start : shift + 1]
        window_slice_high = high_arr[window_start : shift + 1]

        # --- Low pivot ---
        val_low = float(np.min(window_slice_low))
        if val_low == last_low:
            val_low = 0.0
        else:
            last_low = val_low
            # Deviation filter: current bar's low must be close to the window minimum
            if (low_arr[shift] - val_low) > (deviation * point):
                val_low = 0.0
            else:
                # Backstep: erase earlier higher lows within backstep range
                for back in range(1, backstep + 1):
                    prev_idx = shift - back
                    if prev_idx >= 0 and lows_buf[prev_idx] != 0.0:
                        if lows_buf[prev_idx] > val_low:
                            lows_buf[prev_idx] = 0.0

        lows_buf[shift] = val_low

        # --- High pivot ---
        val_high = float(np.max(window_slice_high))
        if val_high == last_high:
            val_high = 0.0
        else:
            last_high = val_high
            if (val_high - high_arr[shift]) > (deviation * point):
                val_high = 0.0
            else:
                for back in range(1, backstep + 1):
                    prev_idx = shift - back
                    if prev_idx >= 0 and highs_buf[prev_idx] != 0.0:
                        if highs_buf[prev_idx] < val_high:
                            highs_buf[prev_idx] = 0.0

        highs_buf[shift] = val_high

    # ── Pass 2: enforce alternating highs and lows ──
    last_high_val = -1.0
    last_high_pos = -1
    last_low_val = -1.0
    last_low_pos = -1

    for shift in range(depth, n):
        cur_low = lows_buf[shift]
        cur_high = highs_buf[shift]

        if cur_low == 0.0 and cur_high == 0.0:
            continue

        if cur_high > 0.0:
            if last_high_val > 0.0:
                # Two consecutive highs — keep the higher one
                if last_high_val < cur_high:
                    highs_buf[last_high_pos] = 0.0
                else:
                    highs_buf[shift] = 0.0
                    cur_high = 0.0
            if cur_high > 0.0:
                last_high_val = cur_high
                last_high_pos = shift
                last_low_val = -1.0  # reset low tracker after a high

        if cur_low > 0.0:
            if last_low_val > 0.0:
                # Two consecutive lows — keep the lower one
                if last_low_val > cur_low:
                    lows_buf[last_low_pos] = 0.0
                else:
                    lows_buf[shift] = 0.0
                    cur_low = 0.0
            if cur_low > 0.0:
                last_low_val = cur_low
                last_low_pos = shift
                last_high_val = -1.0  # reset high tracker after a low

    return lows_buf, highs_buf


def get_valid(
    df: pd.DataFrame,
    lows_buf: np.ndarray,
    highs_buf: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Port of GetValid() from MQ4.

    Applies three filters to the raw ZigZag output:
    1. Market structure filter: demand lows must step DOWN (descending); supply highs must step UP (ascending)
    2. Zone boundary computation: establishes body-based zone edges using neighboring candle bodies
    3. Re-entry filter: removes zones that have already been re-entered by price

    Returns filtered copies of (lows_buf, highs_buf).
    """
    lows = lows_buf.copy()
    highs = highs_buf.copy()

    open_arr = df["open"].to_numpy()
    close_arr = df["close"].to_numpy()
    high_arr = df["high"].to_numpy()
    low_arr = df["low"].to_numpy()
    n = len(df)

    # ── Find first valid pivots ──
    upbar = 0   # index of first demand pivot
    dnbar = 0   # index of first supply pivot
    up_cur = 0.0
    dn_cur = 0.0

    for i in range(n):
        if lows[i] > 0.0:
            up_cur = lows[i]
            upbar = i
            break

    for i in range(n):
        if highs[i] > 0.0:
            dn_cur = highs[i]
            dnbar = i
            break

    if up_cur == 0.0 and dn_cur == 0.0:
        return lows, highs  # no pivots at all

    # ── Filter 1: market structure — demand descends, supply ascends ──
    last_up = up_cur
    last_dn = dn_cur

    for i in range(n):
        if highs[i] > 0.0:
            if highs[i] >= last_dn:
                last_dn = highs[i]
                dnbar = i
            else:
                highs[i] = 0.0

        if lows[i] > 0.0:
            if lows[i] <= last_up:
                last_up = lows[i]
                upbar = i
            else:
                lows[i] = 0.0

    # ── Zone boundary computation ──
    # Demand zone top (hi_up): body of demand pivot candle, adjusted upward by neighbor lows
    def _demand_zone_top(idx: int) -> float:
        top = min(open_arr[idx], close_arr[idx])
        if idx > 0:
            top = max(top, low_arr[idx - 1])
            top = max(top, min(open_arr[idx - 1], close_arr[idx - 1]))
        if idx + 1 < n:
            top = max(top, low_arr[idx + 1])
            top = max(top, min(open_arr[idx + 1], close_arr[idx + 1]))
        return top

    # Supply zone bottom (low_dn): body of supply pivot candle, adjusted downward by neighbor highs
    def _supply_zone_bottom(idx: int) -> float:
        bottom = max(open_arr[idx], close_arr[idx])
        if idx > 0:
            bottom = min(bottom, high_arr[idx - 1])
            bottom = min(bottom, max(open_arr[idx - 1], close_arr[idx - 1]))
        if idx + 1 < n:
            bottom = min(bottom, high_arr[idx + 1])
            bottom = min(bottom, max(open_arr[idx + 1], close_arr[idx + 1]))
        return bottom

    hi_up = _demand_zone_top(upbar)   # demand zone top for first valid demand pivot
    low_dn = _supply_zone_bottom(dnbar)  # supply zone bottom for first valid supply pivot

    # ── Filter 3: re-entry filter — walk newest→oldest ──
    # Zones that have already been re-entered by price are removed.
    # In MQ4 this walks i=start→0 (newest to oldest). In Python: range(n-1, -1, -1).
    last_dn_reentry = dn_cur
    last_up_reentry = up_cur

    for i in range(n - 1, -1, -1):
        # Supply re-entry: if this high is below the current supply zone bottom → re-entered → remove
        if highs[i] > 0.0:
            if highs[i] != last_dn_reentry and highs[i] > low_dn:
                highs[i] = 0.0
            else:
                last_dn_reentry = highs[i]
                low_dn = _supply_zone_bottom(i)

        # Demand re-entry: if this low is above the current demand zone top → re-entered → remove
        if lows[i] > 0.0:
            if lows[i] != last_up_reentry and lows[i] < hi_up:
                lows[i] = 0.0
            else:
                last_up_reentry = lows[i]
                hi_up = _demand_zone_top(i)

    return lows, highs


def _demand_zone_top(
    idx: int, open_arr: np.ndarray, close_arr: np.ndarray,
    low_arr: np.ndarray, n: int
) -> float:
    """Zone top for a demand zone: min body of pivot, nudged up by neighboring bar lows and bodies."""
    top = min(open_arr[idx], close_arr[idx])
    if idx > 0:
        top = max(top, low_arr[idx - 1])
        top = max(top, min(open_arr[idx - 1], close_arr[idx - 1]))
    if idx + 1 < n:
        top = max(top, low_arr[idx + 1])
        top = max(top, min(open_arr[idx + 1], close_arr[idx + 1]))
    return top


def _supply_zone_bottom(
    idx: int, open_arr: np.ndarray, close_arr: np.ndarray,
    high_arr: np.ndarray, n: int
) -> float:
    """Zone bottom for a supply zone: max body of pivot, nudged down by neighboring bar highs and bodies."""
    bottom = max(open_arr[idx], close_arr[idx])
    if idx > 0:
        bottom = min(bottom, high_arr[idx - 1])
        bottom = min(bottom, max(open_arr[idx - 1], close_arr[idx - 1]))
    if idx + 1 < n:
        bottom = min(bottom, high_arr[idx + 1])
        bottom = min(bottom, max(open_arr[idx + 1], close_arr[idx + 1]))
    return bottom


def build_zones(df: pd.DataFrame, point: float) -> list[RawZone]:
    """
    Run the full ZigZag → GetValid pipeline and return structured zone objects.

    Uses the primary parameter set: depth=3, deviation=2, backstep=2.
    For multi-parameter confluence (confirming zones across all 4 sets), extend this
    to run all 4 sets and intersect results — that's a Phase 2 enhancement.

    point: minimum price increment for this instrument (from IBKR reqContractDetails.minTick)
    """
    depth = ZIGZAG_PERIODS[0]      # 3
    deviation = ZIGZAG_DEVIATIONS[0]  # 2
    backstep = ZIGZAG_BACKSTEPS[0]    # 2

    lows_raw, highs_raw = count_zz(df, depth, deviation, backstep, point)
    lows_valid, highs_valid = get_valid(df, lows_raw, highs_raw)

    open_arr = df["open"].to_numpy()
    close_arr = df["close"].to_numpy()
    high_arr = df["high"].to_numpy()
    low_arr = df["low"].to_numpy()
    timestamps = df.index
    n = len(df)

    zones: list[RawZone] = []

    for i in range(n):
        # ── Demand zone ──
        if lows_valid[i] > 0.0:
            zone_top = _demand_zone_top(i, open_arr, close_arr, low_arr, n)
            swing_low = lows_valid[i]

            # Ensure zone is valid (top > bottom)
            if zone_top > swing_low:
                zones.append(
                    RawZone(
                        zone_type="demand",
                        price_high=zone_top,    # top of demand zone (body edge)
                        price_low=swing_low,    # swing low = bottom
                        bar_index=i,
                        formed_at=timestamps[i],
                    )
                )

        # ── Supply zone ──
        if highs_valid[i] > 0.0:
            zone_bottom = _supply_zone_bottom(i, open_arr, close_arr, high_arr, n)
            swing_high = highs_valid[i]

            if swing_high > zone_bottom:
                zones.append(
                    RawZone(
                        zone_type="supply",
                        price_high=swing_high,   # swing high = top
                        price_low=zone_bottom,   # zone bottom (body edge)
                        bar_index=i,
                        formed_at=timestamps[i],
                    )
                )

    return zones
