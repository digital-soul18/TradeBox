"""
Zone freshness state machine.

States (from plan spec):
  VIRGIN      → touch_count == 0, never revisited since formation   (tradeable)
  STALE       → touch_count >= 1, first touch occurred              (not tradeable)
  DEAD        → strength_score < 0.25                               (frozen visually)
  DEACTIVATED → any candle closed beyond zone boundary              (removed from active set)

Transitions:
  VIRGIN → STALE on first touch
  Any state → DEAD when strength_score drops below threshold
  Any non-deactivated state → DEACTIVATED when a candle closes beyond boundary
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

import pandas as pd

DEAD_THRESHOLD = 0.25      # strength_score below this → DEAD
STRENGTH_DECAY = 0.25      # subtracted from strength_score on each touch


class Freshness(str, Enum):
    VIRGIN = "virgin"
    STALE = "stale"
    DEAD = "dead"
    DEACTIVATED = "deactivated"


@dataclass
class ZoneFreshnessState:
    """
    Mutable freshness state for a single zone.
    Call update_with_bar() for each new candle, or replay() to fast-forward.
    """

    zone_type: str          # "supply" | "demand"
    price_high: float
    price_low: float

    freshness: Freshness = Freshness.VIRGIN
    touch_count: int = 0
    strength_score: float = 1.0
    departure_bar_count: int = 0
    deactivation_reason: Optional[str] = None
    deactivated_at: Optional[pd.Timestamp] = None

    def _is_touched(self, bar_high: float, bar_low: float) -> bool:
        """Price entered the zone rectangle."""
        return bar_low <= self.price_high and bar_high >= self.price_low

    def _closed_beyond(self, bar_open: float, bar_close: float) -> bool:
        """
        A candle closed beyond the zone boundary — deactivation trigger.
        Both open AND close must be beyond the boundary to count as a true close-beyond.
        """
        if self.zone_type == "demand":
            return bar_close < self.price_low and bar_open < self.price_low
        else:
            return bar_close > self.price_high and bar_open > self.price_high

    def update_with_bar(
        self,
        bar: pd.Series,
        bar_timestamp: pd.Timestamp,
    ) -> Freshness:
        """
        Advance the state machine for a single bar.
        Returns the resulting freshness state after processing this bar.
        """
        # Already deactivated — no further state changes
        if self.freshness == Freshness.DEACTIVATED:
            return self.freshness

        # ── Deactivation check (highest priority) ──
        if self._closed_beyond(bar["open"], bar["close"]):
            self.freshness = Freshness.DEACTIVATED
            self.deactivation_reason = "candle_closed_beyond"
            self.deactivated_at = bar_timestamp
            return self.freshness

        # ── Touch detection ──
        if self._is_touched(bar["high"], bar["low"]):
            self.touch_count += 1
            self.strength_score = max(0.0, self.strength_score - STRENGTH_DECAY)

        # ── State transitions ──
        if self.freshness == Freshness.VIRGIN and self.touch_count >= 1:
            self.freshness = Freshness.STALE

        if self.strength_score < DEAD_THRESHOLD and self.freshness != Freshness.DEAD:
            self.freshness = Freshness.DEAD

        return self.freshness

    def replay(
        self,
        df: pd.DataFrame,
        zone_bar_index: int,
    ) -> Freshness:
        """
        Fast-forward through all bars after zone formation to compute current freshness.
        df must be chronologically ordered; zone_bar_index is the formation bar's position.
        """
        for i in range(zone_bar_index + 1, len(df)):
            bar = df.iloc[i]
            ts = df.index[i]
            self.update_with_bar(bar, ts)
            if self.freshness == Freshness.DEACTIVATED:
                break
        return self.freshness

    def to_dict(self) -> dict:
        return {
            "freshness": self.freshness.value,
            "touch_count": self.touch_count,
            "strength_score": round(self.strength_score, 4),
            "is_virgin": self.freshness == Freshness.VIRGIN,
            "is_tradeable": self.freshness == Freshness.VIRGIN,
            "deactivation_reason": self.deactivation_reason,
        }
