# GitHub DOM Structure for Code Highlighting (2026-06-15)

Investigated while building a Tampermonkey userscript for LCC syntax highlighting on github.com (#450).

## DOM Layout

GitHub's file viewer has used two different DOM structures:

### Classic Layout (pre-2025)
```
div.blob-wrapper
  table.highlight.tab-size.js-file-line-container[data-tab-size="2"]
    tbody
      tr
        td.blob-num.js-line-number[id="L1"][data-line-number="1"]
        td.blob-code.blob-code-inner.js-file-line[id="LC1"]
          span.pl-k  (keyword)
          span.pl-s  (string)
          span.pl-c  (comment)
```

### Current Layout (2026)
GitHub migrated to a div-based grid layout. The `table.highlight` and `div.blob-wrapper`
selectors no longer exist on file pages. Key attributes for detection:
- `[data-line-number="1"]` — present on line number elements
- `[role="row"]` — each line is a row
- `[role="rowgroup"]` — the tbody equivalent
- `[role="grid"]` — the table equivalent

## Detection Strategy

For a userscript that needs to work across both layouts:

```javascript
// Try classic layout first
const wrapper = document.querySelector('div.blob-wrapper');
if (wrapper) {
  const table = wrapper.querySelector('table.highlight');
  // ... extract from td.blob-code-inner
}

// Fallback: div-based layout
const firstLine = document.querySelector('[data-line-number="1"]');
if (firstLine) {
  const row = firstLine.closest('[role="row"]');
  const grid = row.closest('[role="grid"]');
  // ... extract from [data-line-number] elements
}
```

## Shiki Integration Notes

- Shiki's `codeToHtml()` produces `<pre class="shiki github-dark">` with inline styles
- Use `themes: ['github-dark']` to match GitHub's dark mode styling
- Grammar must be a TextMate grammar JSON (Shiki accepts directly, no build step)
- Load grammar via `GM.xmlHttpRequest` from `raw.githubusercontent.com`
- Load Shiki via dynamic `import()` from `cdn.jsdelivr.net`
- Pin the Shiki version to avoid silent breakage from CDN updates

## Maintenance Risk

GitHub can change DOM layout without notice. The userscript should:
1. Try multiple selectors (classic + current)
2. Log a warning if no code container is found
3. Not crash on unexpected DOM shapes
