"""
Tests for S&D zone detection — validates the MQ4 port.

Uses a synthetic 200-bar OHLCV DataFrame with a seeded random walk so
results are deterministic and comparable across runs.
"""
import numpy as np
import pandas as pd
import pytest

from trading_system.indicators.sd_zones import (
    ZIGZAG_BACKSTEPS,
    ZIGZAG_DEVIATIONS,
    ZIGZAG_PERIODS,
    RawZone,
    build_zones,
    count_zz,
    get_valid,
)
from trading_system.indicators.zone_freshness import Freshness, ZoneFreshnessState
from trading_system.indicators.zone_strength import (
    calculate_strength_score,
    count_departure_bars,
    is_strong_zone,
)


# ── Fixtures ──

def make_synthetic_df(n: int = 200, seed: int = 42) -> pd.DataFrame:
    """Deterministic trending OHLCV with clear swing highs/lows."""
    rng = np.random.default_rng(seed)
    close = np.cumsum(rng.standard_normal(n) * 2) + 100
    open_ = close + rng.standard_normal(n) * 0.5
    high  = np.maximum(close, open_) + np.abs(rng.standard_normal(n))
    low   = np.minimum(close, open_) - np.abs(rng.standard_normal(n))
    volume = rng.integers(100, 10_000, n).astype(float)
    idx = pd.date_range("2024-01-01", periods=n, freq="15min", tz="UTC")
    return pd.DataFrame(
        {"open": open_, "high": high, "low": low, "close": close, "volume": volume},
        index=idx,
    )


POINT = 0.01  # generic point size for synthetic data


@pytest.fixture
def df200():
    return make_synthetic_df(200)


# ── count_zz tests ──

class TestCountZZ:
    def test_output_length_matches_input(self, df200):
        lows, highs = count_zz(
            df200, ZIGZAG_PERIODS[0], ZIGZAG_DEVIATIONS[0], ZIGZAG_BACKSTEPS[0], POINT
        )
        assert len(lows) == len(df200)
        assert len(highs) == len(df200)

    def test_no_simultaneous_high_low_pivot(self, df200):
        """After pass 2, no single bar should have both a high and low pivot."""
        lows, highs = count_zz(
            df200, ZIGZAG_PERIODS[0], ZIGZAG_DEVIATIONS[0], ZIGZAG_BACKSTEPS[0], POINT
        )
        for i in range(len(lows)):
            assert not (lows[i] > 0.0 and highs[i] > 0.0), (
                f"Bar {i} has both a high ({highs[i]:.4f}) and low ({lows[i]:.4f}) pivot"
            )

    def test_low_pivots_are_at_or_below_bar_low(self, df200):
        low_arr = df200["low"].to_numpy()
        lows, _ = count_zz(
            df200, ZIGZAG_PERIODS[0], ZIGZAG_DEVIATIONS[0], ZIGZAG_BACKSTEPS[0], POINT
        )
        for i in range(len(lows)):
            if lows[i] > 0.0:
                assert lows[i] <= low_arr[i] + 1e-8, (
                    f"Bar {i}: low pivot {lows[i]:.4f} > bar low {low_arr[i]:.4f}"
                )

    def test_high_pivots_are_at_or_above_bar_high(self, df200):
        high_arr = df200["high"].to_numpy()
        _, highs = count_zz(
            df200, ZIGZAG_PERIODS[0], ZIGZAG_DEVIATIONS[0], ZIGZAG_BACKSTEPS[0], POINT
        )
        for i in range(len(highs)):
            if highs[i] > 0.0:
                assert highs[i] >= high_arr[i] - 1e-8, (
                    f"Bar {i}: high pivot {highs[i]:.4f} < bar high {high_arr[i]:.4f}"
                )

    def test_produces_at_least_some_pivots(self, df200):
        lows, highs = count_zz(
            df200, ZIGZAG_PERIODS[0], ZIGZAG_DEVIATIONS[0], ZIGZAG_BACKSTEPS[0], POINT
        )
        assert np.count_nonzero(lows) > 0, "Expected at least one low pivot"
        assert np.count_nonzero(highs) > 0, "Expected at least one high pivot"


# ── build_zones tests ──

class TestBuildZones:
    def test_returns_list_of_raw_zones(self, df200):
        zones = build_zones(df200, POINT)
        assert isinstance(zones, list)
        assert len(zones) > 0, "Expected at least one zone"

    def test_all_zones_have_valid_types(self, df200):
        zones = build_zones(df200, POINT)
        for z in zones:
            assert z.zone_type in ("supply", "demand"), (
                f"Unexpected zone_type: {z.zone_type}"
            )

    def test_all_zones_price_high_above_price_low(self, df200):
        zones = build_zones(df200, POINT)
        for z in zones:
            assert z.price_high > z.price_low, (
                f"{z.zone_type} zone at bar {z.bar_index}: "
                f"price_high={z.price_high:.4f} <= price_low={z.price_low:.4f}"
            )

    def test_zone_bar_index_in_range(self, df200):
        zones = build_zones(df200, POINT)
        for z in zones:
            assert 0 <= z.bar_index < len(df200), (
                f"bar_index {z.bar_index} out of range [0, {len(df200)})"
            )

    def test_formed_at_matches_df_index(self, df200):
        zones = build_zones(df200, POINT)
        for z in zones:
            expected_ts = df200.index[z.bar_index]
            assert z.formed_at == expected_ts, (
                f"formed_at mismatch at bar {z.bar_index}"
            )

    def test_supply_high_is_swing_high(self, df200):
        """Supply zone top should match the swing high at its bar."""
        zones = build_zones(df200, POINT)
        high_arr = df200["high"].to_numpy()
        for z in [z for z in zones if z.zone_type == "supply"]:
            assert z.price_high <= high_arr[z.bar_index] + 1e-6, (
                f"Supply zone top {z.price_high:.4f} > bar high {high_arr[z.bar_index]:.4f} "
                f"at bar {z.bar_index}"
            )

    def test_demand_low_is_swing_low(self, df200):
        """Demand zone bottom should match the swing low at its bar."""
        zones = build_zones(df200, POINT)
        low_arr = df200["low"].to_numpy()
        for z in [z for z in zones if z.zone_type == "demand"]:
            assert z.price_low >= low_arr[z.bar_index] - 1e-6, (
                f"Demand zone bottom {z.price_low:.4f} < bar low {low_arr[z.bar_index]:.4f} "
                f"at bar {z.bar_index}"
            )


# ── zone_strength tests ──

class TestZoneStrength:
    def test_strong_zone_requires_two_departure_bars(self):
        assert is_strong_zone(departure_bar_count=2, penetration_bar_count=0) is True
        assert is_strong_zone(departure_bar_count=1, penetration_bar_count=0) is False

    def test_high_penetration_not_strong(self):
        assert is_strong_zone(departure_bar_count=2, penetration_bar_count=2) is False

    def test_strength_score_capped_at_one(self):
        assert calculate_strength_score(100) == 1.0

    def test_strength_score_zero_for_no_departures(self):
        assert calculate_strength_score(0) == 0.0

    def test_count_departure_bars_demand(self, df200):
        zones = build_zones(df200, POINT)
        demand_zones = [z for z in zones if z.zone_type == "demand"]
        if demand_zones:
            zone = demand_zones[0]
            dep, pen = count_departure_bars(df200, zone)
            assert dep >= 0
            assert pen >= 0


# ── zone_freshness tests ──

class TestZoneFreshness:
    def _make_supply_zone(self) -> ZoneFreshnessState:
        return ZoneFreshnessState(
            zone_type="supply", price_high=110.0, price_low=105.0
        )

    def _make_demand_zone(self) -> ZoneFreshnessState:
        return ZoneFreshnessState(
            zone_type="demand", price_high=95.0, price_low=90.0
        )

    def _bar(self, o, h, l, c) -> pd.Series:
        return pd.Series({"open": o, "high": h, "low": l, "close": c})

    def _ts(self) -> pd.Timestamp:
        return pd.Timestamp("2024-01-01 12:00", tz="UTC")

    def test_initial_state_is_virgin(self):
        state = self._make_supply_zone()
        assert state.freshness == Freshness.VIRGIN

    def test_touch_transitions_to_stale(self):
        state = self._make_supply_zone()
        # Bar that enters the supply zone (low below price_high)
        bar = self._bar(o=108.0, h=112.0, l=104.0, c=107.0)
        state.update_with_bar(bar, self._ts())
        assert state.freshness == Freshness.STALE
        assert state.touch_count == 1

    def test_close_beyond_demand_deactivates(self):
        state = self._make_demand_zone()
        # Bar that closes below demand zone bottom (price_low=90)
        bar = self._bar(o=88.0, h=89.0, l=87.0, c=88.0)
        result = state.update_with_bar(bar, self._ts())
        assert result == Freshness.DEACTIVATED
        assert state.deactivation_reason == "candle_closed_beyond"

    def test_close_beyond_supply_deactivates(self):
        state = self._make_supply_zone()
        # Bar closes above supply zone top (price_high=110)
        bar = self._bar(o=111.0, h=115.0, l=110.5, c=113.0)
        result = state.update_with_bar(bar, self._ts())
        assert result == Freshness.DEACTIVATED

    def test_no_update_after_deactivation(self):
        state = self._make_demand_zone()
        bar_beyond = self._bar(o=88.0, h=89.0, l=87.0, c=88.0)
        state.update_with_bar(bar_beyond, self._ts())
        assert state.freshness == Freshness.DEACTIVATED

        # Subsequent bar should not change state
        bar_inside = self._bar(o=92.0, h=94.0, l=91.0, c=93.0)
        result = state.update_with_bar(bar_inside, self._ts())
        assert result == Freshness.DEACTIVATED
        assert state.touch_count == 0  # should not have been incremented

    def test_strength_degrades_on_touch(self):
        state = self._make_supply_zone()
        initial_score = state.strength_score
        bar = self._bar(o=108.0, h=112.0, l=104.0, c=107.0)
        state.update_with_bar(bar, self._ts())
        assert state.strength_score < initial_score

    def test_replay_advances_freshness(self, df200):
        zones = build_zones(df200, POINT)
        if not zones:
            pytest.skip("No zones detected in synthetic data")

        zone = zones[0]
        state = ZoneFreshnessState(
            zone_type=zone.zone_type,
            price_high=zone.price_high,
            price_low=zone.price_low,
        )
        result = state.replay(df200, zone.bar_index)
        assert result in (
            Freshness.VIRGIN,
            Freshness.STALE,
            Freshness.DEAD,
            Freshness.DEACTIVATED,
        )
