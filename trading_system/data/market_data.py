from __future__ import annotations

from typing import Callable, Optional

from loguru import logger

from .ibkr_client import ibkr_client


class MarketDataManager:
    """
    Manages live tick subscriptions and 5-second real-time bars via ib_insync.
    Callbacks fire on each update inside the ib_insync event loop thread.
    """

    def __init__(self) -> None:
        self._tickers: dict[str, object] = {}
        self._rtbars: dict[str, object] = {}

    def _key(self, symbol: str, contract_month: str = "") -> str:
        return f"{symbol}_{contract_month}"

    def subscribe_ticker(
        self,
        contract,
        callback: Optional[Callable] = None,
    ) -> object:
        """
        Subscribe to live bid/ask/last tick stream.
        Returns the Ticker object (from ib_insync).
        """
        key = self._key(
            contract.symbol,
            getattr(contract, "lastTradeDateOrContractMonth", ""),
        )
        ticker = ibkr_client.ib.reqMktData(
            contract,
            genericTickList="",
            snapshot=False,
            regulatorySnapshot=False,
        )
        self._tickers[key] = ticker
        if callback:
            ticker.updateEvent += callback
        logger.info(f"Subscribed to tick stream: {contract.symbol}")
        return ticker

    def subscribe_realtime_bars(
        self,
        contract,
        callback: Optional[Callable] = None,
    ) -> object:
        """
        Subscribe to 5-second OHLCV bars via reqRealTimeBars.
        barSize is always 5 seconds — this is an IBKR limitation.
        Returns the BarDataList object.
        """
        key = f"{contract.symbol}_rtbars"
        bars = ibkr_client.ib.reqRealTimeBars(
            contract=contract,
            barSize=5,
            whatToShow="TRADES",
            useRTH=False,
        )
        self._rtbars[key] = bars
        if callback:
            bars.updateEvent += callback
        logger.info(f"Subscribed to 5s real-time bars: {contract.symbol}")
        return bars

    def get_last_price(
        self,
        symbol: str,
        contract_month: str = "",
    ) -> Optional[float]:
        key = self._key(symbol, contract_month)
        ticker = self._tickers.get(key)
        if ticker is None:
            return None
        price = getattr(ticker, "last", None) or getattr(ticker, "close", None)
        return float(price) if price else None

    def cancel_all(self) -> None:
        """Cancel all active market data subscriptions."""
        for ticker in self._tickers.values():
            try:
                ibkr_client.ib.cancelMktData(ticker.contract)
            except Exception as exc:
                logger.warning(f"Failed to cancel ticker: {exc}")

        for bars in self._rtbars.values():
            try:
                ibkr_client.ib.cancelRealTimeBars(bars)
            except Exception as exc:
                logger.warning(f"Failed to cancel real-time bars: {exc}")

        self._tickers.clear()
        self._rtbars.clear()
        logger.info("Cancelled all market data subscriptions")


market_data = MarketDataManager()
