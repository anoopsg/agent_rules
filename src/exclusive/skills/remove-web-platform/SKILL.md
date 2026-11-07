---
name: remove-web-platform
description: Removes the web platform from a project — web files and config, app_ui web widgets, *_view_web.dart views, kIsWeb branches and the web-only maintenance feature. Use when the app should become mobile-only (Android/iOS).
---

# Remove Platform Skill

This skill defines the process for completely removing all files, configurations,
and dead code associated with the web platform when the app is restricted to
mobile (Android/iOS) only.

## 1. Generate the Checklist

The project itself is the inventory. [scripts/find_web.sh](scripts/find_web.sh)
ships with this skill (not the project's `scripts/`) and lists everything web-only
that is left, grouped into the numbered sections of §3:

```bash
bash <this skill>/scripts/find_web.sh <project_dir>
```

It exits 1 while anything is left and 0 when clean (docs are listed for review
only). Work through its output section by section and re-run it until it exits 0.

**Stop and ask** before starting if the user wants to keep maintenance mode on
mobile: today it only runs on web, so this skill removes it.

## 2. Rules for Every Finding

- **Branches**: keep the mobile side and delete the condition:
  `kIsWeb ? a : b` → `b`; `if (!kIsWeb) x;` → `x;`; `if (kIsWeb) return;` → delete.
  Then remove `show kIsWeb` imports that are no longer used.
- **Shared code**: delete a symbol only when nothing non-web uses it; otherwise
  drop just its web branch or parameter. If a file mixes web and non-web parts
  (e.g. one DTO in a shared area file), remove only the web part.
- **Conditional imports**: keep `dart.library.io` ones (they select native
  code). Replace a `dart.library.js_interop` one with its plain native import.
- **Tests**: delete tests of removed code, and the web cases inside shared tests.

## 3. Work Through the Checklist

1. **Web and deploy files**: delete them (the `web/` folder, Docker/nginx files,
   the Firebase service-worker script). Projects generated without web won't
   have them.
2. **Web-only Dart files and folders**: delete each `*_web.dart` file and web
   folder (views, the web bootstrap, `app_ui`'s web library and widgets). Then fix
   whatever imported them, which shows up in section 3.
3. **Web branches and imports**: apply §2 to every hit (router, guards, app
   state, pages, `app_ui` layouts, Firebase setup and options, tests). For a web
   dependency (e.g. `flutter_web_plugins`) remove it from `pubspec.yaml` and run
   `flutter pub get`. For the web push key (VAPID), remove the argument, the
   `Environment` constant and the key in every `env/*.json`.
4. **Maintenance feature**: remove it end to end. That means the feature folder
   and its exports, its `AppState` fields and listener, its gate guard and route,
   its `maintenance` i18n section (then `melos run translate`), and its tests.
   Remove its backend call from every API layer as well (spec operation and
   schema, `ApiClient` method, adapter, service, DTO, mock route and fixture; see
   the add-api-endpoint skill for where each lives).
5. **Web build config**: remove the web build step from CI, the `web:` block of
   the launcher-icons config and the `web/**` line in `.gitattributes`.
6. **Docs to review**: drop the web naming line (`*_view_web.dart`) from
   `AGENTS.md` and web-only sections from `docs/` (if present). Keep everything
   that isn't web-specific.

## 4. Verify

```bash
melos run generate
melos run analyze
melos run coverage
bash <this skill>/scripts/find_web.sh <project_dir>   # must exit 0
```
