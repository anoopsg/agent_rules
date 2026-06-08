---
trigger: auto
description: Flutter UI performance guidelines (const constructors, RepaintBoundary, lazy lists, lightweight build methods). Apply when optimizing Flutter rendering performance or reviewing widget build methods.
---

# Flutter Performance

- Use `const` constructors everywhere possible to reduce widget rebuilds.
- Avoid `Opacity` widget for simple transparency; use colors with alpha.
- Use `ListView.builder` or `CustomScrollView` for long lists to enable lazy loading.
- Wrap expensive-to-paint widgets in `RepaintBoundary`.
- Keep `build()` methods pure and lightweight; move logic to Notifiers/Controllers.
- Use `precacheImage` for assets needed immediately on the next screen.
- Avoid `MediaQuery.of(context).size` if only width/height is needed; use `LayoutBuilder`.
- Minimize use of `saveLayer()` (often triggered by `ClipRRect`, `Opacity`, `ShaderMask`).
- Use `itemExtent` or `prototypeItem` in `ListView` for better scroll performance.
