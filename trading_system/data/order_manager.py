from __future__ import annotations

from typing import Optional

from loguru import logger

from .ibkr_client import ibkr_client


class OrderManager:
    """
    Thin wrapper around ib_insync order placement.
    All orders go through this class. Phase 1 targets paper account only.
    """

    def place_bracket_order(
        self,
        contract,
        action: str,           # "BUY" or "SELL"
        quantity: float,
        entry_price: float,
        stop_price: float,
        take_profit_price: float,
    ) -> list:
        """
        Place a bracket order: entry limit + take-profit limit + stop-loss stop.
        Returns list of IBTrade objects (one per child order).
        """
        bracket = ibkr_client.ib.bracketOrder(
            action=action,
            quantity=quantity,
            limitPrice=entry_price,
            takeProfitPrice=take_profit_price,
            stopLossPrice=stop_price,
        )
        trades = []
        for order in bracket:
            trade = ibkr_client.ib.placeOrder(contract, order)
            trades.append(trade)
            logger.info(
                f"Placed order {order.orderId} {action} {quantity} "
                f"{contract.symbol} @ {entry_price} | SL={stop_price} | TP={take_profit_price}"
            )
        return trades

    def place_limit_order(
        self,
        contract,
        action: str,
        quantity: float,
        limit_price: float,
    ) -> object:
        """Place a standalone limit order. Returns IBTrade."""
        from ib_insync import LimitOrder
        order = LimitOrder(action, quantity, limit_price)
        trade = ibkr_client.ib.placeOrder(contract, order)
        logger.info(
            f"Placed limit order {trade.order.orderId} {action} "
            f"{quantity} {contract.symbol} @ {limit_price}"
        )
        return trade

    def cancel_order(self, trade) -> None:
        ibkr_client.ib.cancelOrder(trade.order)
        logger.info(f"Cancelled order {trade.order.orderId}")

    def cancel_all_for_contract(self, contract) -> None:
        """Cancel all open orders for a given contract."""
        for trade in ibkr_client.ib.openTrades():
            if trade.contract.symbol == contract.symbol:
                self.cancel_order(trade)

    def get_open_orders(self) -> list:
        return ibkr_client.ib.openTrades()

    def get_positions(self) -> list:
        return ibkr_client.ib.positions()

    def is_flat(self, symbol: Optional[str] = None) -> bool:
        """Returns True if there are no open positions (and no pending orders)."""
        positions = self.get_positions()
        if symbol:
            positions = [p for p in positions if p.contract.symbol == symbol]
        return len(positions) == 0


order_manager = OrderManager()
