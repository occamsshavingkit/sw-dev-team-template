# Commented-Out Fence Forms

A second escape form (in addition to `in-code-block.md`): the TOC
fences are wrapped in an OUTER HTML comment inside a fenced code block,
which is the form documentation uses to discuss the fence convention
without it being seen as a live fence (reviewer non-blocking N2).

```markdown
<!-- <!-- TOC --> -->
- [Example](#example)
<!-- <!-- /TOC --> -->
```

The strip script MUST NOT touch the commented-out form inside the code
block (no live fence in this file; mirror = source plus banner).
