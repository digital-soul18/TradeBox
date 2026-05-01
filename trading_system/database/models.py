from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class AgentPrompt(Base):
    __tablename__ = "agent_prompts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    agent_name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    system_prompt: Mapped[str] = mapped_column(Text, nullable=False)
    training_docs: Mapped[Optional[str]] = mapped_column(Text)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    notes: Mapped[Optional[str]] = mapped_column(Text)


class SDZone(Base):
    __tablename__ = "sd_zones"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    timeframe: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    zone_type: Mapped[str] = mapped_column(String(10), nullable=False)  # 'supply' | 'demand'
    price_high: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    price_low: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    zone_height: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    formed_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    freshness: Mapped[str] = mapped_column(String(20), default="virgin", nullable=False)
    touch_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    strength_score: Mapped[float] = mapped_column(Numeric(5, 4), default=1.0, nullable=False)
    departure_bar_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_strong: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    deactivated_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    deactivation_reason: Mapped[Optional[str]] = mapped_column(String(100))
    formation_volume: Mapped[Optional[float]] = mapped_column(Numeric(20, 2))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class PriceGap(Base):
    __tablename__ = "price_gaps"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    timeframe: Mapped[str] = mapped_column(String(10), nullable=False)
    gap_top: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    gap_bottom: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    gap_size_atr: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))
    is_lvn: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_clear: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    detected_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Trade(Base):
    __tablename__ = "trades"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    ibkr_ticket: Mapped[Optional[str]] = mapped_column(String(50), unique=True)
    symbol: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    timeframe: Mapped[Optional[str]] = mapped_column(String(10))
    direction: Mapped[str] = mapped_column(String(5), nullable=False)   # 'long' | 'short'
    setup_type: Mapped[Optional[str]] = mapped_column(String(20))       # 'confluence' | 'gap'
    entry_price: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    stop_loss: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    take_profit: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    stop_distance: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    lots: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))
    risk_pct: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    h4_zone_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sd_zones.id"))
    m15_zone_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sd_zones.id"))
    m1_zone_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sd_zones.id"))
    gap_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("price_gaps.id"))
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False, index=True)
    open_time: Mapped[Optional[datetime]] = mapped_column(DateTime)
    close_time: Mapped[Optional[datetime]] = mapped_column(DateTime)
    close_price: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    pnl: Mapped[Optional[float]] = mapped_column(Numeric(18, 2))
    pnl_r: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))
    session: Mapped[Optional[str]] = mapped_column(String(20))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class AgentRun(Base):
    __tablename__ = "agent_runs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), default=uuid.uuid4, nullable=False, index=True
    )
    agent_name: Mapped[str] = mapped_column(String(100), nullable=False)
    symbol: Mapped[Optional[str]] = mapped_column(String(20))
    timeframe: Mapped[Optional[str]] = mapped_column(String(10))
    chart_image: Mapped[Optional[str]] = mapped_column(Text)  # base64 PNG
    prompt_version: Mapped[Optional[int]] = mapped_column(Integer)
    raw_output: Mapped[Optional[dict]] = mapped_column(JSONB)
    pattern: Mapped[Optional[str]] = mapped_column(String(100))
    confidence: Mapped[Optional[str]] = mapped_column(String(10))
    bias: Mapped[Optional[str]] = mapped_column(String(10))
    reasoning: Mapped[Optional[str]] = mapped_column(Text)
    approved: Mapped[Optional[bool]] = mapped_column(Boolean)
    duration_ms: Mapped[Optional[int]] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)


class TradeAgentRun(Base):
    __tablename__ = "trade_agent_runs"

    trade_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("trades.id"), primary_key=True
    )
    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True
    )


class PerformanceDaily(Base):
    __tablename__ = "performance_daily"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    date: Mapped[date] = mapped_column(Date, nullable=False, unique=True)
    starting_balance: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    ending_balance: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    daily_pnl: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    trades_taken: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    trades_won: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    win_rate: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    avg_r: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))
    sharpe_daily: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))
    max_drawdown: Mapped[Optional[float]] = mapped_column(Numeric(10, 4))


class PatternLabel(Base):
    __tablename__ = "pattern_labels"
    __table_args__ = (
        UniqueConstraint("symbol", "timeframe", "bar_timestamp", name="uq_pattern_label"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), nullable=False)
    timeframe: Mapped[str] = mapped_column(String(10), nullable=False)
    bar_timestamp: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    pattern: Mapped[Optional[str]] = mapped_column(String(100))
    confidence: Mapped[Optional[str]] = mapped_column(String(10))
    bias: Mapped[Optional[str]] = mapped_column(String(10))
    target_price: Mapped[Optional[float]] = mapped_column(Numeric(18, 6))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
