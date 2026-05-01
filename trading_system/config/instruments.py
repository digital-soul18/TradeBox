from ib_insync import Contract


def make_mhi(contract_month: str = "") -> Contract:
    """Mini Hang Seng futures — HKEX. Note: IBKR exchange code is HKFE, not HKEX."""
    c = Contract()
    c.symbol = "MHI"
    c.secType = "FUT"
    c.exchange = "HKFE"
    c.currency = "HKD"
    if contract_month:
        c.lastTradeDateOrContractMonth = contract_month
    return c


def make_mgc(contract_month: str = "") -> Contract:
    """Micro Gold futures — COMEX."""
    c = Contract()
    c.symbol = "MGC"
    c.secType = "FUT"
    c.exchange = "COMEX"
    c.currency = "USD"
    if contract_month:
        c.lastTradeDateOrContractMonth = contract_month
    return c


def make_mcl(contract_month: str = "") -> Contract:
    """Micro Crude Oil futures — NYMEX."""
    c = Contract()
    c.symbol = "MCL"
    c.secType = "FUT"
    c.exchange = "NYMEX"
    c.currency = "USD"
    if contract_month:
        c.lastTradeDateOrContractMonth = contract_month
    return c


INSTRUMENTS = {
    "MHI": make_mhi,
    "MGC": make_mgc,
    "MCL": make_mcl,
}

# contract_month format: "YYYYMM" e.g. "202506" for June 2025
# For front-month resolution, call ib.qualifyContracts(contract) after construction
