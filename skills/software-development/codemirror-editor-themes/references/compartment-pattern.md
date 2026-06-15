# Compartment Architecture

## Why Compartments?

CodeMirror 6 extensions are immutable — you can't change them after creation. Compartments let you reconfigure a subset of extensions without recreating the entire editor.

## Dual Compartment Pattern

```javascript
const highlightCompartment = new Compartment();
const backgroundCompartment = new Compartment();
```

- `highlightCompartment` — holds `syntaxHighlighting` (token colors)
- `backgroundCompartment` — holds `EditorView.theme` for `.cm-content`/`.cm-gutters` background

## Reconfiguring on Theme Change

```javascript
// Swap syntax highlighting
editor.dispatch({
  effects: highlightCompartment.reconfigure(
    syntaxHighlighting(buildHighlightStyle(themeObj))
  ),
});

// Swap editor background
editor.dispatch({
  effects: backgroundCompartment.reconfigure(
    EditorView.theme({
      '.cm-content': { background: bg },
      '.cm-gutters': { background: bg }
    })
  ),
});
```

## Why Not One Compartment?

If you put both syntax highlighting and background in a single compartment, changing the background would also re-create the syntax highlighting, causing a visible flicker. Separating them means only the part that actually changed gets reconfigured.
