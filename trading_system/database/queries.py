from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from .models import AgentRun, SDZone, Trade


def get_active_zones(
    session: Session,
    symbol: str,
    timeframe: str,
    zone_type: Optional[str] = None,
) -> list[SDZone]:
    stmt = select(SDZone).where(
        and_(
            SDZone.symbol == symbol,
            SDZone.timeframe == timeframe,
            SDZone.is_active == True,
        )
    )
    if zone_type:
        stmt = stmt.where(SDZone.zone_type == zone_type)
    stmt = stmt.order_by(SDZone.formed_at.desc())
    return list(session.execute(stmt).scalars())


def upsert_zone(session: Session, zone: SDZone) -> SDZone:
    """Insert or update a zone — deduplicates by (symbol, timeframe, formed_at, zone_type)."""
    existing = session.execute(
        select(SDZone).where(
            and_(
                SDZone.symbol == zone.symbol,
                SDZone.timeframe == zone.timeframe,
                SDZone.formed_at == zone.formed_at,
                SDZone.zone_type == zone.zone_type,
            )
        )
    ).scalar_one_or_none()

    if existing:
        existing.price_high = zone.price_high
        existing.price_low = zone.price_low
        existing.zone_height = zone.zone_height
        existing.freshness = zone.freshness
        existing.strength_score = zone.strength_score
        existing.departure_bar_count = zone.departure_bar_count
        existing.is_strong = zone.is_strong
        existing.touch_count = zone.touch_count
        existing.is_active = zone.is_active
        return existing

    session.add(zone)
    return zone


def get_open_trades(
    session: Session,
    symbol: Optional[str] = None,
) -> list[Trade]:
    stmt = select(Trade).where(Trade.status.in_(["pending", "open"]))
    if symbol:
        stmt = stmt.where(Trade.symbol == symbol)
    return list(session.execute(stmt).scalars())


def get_daily_pnl(session: Session, date: datetime) -> float:
    """Sum P&L for all trades closed on the given date."""
    from sqlalchemy import func
    from datetime import timedelta

    day_start = date.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    result = session.execute(
        select(func.coalesce(func.sum(Trade.pnl), 0.0)).where(
            and_(
                Trade.status == "closed",
                Trade.close_time >= day_start,
                Trade.close_time < day_end,
                Trade.pnl.isnot(None),
            )
        )
    ).scalar()

    return float(result or 0.0)


def get_recent_agent_runs(
    session: Session,
    limit: int = 50,
    agent_name: Optional[str] = None,
) -> list[AgentRun]:
    stmt = select(AgentRun).order_by(AgentRun.created_at.desc()).limit(limit)
    if agent_name:
        stmt = stmt.where(AgentRun.agent_name == agent_name)
    return list(session.execute(stmt).scalars())
