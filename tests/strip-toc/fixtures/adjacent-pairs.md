# Adjacent TOC Pairs

Two `<!-- TOC -->...<!-- /TOC -->` pairs separated by exactly one blank
line. Both must strip cleanly; the blank line between them is
preserved as body context (reviewer non-blocking N1).

<!-- TOC -->
- [Section A](#section-a)
<!-- /TOC -->

<!-- TOC -->
- [Section B](#section-b)
<!-- /TOC -->

## Section A

Body A.

## Section B

Body B.
