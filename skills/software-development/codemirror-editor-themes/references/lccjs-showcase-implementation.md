# LCC.js Showcase Implementation Reference

This document captures the full CodeMirror 6 + Shiki theme integration as implemented in the lccjs sandbox playground (`scripts/build-site.js`).

## Theme List (11 themes)
- GitHub Light / GitHub Dark
- Monokai
- Dracula
- Nord
- Tokyo Night
- Solarized Light / Solarized Dark
- Zenburn
- Retro Console Dark / Retro Console Light

## Key Implementation Details

### Theme Loading
All 11 themes are loaded upfront via `createHighlighter()` to enable zero-flicker switching.

### Retro Console Special Handling
Retro themes require a `.retro` body class for full-page styling. The `applyBodyClass()` function detects theme IDs starting with `retro-console` and adds the class.

### Persistent Theme
The inline script in `<head>` reads `localStorage.getItem('site-theme')` and applies the class to `<html>` before the body renders, preventing flash.

### Build Script Integration
The build script (`scripts/build-site.js`) generates the sandbox page with:
- Theme selector dropdown
- Inline script for flash prevention
- All 11 theme CSS variables
- Editor initialization with dual compartments
