from __future__ import annotations

from typing import Literal, Optional

import pandas as pd
from loguru import logger

from .ibkr_client import ibkr_client

TimeframeStr = Literal["M1", "M5", "M15", "H1", "H4", "D1"]

TIMEFRAME_TO_BAR_SIZE: dict[str, str] = {
    "M1":  "1 min",
    "M5":  "5 mins",
    "M15": "15 mins",
    "H1":  "1 hour",
    "H4":  "4 hours",
    "D1":  "1 day",
}

DEFAULT_DURATION: dict[str, str] = {
    "M1":  "1 D",
    "M5":  "3 D",
    "M15": "7 D",
    "H1":  "30 D",
    "H4":  "90 D",
    "D1":  "1 Y",
}


def fetch_ohlcv(
    contract,
    timeframe: str = "M15",
    duration: Optional[str] = None,
    end_datetime: str = "",
    use_rth: bool = False,
    what_to_show: str = "TRADES",
) -> pd.DataFrame:
    """
    Fetch historical OHLCV bars from IBKR via ib_insync.

    Returns a DataFrame with columns: open, high, low, close, volume
    with a UTC-aware DatetimeIndex, sorted ascending (oldest first).

    Notes:
    - use_rth=False is required for MHI to include the afternoon session (13:00-16:30 HKT)
    - what_to_show="TRADES" is correct for futures; fall back to "MIDPOINT" if empty
    - formatDate=2 returns epoch seconds UTC
    """
    bar_size = TIMEFRAME_TO_BAR_SIZE.get(timeframe)
    if bar_size is None:
        raise ValueError(f"Unknown timeframe: {timeframe}. Valid: {list(TIMEFRAME_TO_BAR_SIZE)}")

    dur = duration or DEFAULT_DURATION[timeframe]

    bars = ibkr_client.ib.reqHistoricalData(
        contract=contract,
        endDateTime=end_datetime,
        durationStr=dur,
        barSizeSetting=bar_size,
        whatToShow=what_to_show,
        useRTH=use_rth,
        formatDate=2,        # UTC epoch seconds
        keepUpToDate=False,
    )

    if not bars:
        if what_to_show == "TRADES":
            logger.warning(
                f"No TRADES bars for {contract.symbol} {timeframe} — retrying with MIDPOINT"
            )
            return fetch_ohlcv(
                contract,
                timeframe=timeframe,
                duration=duration,
                end_datetime=end_datetime,
                use_rth=use_rth,
                what_to_show="MIDPOINT",
            )
        logger.warning(f"No historical bars returned for {contract.symbol} {timeframe}")
        return pd.DataFrame(
            columns=["open", "high", "low", "close", "volume"]
        )

    df = pd.DataFrame(
        [
            {
                "timestamp": pd.Timestamp(b.date, tz="UTC"),
                "open": b.open,
                "high": b.high,
                "low": b.low,
                "close": b.close,
                "volume": b.volume,
            }
            for b in bars
        ]
    )

    df = df.set_index("timestamp").sort_index()
    logger.info(
        f"Fetched {len(df)} bars for {contract.symbol} {timeframe} "
        f"({df.index[0]} → {df.index[-1]})"
    )
    return df
