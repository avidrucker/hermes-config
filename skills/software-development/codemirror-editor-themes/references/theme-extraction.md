# Theme Extraction from Shiki

## Background Location

Shiki themes store background color in two places:

### 1. Root-level `bg` property
Most built-in Shiki themes (github-dark, dracula, monokai, etc.):
```json
{
  "bg": "#24292e",
  "fg": "#c9d1d9",
  "settings": [...]
}
```

### 2. First rule's `background` setting
Custom TextMate themes (retro-console, etc.):
```json
{
  "name": "retro-console-dark",
  "settings": [
    { "settings": { "background": "#233501", "foreground": "#d0cf9d" } },
    { "scope": ["comment"], "settings": { "foreground": "#446710" } }
  ]
}
```

## Extraction Function

```javascript
function getThemeBackground(themeObj) {
  if (!themeObj) return null;
  if (themeObj.bg) return themeObj.bg;
  const rules = themeObj.settings || themeObj.tokenColors || [];
  for (const rule of rules) {
    const s = rule && rule.settings;
    if (s && s.background) return s.background;
  }
  return null;
}
```

## Foreground Extraction

Same pattern — check `themeObj.fg` first, then `settings[0].settings.foreground`.
