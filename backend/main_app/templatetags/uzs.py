"""Currency formatting for UZS soʻm.

Usage: {% load uzs %}  →  {{ invoice.amount|uzs }}  →  "1 200 000 soʻm"
"""
from decimal import Decimal, InvalidOperation

from django import template

register = template.Library()


@register.filter
def uzs(value, suffix="soʻm"):
    """Format a number as UZS with space-grouped thousands."""
    if value is None or value == "":
        return "—"
    try:
        amount = Decimal(value)
    except (InvalidOperation, TypeError, ValueError):
        return value
    grouped = f"{amount:,.0f}".replace(",", " ")  # narrow no-break space
    return f"{grouped} {suffix}".strip()


@register.filter
def uzs_plain(value):
    """UZS amount without the currency suffix (for inputs/tables)."""
    return uzs(value, suffix="")
