---
name: create-feature
description: Creates a feature or sub-feature in the DDD-lite layout — folders, page and view, notifier state, error display, routing and barrels. Use when adding a new screen, feature or domain. Data layer — create-infrastructure; reusable UI — create-ui-widget.
---

# Feature Creation Skill

This skill outlines the standard process for creating a new feature in the 
project, following the **DDD-lite** architecture. This guide covers both 
simple domains (like Settings) and complex domains (like Auth).

## 1. Directory Structure

Features are located in `lib/src/features/`. The structure depends on the 
complexity of the domain.

### A. Simple Domain (e.g., Settings, Explore)
If the feature is self-contained and doesn't require separate sub-modules, 
keep it flat under the feature root folder. No `_self` folder is used.
```text
lib/src/features/settings/
├── data/                # Models & repositories (create-infrastructure)
│   └── data.dart
├── state/               # Domain-specific state
│   └── settings_notifier.dart
├── view/                # UI implementation
│   ├── settings_page.dart       # Entry point & Bindings
│   ├── settings_view.dart       # Mobile UI
│   └── settings_view_web.dart   # Web UI (only if the layout differs)
└── settings.dart        # Feature barrel file
```

### B. Complex Domain (e.g., Auth, Account)
If the feature has multiple sub-domains, it is structured as a complex 
domain. The `_self` folder is used for root-level domain control, shared 
domain state (e.g., auth status, user metadata, cache), and layout/shell 
views that host or wrap the sub-features.

#### Example: Auth Domain
```text
lib/src/features/auth/
├── _self/               # Shared domain logic & state
│   ├── data/            # Models & repositories (create-infrastructure)
│   └── state/
│       └── auth_notifier.dart  # Global auth status
├── login/               # Sub-domain feature
│   ├── state/           # Local feature state
│   │   └── login_notifier.dart
│   ├── view/            # Local UI
│   │   ├── _form.dart   # Feature-only view part (see 3.5)
│   │   ├── login_page.dart
│   │   ├── login_view.dart
│   │   └── login_view_web.dart
│   └── login.dart       # Sub-domain barrel
└── auth.dart            # Domain barrel (exports _self and sub-domains)
```

Sub-domains are nested folders (`auth/login/`), never prefixed siblings
(`auth_login/`). Never use `_self` for a single feature's own state.

The data layer (models, repositories) is built with the
[create-infrastructure](../create-infrastructure/SKILL.md) skill. Backend
calls and their mock data go through `ApiClient`
([add-api-endpoint](../add-api-endpoint/SKILL.md)); on/off switches for a
feature use [add-config-flag](../add-config-flag/SKILL.md).

## 2. Naming Conventions

| Entity | Convention | Example |
| :--- | :--- | :--- |
| **Folder** | `snake_case` | `privacy_policy` |
| **File** | `snake_case` | `login_page.dart` |
| **Page Class** | `PascalCase` + `Page` | `LoginPage` |
| **View Class** | `PascalCase` + `View` | `LoginView` |
| **Web View Class** | `PascalCase` + `ViewWeb` | `LoginViewWeb` |
| **Props Class** | `PascalCase` + `Props` | `LoginProps` |
| **View Part** | `_` + `snake_case`, never exported | `_form.dart` |

## 3. Creating the View Layer

### 3.1 The Page & Bindings
The `Page` widget delegates logic to `_Bindings`, which prepares the 
`ViewProps`. A page with no state or callbacks skips this and returns the
view directly (e.g. `SettingsPage` returns `const SettingsView()`). Add a
`ViewWeb` only when the web layout differs.

```dart
class const MyFeaturePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Bindings(
      viewBuilder: (_, props) {
        // Simple pages can return the view directly.
        // Complex UIs should use MemoizedView for performance.
        if (isComplex) {
          return MemoizedView(
            props: props,
            builder: (context, memProps) => kIsWeb 
              ? MyFeatureViewWeb(props: memProps) 
              : MyFeatureView(props: memProps),
          );
        }

        return kIsWeb 
          ? MyFeatureViewWeb(props: props) 
          : MyFeatureView(props: props);
      },
    );
  }
}
```

### 3.2 ViewProps & Stale Closures
`ViewProps` separates **Data** (used for equality) from **Callbacks** 
(ignored for equality).

> [!IMPORTANT]
> **CRITICAL RULE FOR AI**: NEVER include callback functions (like `VoidCallback`, `Function`, etc.) in the `equalityProperties` list of a `ViewProps` subclass. The base class has a runtime assertion that will crash the app if functions are included. **ONLY** include data fields.

> [!CAUTION]
> **STALE CLOSURES**: Because `MemoizedView` ignores callbacks in equality 
> checks, your UI might hold a reference to an "old" closure. 
> **Never** capture variables from `ref.watch` in a callback. Always use 
> `ref.read` inside the closure to ensure you have the fresh state.

```dart
final class const MyProps({
  required final String data,
  required final VoidCallback onAction,
}) extends ViewProps {
  // CRITICAL: Only include data fields. Do NOT include functions/callbacks here!
  @override
  List<Object?> get equalityProperties => [data]; // Exclude onAction
}

// ... inside _Bindings ...
return viewBuilder(
  context,
  MyProps(
    data: ref.watch(myProvider).data, // Data for equality
    onAction: () {
      // SAFE: ref.read ensures fresh state when callback is executed
      ref.read(myProvider.notifier).doSomething(); 
      
      // DANGEROUS: capturing 'data' here will cause stale closure bugs
      // print(data); 
    },
  ),
);
```

### 3.3 Feature State & Notifiers

Feature state and notifiers live in the `state/` directory of a feature.

- **State Location**: Define the state class in the same file as the provider
  or notifier. Do not create a separate file for the state class.
- **Data Modeling**: Always use `dart_mappable` (`@MappableClass()`) for state
  classes to get built-in immutability (`copyWith`) and equality.

```dart
import 'package:dart_mappable/dart_mappable.dart';
import 'package:framework/framework.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier.mapper.dart';
part 'login_notifier.g.dart';

/// Local form state tracking for the Auth flow.
@MappableClass()
class const LoginState({
  final bool isLoggingIn = false,
  @override final Failure? failure,
}) with LoginStateMappable implements FailureInterface {
  factory loading() => const LoginState(isLoggingIn: true);
}

@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() => const LoginState();

  Future<void> login(Credentials credentials) async {
    state = LoginState.loading();
    final result = await ref.read(authRepositoryProvider).login(credentials);
    // The page may have been closed while the request was in flight.
    if (!ref.mounted) return;

    state = result.when(
      onSuccess: (_) => state.copyWith(isLoggingIn: false),
      onFailure: (failure) =>
          state.copyWith(isLoggingIn: false, failure: failure),
    );
  }
}
```

- **Mounted Check**: After every `await`, return early with
  `if (!ref.mounted) return;` before writing state.
- **Domain Models**: If the state is a domain model, use the model from
  `data/models/` directly instead of wrapping it.
- **Lifetime**: Use `@Riverpod(keepAlive: true)` only for app-wide state
  (auth, settings, routing). Feature state uses `@riverpod`.
- **Paged Lists**: Hold `PaginatedData<T>` from `lib/src/shared/pagination.dart`
  (e.g. `NotificationsState`).

### 3.4 Showing Errors
Notifiers never `try/catch`; repositories return `Result`, and the state
carries the `Failure` (`implements FailureInterface`). How the view shows it
depends on the notifier:

- **Sync state** (like `LoginState` above): `_Bindings` calls `ref.listen`
  and, when `next.canTriggerError(previous)`, passes
  `next.getErrorMessage(context.$.tr)` to the view's
  `static void delegateError(BuildContext, String)`. Mirror
  `grep -rl "delegateError" lib/src/features`.
- **Async state** (`AsyncValue`): `build()` throws the failure on `Err`, so
  the view shows its error state; mutations store the failure in the state,
  and the view calls `ref.listenForFailures(context, provider)` to show it as
  a snackbar. Mirror `grep -rl "listenForFailures" lib/src/features`.

### 3.5 View Composition
Split the UI by purpose before writing the view:

- **Reusable visual blocks** (cards, tiles, empty or error states) belong in
  `app_ui`. Extract them first with the
  [create-ui-widget](../create-ui-widget/SKILL.md) skill, then use them here.
- **Feature-only composition** (e.g. a form wiring state to `app_ui`
  widgets) goes in `view/_<part>.dart`, imported directly by the views and
  never exported from the barrel (e.g. `auth/login/view/_form.dart`).
- **Never** write `_buildX()` helper methods.

All text comes from `context.$.tr` (see the add-translations skill).

## 4. Routing

Follow the [Routing Management Skill](../manage-routes/SKILL.md) to define the route
class and register it in the appropriate group (`open`, `unauthenticated`,
or `authenticated`). Navigate with `Routes.<route>.path`, never literal
paths.

## 5. Barrel Files (Exports)

1. **Sub-domain level**: Export the notifier and the page, not the views or
   `_<part>.dart` files.
2. **Domain level**: Export the data barrel (`data/data.dart` or
   `_self/data/data.dart`), `_self` state and all sub-domain barrels.
3. **Global level** (`features/features.dart`): Export all domain barrels.
