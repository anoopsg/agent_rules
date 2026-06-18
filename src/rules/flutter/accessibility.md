---
trigger: auto
description: Flutter accessibility (a11y) guidelines. Apply when building custom UI components, handling touch targets, or addressing semantics and screen reader support.
---

# Flutter Accessibility (a11y)

- Add `Semantics` widgets for custom components lacking default semantics.
- Ensure all tappable areas meet minimum 48x48 dp touch targets.
- Use `excludeFromSemantics: true` on decorative images.
- Test with `SemanticsDebugger` and screen readers.
- Provide `tooltip` or `tooltipMessage` for `IconButton` and similar widgets.
- Ensure sufficient color contrast (WCAG AA minimum).