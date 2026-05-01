"""
Zone strength scoring — port of the departure-bar counting logic in Draw() of II_SupDemMOD.

A zone is "strong" if price left it cleanly after formation with >= 2 departure bars
and <= 1 penetration bar.
"""
from __future__ import annotations

import pandas as pd
from .sd_zones import RawZone


def count_departure_bars(
    df: pd.DataFrame,
    zone: RawZone,
    max_bars_to_scan: int = 100,
) -> tuple[int, int]:
    """
    Count departure and penetration bars after zone formation.

    For a demand zone:
      departure  = bar where low > zone_top  (price left the zone cleanly above)
      penetration = bar where low < swing_low (price breached the zone bottom)

    For a supply zone:
      departure  = bar where high < zone_bottom (price left cleanly below)
      penetration = bar where high > swing_high (price breached the zone top)

    Stops scanning after departure >= 2 or penetration >= 2.

    Returns: (departure_bar_count, penetration_bar_count)
    """
    high_arr = df["high"].to_numpy()
    low_arr = df["low"].to_numpy()
    n = len(df)

    start = zone.bar_index + 1  # scan bars AFTER formation
    end_idx = min(start + max_bars_to_scan, n)

    departure = 0
    penetration = 0

    if zone.zone_type == "demand":
        zone_top = zone.price_high
        swing_low = zone.price_low
        for j in range(start, end_idx):
            if low_arr[j] > zone_top:
                departure += 1
            elif low_arr[j] < swing_low:
                penetration += 1
            if departure >= 2 or penetration >= 2:
                break
    else:  # supply
        zone_bottom = zone.price_low
        swing_high = zone.price_high
        for j in range(start, end_idx):
            if high_arr[j] < zone_bottom:
                departure += 1
            elif high_arr[j] > swing_high:
                penetration += 1
            if departure >= 2 or penetration >= 2:
                break

    return departure, penetration


def calculate_strength_score(
    departure_bar_count: int,
    max_possible: int = 10,
) -> float:
    """Normalized strength score 0.0–1.0."""
    if departure_bar_count <= 0:
        return 0.0
    return min(departure_bar_count / max_possible, 1.0)


def is_strong_zone(departure_bar_count: int, penetration_bar_count: int) -> bool:
    """A zone is strong if it has >= 2 clean departure bars and <= 1 penetration bar."""
    return departure_bar_count >= 2 and penetration_bar_count <= 1
