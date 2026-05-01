from __future__ import annotations

import asyncio
from typing import Optional

from loguru import logger

from trading_system.config.settings import settings


class IBKRClient:
    """
    Singleton IBKR connection manager using ib_insync.

    Run ib.run() in a daemon thread to keep the event loop alive:
        import threading
        from ib_insync import util
        def _run(): util.patchAsyncio(); ibkr_client.connect(); ibkr_client.ib.run()
        threading.Thread(target=_run, daemon=True).start()

    All reqHistoricalData / reqMktData calls from other threads work synchronously
    because ib_insync uses asyncio.run_coroutine_threadsafe internally.
    """

    def __init__(self) -> None:
        from ib_insync import IB
        self.ib = IB()
        self._connected = False
        self._reconnect_base_delay = 2.0
        self._max_reconnect_attempts = 10
        self._setup_callbacks()

    def _setup_callbacks(self) -> None:
        self.ib.disconnectedEvent += self._on_disconnect
        self.ib.errorEvent += self._on_error

    def _on_disconnect(self) -> None:
        logger.warning("IBKR disconnected — scheduling reconnect")
        self._connected = False
        asyncio.ensure_future(self._reconnect_loop())

    def _on_error(
        self, req_id: int, error_code: int, error_string: str, contract
    ) -> None:
        # 1100/1300: connection lost (expected on TWS restart)
        # 1102: connection restored by TWS
        # 502: cannot connect to TWS
        # 10197: no security definition found
        if error_code in (1100, 1300):
            logger.warning(f"IBKR error {error_code}: {error_string}")
        elif error_code == 1102:
            logger.info("IBKR connection restored by TWS")
            self._connected = True
        elif error_code == 502:
            logger.error("IBKR: cannot connect to TWS — is it running on the correct port?")
        else:
            logger.error(
                f"IBKR error reqId={req_id} code={error_code}: {error_string}"
            )

    async def _reconnect_loop(self) -> None:
        delay = self._reconnect_base_delay
        for attempt in range(1, self._max_reconnect_attempts + 1):
            logger.info(
                f"Reconnect attempt {attempt}/{self._max_reconnect_attempts} in {delay:.0f}s"
            )
            await asyncio.sleep(delay)
            try:
                await self.connect_async()
                return
            except Exception as exc:
                logger.error(f"Reconnect attempt {attempt} failed: {exc}")
                delay = min(delay * 2, 120.0)
        logger.critical(
            "Exhausted IBKR reconnect attempts. Manual restart required."
        )

    def connect(self) -> None:
        """Synchronous connect — use at startup before event loop starts."""
        self.ib.connect(
            host=settings.ibkr_host,
            port=settings.ibkr_port,
            clientId=settings.ibkr_client_id,
            timeout=20,
            readonly=False,
        )
        self._connected = True
        logger.info(
            f"Connected to IBKR at {settings.ibkr_host}:{settings.ibkr_port} "
            f"(clientId={settings.ibkr_client_id})"
        )

    async def connect_async(self) -> None:
        """Async connect — use when already inside an event loop."""
        await self.ib.connectAsync(
            host=settings.ibkr_host,
            port=settings.ibkr_port,
            clientId=settings.ibkr_client_id,
            timeout=20,
            readonly=False,
        )
        self._connected = True
        logger.info(
            f"Connected to IBKR (async) at {settings.ibkr_host}:{settings.ibkr_port}"
        )

    def disconnect(self) -> None:
        self.ib.disconnect()
        self._connected = False
        logger.info("Disconnected from IBKR")

    @property
    def connected(self) -> bool:
        return self._connected and self.ib.isConnected()

    def get_account_summary(self) -> dict[str, str]:
        values = self.ib.accountSummary()
        return {v.tag: v.value for v in values}

    def get_account_values(self) -> dict[str, str]:
        """Returns account values filtered to BASE, USD, and HKD currencies."""
        values = self.ib.accountValues()
        return {
            f"{v.tag}_{v.currency}": v.value
            for v in values
            if v.currency in ("USD", "HKD", "BASE")
        }

    def get_equity(self) -> float:
        """Returns net liquidation value (total equity) in account currency."""
        summary = self.get_account_summary()
        val = summary.get("NetLiquidation", "0")
        try:
            return float(val)
        except ValueError:
            return 0.0

    def get_min_tick(self, contract) -> float:
        """Fetch the minimum price increment for a contract via reqContractDetails."""
        details = self.ib.reqContractDetails(contract)
        if details:
            return details[0].minTick
        raise ValueError(f"No contract details found for {contract.symbol}")


# Module-level singleton — imported everywhere
ibkr_client = IBKRClient()
