---
trigger: auto
description: GoRouter navigation and routing conventions (route definitions, named navigation, shell routes, auth redirects, state restoration). Apply when adding or modifying navigation, routes, or redirects in a Flutter app.
---

# Package: Go Router (Navigation & Routing)

- Implementation in `router.dart`; route definitions in `routes.dart`.
- Don't use `go_router_builder` route generation.
- Navigate by path from the route registry (`context.go(Routes.settings.path)`); never hardcode path strings.
- Use `StatefulShellRoute` for persistent bottom navigation bars.
- Put auth (logged-in/out) redirects on the `ShellRoute.redirect` of each auth group; keep the top-level `GoRouter.redirect` for app-wide gates and per-route access checks (e.g. RBAC).
- Pass IDs in paths/query params; fetch full objects at the destination.
- Use `CustomTransitionPage` for specific transition requirements.
- Always set `restorationScopeId` on the `GoRouter` for state restoration.
- Define a `rootNavigatorKey` to allow navigation above shell routes.
