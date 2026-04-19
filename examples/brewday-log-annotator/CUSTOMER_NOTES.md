# Customer Notes

Append-only log of customer answers, verbatim. Stewarded by `researcher`.
Each entry: date, question ID (from `docs/OPEN_QUESTIONS.md`), verbatim
answer, and the conversation context.

---

## 2026-04-19 — scoping

**Customer.** Alex Keller, sole proprietor of a ~5 BBL craft brewery.

### Q-0001 — project summary (verbatim)

> "I want something I can tap on with wet hands in the brewhouse during
> a brew day to mark timestamps: grain-in, strike temp reached, mash-in,
> sparge, boil start, hop additions, whirlpool, knockout, pitch, crash,
> transfer. Plus notes (how the malt smelled, any problems). Plus gravity
> readings. At the end, it spits out a PDF that goes in my brewing
> logbook. Running on the mini-PC in the brewhouse; I open it on a
> tablet over Wi-Fi. Python, because that's what I can maintain myself
> afterwards. FastAPI, HTMX, SQLite. Done is: I can walk through one
> full brew day with it and get a PDF at the end."

### Q-0002 — SMEs

> "Craft brewing — yeah, that's needed but I know that cold. Food
> safety and licensing — probably at some point, but not for the first
> version. Web dev — I don't know the modern stuff; you'll need
> someone who knows the standards."

### Q-0003 — customer as SME

> "Brewing, yes. The rest, no."

### Q-0004 — external SMEs

> "I don't have a food-safety contact for this, and Milestone 1 doesn't
> touch licensing. Defer. Web-dev standards — just look them up; I
> don't need a human for that."

### Q-0005 — agent naming category

> "Classical composers. Bach, Nadia Boulanger, Clara Schumann, that
> kind of thing."

### Q-0006 — non-functional constraints

> "One user — me. Local network. No internet dependency, we have
> crappy Wi-Fi. I'll be tapping with wet hands, so make the buttons
> big. I don't need real-time anything. PDF printing is fine via the
> browser — I don't need a native print pipeline."
