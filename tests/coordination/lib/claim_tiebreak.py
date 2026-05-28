"""
claim_tiebreak.py — TEST-ONLY tie-break helper for the advisory claim protocol.

NOT a shipped runtime artifact. Lives under tests/coordination/lib/ only.
No network / gh calls; operates on in-memory/fixture Claim Record dicts.

Tie-break rule (docs/coordination/claim-protocol.md):
  1. Earliest UTC timestamp (ISO 8601 string, lexically comparable when zero-padded)
     wins.
  2. Equal timestamps: lexicographically lower operator id wins.

Returns the winning Claim Record dict from the supplied iterable.
Raises ValueError if claims is empty.
Order of iteration (evaluation order) does NOT affect the result — the
function is deterministic and observer-independent.
"""

from __future__ import annotations

from typing import Iterable


def resolve_winner(claims: Iterable[dict]) -> dict:
    """Return the winning claim record per the deterministic tie-break rule.

    Args:
        claims: An iterable of Claim Record dicts, each containing at minimum:
                  - "operator": str  — operator id
                  - "ts": str        — UTC ISO 8601 timestamp (e.g. "2026-05-27T18:00:00Z")

    Returns:
        The claim dict that wins the tie-break.

    Raises:
        ValueError: if claims is empty.
    """
    claim_list = list(claims)
    if not claim_list:
        raise ValueError("resolve_winner: claims must be non-empty")

    # Sort key: (ts, operator) — ascending on both; first element after sort is winner.
    # This is evaluation-order-independent: sorting is a total order over the full set.
    winner = min(claim_list, key=lambda c: (c["ts"], c["operator"]))
    return winner
