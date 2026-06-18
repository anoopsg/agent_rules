---
trigger: auto
description: >
  Flutter UI performance guidelines. Apply when
  optimizing rendering performance or reviewing
  widget build methods.
---

# Flutter Performance

- Use `const` constructors everywhere possible.
- Keep `build()` pure and lightweight — split large
  widgets into smaller `StatelessWidget` subclasses.
  Never create widgets inline (e.g., `List.generate`);
  extract to separate classes.
- Avoid `setState` that rebuilds the entire tree;
  scope to the smallest subtree. Prefer
  `ValueNotifier` + `ValueListenableBuilder` for
  simple local state.
- Use `ListView.builder` or `CustomScrollView` for
  long lists. Use `itemExtent` or `prototypeItem`
  for better scroll performance.
- Wrap expensive-to-paint widgets in
  `RepaintBoundary`.
- Minimize `saveLayer()` triggers: avoid `Opacity`
  (use colors with alpha), `ClipRRect`, `ShaderMask`.
- Avoid `MediaQuery.of(context).size` if only
  width/height is needed; use `LayoutBuilder`.
- Use `precacheImage` for assets needed immediately
  on the next screen.
- Use `cacheWidth` / `cacheHeight` on `Image` to
  decode at display size, not full resolution.
- Prefer `SvgPicture.asset` over
  `SvgPicture.network`. Use
  `fadeInDuration: Duration.zero` on
  `CachedNetworkImage` when fade isn't needed.
- Never perform heavy computation (JSON parsing,
  sorting large lists) on the main isolate — use
  `compute()` or `Isolate.run()`.
- Avoid `GlobalKey` unless strictly necessary
  (e.g., `FormState`). They prevent framework
  optimizations.
