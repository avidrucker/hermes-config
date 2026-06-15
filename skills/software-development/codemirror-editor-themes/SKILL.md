---
name: codemirror-editor-themes
description: "CodeMirror 6 + Shiki theme integration for browser-based code editors and playgrounds. Covers per-theme editor backgrounds, dynamic syntax highlighting via compartments, zero-flicker theme switching, and persistent site-wide light/dark mode. Use when building a code editor/playground with CodeMirror 6 that uses Shiki themes."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [codemirror, shiki, code-editor, playground, syntax-highlighting, themes, frontend]
    related_skills: [pretext, claude-design]
---

# CodeMirror 6 + Shiki Theme Integration

Patterns for integrating **CodeMirror 6** with **Shiki themes** in browser-based code editors and playgrounds. Covers per-theme editor backgrounds, dynamic syntax highlighting, zero-flicker initialization, and persistent site-wide light/dark mode.

---

## Core Pattern: Dual Compartment Architecture

**Two separate CodeMirror compartments** — one for syntax highlighting, one for editor background.

```javascript
const highlightCompartment = new Compartment();
const backgroundCompartment = new Compartment();
```

### Why Two Compartments?
- **Syntax highlighting** changes frequently (per-token styles from Shiki theme)
- **Editor background** changes infrequently (single color per theme)
- Separating them avoids re-creating full highlight style when only background changes

---

## Extracting Theme Background from Shiki

Shiki themes store background in two places — check both:

```javascript
function getThemeBackground(themeObj) {
  if (!themeObj) return null;
  // 1. Root-level `bg` property (common in built-in Shiki themes)
  if (themeObj.bg) return themeObj.bg;
  // 2. First rule's `background` setting (used by custom TextMate themes)
  const rules = themeObj.settings || themeObj.tokenColors || [];
  for (const rule of rules) {
    const s = rule && rule.settings;
    if (s && s.background) return s.background;
  }
  return null;
}
```

### Shiki Theme Object Structure
```javascript
// Built-in theme (github-dark, dracula, etc.)
{ bg: '#24292e', fg: '#c9d1d9', settings: [...], tokenColors: [...] }

// Custom theme (retro-console-dark)
{ name: 'retro-console-dark', settings: [
  { settings: { background: '#233501', foreground: '#d0cf9d' } }, // <-- background here
  { scope: ['comment'], settings: { foreground: '#446710' } }
]}
```

See `references/theme-extraction.md` for detailed background extraction logic.

---

## Initial Editor Setup (Zero Flicker)

```javascript
// 1. Load Shiki highlighter with ALL themes upfront
const hl = await createHighlighter({
  langs: [grammar],
  themes: [...customThemes, ...builtinThemeIds]
});

// 2. Get initial theme object
const themeObj = hl.getTheme(initialThemeId);

// 3. Build initial highlight style + background
const initialHighlightStyle = buildHighlightStyle(themeObj);
const initialBackground = getThemeBackground(themeObj) || 'var(--border)';

// 4. Create editor with BOTH compartments configured
const editor = new EditorView({
  doc: starterCode,
  extensions: [
    basicSetup,
    lineNumbers(),
    myLanguage(),
    highlightCompartment.of(syntaxHighlighting(initialHighlightStyle)),
    backgroundCompartment.of(EditorView.theme({
      '.cm-content': { background: initialBackground },
      '.cm-gutters': { background: initialBackground }
    })),
    EditorView.theme({
      '.cm-content': { background: 'var(--border)', color: 'var(--fg)' },
      '.cm-gutters': { background: 'var(--border)' }
    }),
  ],
  parent: document.getElementById('editor'),
});
```

---

## Theme Change Handler

```javascript
function applyTheme(themeId) {
  applyBodyClass(themeId);  // page-level dark/light/retro

  let themeObj = null;
  try { themeObj = hl.getTheme(themeId); } catch { themeObj = null; }

  editor.dispatch({
    effects: highlightCompartment.reconfigure(
      syntaxHighlighting(buildHighlightStyle(themeObj))
    ),
  });

  const bg = getThemeBackground(themeObj);
  if (bg) {
    editor.dispatch({
      effects: backgroundCompartment.reconfigure(
        EditorView.theme({
          '.cm-content': { background: bg },
          '.cm-gutters': { background: bg }
        })
      ),
    });
  }
}

themeSelect.addEventListener('change', () => applyTheme(themeSelect.value));
applyBodyClass(initialTheme);
applyTheme(initialTheme);
```

See `references/compartment-pattern.md` for compartment architecture details.

---

## Persistent Light/Dark Mode (Site-Wide)

### 1. Inline Script in `<head>` (Flash Prevention)

```javascript
(function(){
  var DARK=["github-dark","monokai","dracula","nord","tokyo-night","slacked-night"];
  var LIGHT_ID='github-light';
  var DARK_ID='github-dark';
  function isDark(t){return DARK.indexOf(t)>=0;}  // indexOf, NOT .has()
  function pick(){
    var s=localStorage.getItem('site-theme');
    if(s)return s;
    return window.matchMedia&&window.matchMedia('(prefers-color-scheme:dark)').matches?DARK_ID:LIGHT_ID;
  }
  var t=pick();
  var cls=isDark(t)?'dark':'light';
  if(t.indexOf('retro-console')===0)cls+=' retro';
  document.documentElement.className=cls;
})();
```

**Critical:** Use `DARK.indexOf(t)>=0` not `DARK.has(t)` — inline scripts serialize arrays as JS arrays which lack `.has()`.

### 2. CSS Selectors
```css
html.dark,  body.dark  { --bg:#0d1117; --fg:#e6edf3; ... }
html.light, body.light { --bg:#f6f8fa; --fg:#24292e; ... }
```

### 3. Toggle Button + Persistence
```javascript
function apply(t) {
  var cls = (isDark(t) ? 'dark' : 'light') + (t.indexOf('retro-console') === 0 ? ' retro' : '');
  document.body.className = cls;
  document.documentElement.className = cls;
  localStorage.setItem('site-theme', t);
}
```

---

## Pitfalls & Gotchas

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Single compartment for both | Background changes reset highlight style flicker | Use two compartments |
| Only checking `themeObj.bg` | Custom themes ignore background | Check `themeObj.bg` first, then fall through to rule scanning |
| Not calling `applyBodyClass` | Page stays dark/light while editor changes | Update body class for page-level CSS variables |
| Creating editor before Shiki loads | Editor shows defaultHighlightStyle briefly | Initialize editor after `createHighlighter` resolves |
| Retro themes not working | Retro themes need special body class `.retro` | `applyBodyClass` adds `.retro` when theme ID starts with `retro-console` |
| Gutters don't match background | Gutters show different color | Include `.cm-gutters` in the `EditorView.theme` background config |
| Worktree editing in wrong copy | Build script edits don't take effect | Work in the worktree copy, not the main checkout |

---

## Verification Checklist

- [ ] All themes define background (via `bg` property or first rule `background`)
- [ ] Initial editor render shows correct theme background (no flicker)
- [ ] Theme switch updates editor background + syntax highlighting + page body class
- [ ] Gutters match editor background
- [ ] Retro themes apply full-page styling (via body class)
- [ ] No console errors on theme switch
- [ ] Site-wide toggle persists via localStorage

---

## Example Project

This pattern was developed for the **lccjs sandbox playground** (`scripts/build-site.js`):
- 11 themes (GitHub, Monokai, Dracula, Nord, Tokyo Night, Solarized, Zenburn, Retro Console)
- Zero-flicker theme switching
- Both syntax highlighting and editor background change per-theme

See `references/lccjs-showcase-implementation.md` for the full implementation reference.

---

## @todo — generalize beyond lccjs

The core patterns (compartment architecture, theme extraction, zero-flicker) are generic. The lccjs specifics are illustrative, not required:
- The "developed for the lccjs sandbox playground" framing + `scripts/build-site.js` reference are an example.
- `references/lccjs-showcase-implementation.md` documents the lccjs implementation specifically — replace with a generic example when porting.
