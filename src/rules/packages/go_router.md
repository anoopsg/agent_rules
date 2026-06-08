---
trigger: auto
description: GoRouter navigation and routing conventions (route definitions, named navigation, shell routes, auth redirects, state restoration). Apply when adding or modifying navigation, routes, or redirects in a Flutter app.
---

# Package: Go Router (Navigation & Routing)

- Implementation in `router.dart`; route definitions in `routes.dart`.
- Don't use `go_router_builder` route generation.
- Prefer `context.goNamed()` or generated route extensions for navigation.
- Use `StatefulShellRoute` for persistent bottom navigation bars.
- Handle auth logic in the `redirect` property of `GoRouter`.
- Pass IDs in paths/query params; fetch full objects at the destination.
- Use `CustomTransitionPage` for specific transition requirements.
- Always provide a `restorationId` to the router for state restoration.
- Define a `rootNavigatorKey` to allow navigation above shell routes.
