from __future__ import annotations

from datetime import date, datetime, time, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from . import auth, db, models, schemas

router = APIRouter(prefix="/cash-drawer", tags=["cash-drawer"])
COLOMBIA_TZ = ZoneInfo("America/Bogota")


def _bounds(day: date) -> tuple[datetime, datetime]:
    start = datetime.combine(day, time.min, tzinfo=COLOMBIA_TZ)
    return start, start + timedelta(days=1)


def _cash_sales_total(db_session: Session, user_id: int, day: date) -> Decimal:
    start, end = _bounds(day)
    total = (
        db_session.query(func.coalesce(func.sum(models.Sale.total), 0))
        .filter(
            models.Sale.registered_by_user_id == user_id,
            models.Sale.payment_method == "cash",
            models.Sale.created_at >= start,
            models.Sale.created_at < end,
        )
        .scalar()
    )
    return Decimal(total or 0)


def _summary(
    db_session: Session,
    current_user: models.User,
    business_date: date,
) -> schemas.CashDrawerSummaryOut:
    opening = (
        db_session.query(models.CashDrawerOpening)
        .filter(
            models.CashDrawerOpening.user_id == current_user.id,
            models.CashDrawerOpening.business_date == business_date,
        )
        .first()
    )
    previous_cash_sales = _cash_sales_total(
        db_session, current_user.id, business_date - timedelta(days=1)
    )
    today_cash_sales = _cash_sales_total(db_session, current_user.id, business_date)
    opening_amount = Decimal(opening.opening_amount) if opening else None
    return schemas.CashDrawerSummaryOut(
        business_date=business_date,
        initialized=opening is not None,
        opening_amount=opening_amount,
        opening_source=opening.source if opening else None,
        previous_day_cash_sales=previous_cash_sales,
        today_cash_sales=today_cash_sales,
        current_cash=(opening_amount + today_cash_sales) if opening_amount is not None else None,
    )


@router.get("/today", response_model=schemas.CashDrawerSummaryOut)
def get_today_cash_drawer(
    db_session: Session = Depends(db.get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    business_date = datetime.now(COLOMBIA_TZ).date()
    return _summary(db_session, current_user, business_date)


@router.post("/opening", response_model=schemas.CashDrawerSummaryOut)
def set_cash_drawer_opening(
    payload: schemas.CashDrawerOpeningCreate,
    db_session: Session = Depends(db.get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    business_date = datetime.now(COLOMBIA_TZ).date()
    existing = (
        db_session.query(models.CashDrawerOpening)
        .filter(
            models.CashDrawerOpening.user_id == current_user.id,
            models.CashDrawerOpening.business_date == business_date,
        )
        .first()
    )
    if existing:
        return _summary(db_session, current_user, business_date)

    source = payload.source.strip().lower()
    if source == "previous_cash_sales":
        amount = _cash_sales_total(
            db_session, current_user.id, business_date - timedelta(days=1)
        )
    elif source == "manual":
        if payload.opening_amount is None:
            raise HTTPException(status_code=400, detail="Ingresa el monto inicial en efectivo")
        amount = Decimal(payload.opening_amount)
    else:
        raise HTTPException(status_code=400, detail="Origen de monto inicial inválido")

    db_session.add(
        models.CashDrawerOpening(
            user_id=current_user.id,
            business_date=business_date,
            opening_amount=amount,
            source=source,
        )
    )
    db_session.commit()
    return _summary(db_session, current_user, business_date)
