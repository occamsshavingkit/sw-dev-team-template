# Fenced-Code TOC Fixture

This file documents the TOC convention by quoting the fence comments
**inside a fenced code block**. The strip script MUST NOT match these
as live fences (reviewer non-blocking N-1).

```markdown
<!-- TOC -->
- [Example](#example)
<!-- /TOC -->
```

## Example

Body after the code block. No live TOC fences in this file; mirror
should be byte-identical to source (plus the generation banner).
