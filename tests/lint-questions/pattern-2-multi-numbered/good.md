# Good fixture — pattern 2, single-numbered customer question

One numbered prompt, then a clean atomic question:

1. Choose an OAuth provider.

Which provider should we adopt?

---

# Good fixture — pattern 2, procedural enumeration (CQG-style, issue #148)

A numbered checklist of procedural checks where each item may contain a
rhetorical `?` label. The paragraph ends with plain prose, not a terminal
customer-facing `?`. Must NOT fire pattern-2.

Before asking the customer:

1. **Customer-owned.** No agent on the roster can answer it.
2. **Is it atomic?** One decision axis only.
3. **Idle.** No dispatches in flight.
4. **Final-line.** Question is the last line.

If any check fails, queue the question internally.
