---
name: create-feature
description: Use when asked to create a new feature or sub-feature following the DDD-lite architecture, or set up state, view, and page layers for a domain.
---

# Feature Creation Skill

This skill outlines the standard process for creating a new feature in the 
project, following the **DDD-lite** architecture. This guide covers both 
simple domains (like Settings) and complex domains (like Auth).

## 1. Directory Structure

Features are located in `lib/src/features/`. The structure depends on the 
complexity of the domain.

### A. Simple Domain (e.g., Settings, Explore)
If the feature is self-contained and doesn't require separate sub-modules:
```text
lib/src/features/settings/
├── state/               # Domain-specific state
│   └── settings_notifier.dart
├── view/                # UI implementation
│   ├── settings_page.dart       # Entry point & Bindings
│   ├── settings_view.dart       # Mobile UI
│   └── settings_view_web.dart   # Web UI
└── settings.dart        # Feature barrel file
```

### B. Complex Domain (e.g., Auth, Account)
If the feature contains multiple distinct flows:
```text
lib/src/features/auth/
├── _self/               # Shared domain logic
│   └── state/
│       └── auth_notifier.dart
├── login/               # Sub-domain feature
│   ├── state/           # Local feature state
│   │   └── login_notifier.dart
│   ├── view/            # Local UI
│   │   ├── login_page.dart
│   │   ├── login_view.dart
│   │   └── login_view_web.dart
│   └── login.dart       # Sub-domain barrel
└── auth.dart            # Domain barrel (exports _self and sub-domains)
```

## 2. Naming Conventions

| Entity | Convention | Example |
| :--- | :--- | :--- |
| **Folder** | `snake_case` | `auth_login` |
| **File** | `snake_case` | `login_page.dart` |
| **Page Class** | `PascalCase` + `Page` | `LoginPage` |
| **View Class** | `PascalCase` + `View` | `LoginView` |
| **Web View Class** | `PascalCase` + `ViewWeb` | `LoginViewWeb` |
| **Props Class** | `PascalCase` + `Props` | `LoginProps` |

## 3. Creating the View Layer

### 3.1 The Page & Bindings
The `Page` widget delegates logic to `_Bindings`, which prepares the 
`ViewProps`.

```dart
class MyFeaturePage extends StatelessWidget {
  const MyFeaturePage({super.key});

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
final class MyProps extends ViewProps {
  const MyProps({required this.data, required this.onAction});
  final String data;
  final VoidCallback onAction;

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
class LoginState with LoginStateMappable implements FailureInterface {
  const LoginState({this.isLoggingIn = false, this.failure});

  factory LoginState.loading() => const LoginState(isLoggingIn: true);

  final bool isLoggingIn;

  @override
  final Failure? failure;
}

@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() => const LoginState();

  void login() {
    state = LoginState.loading();
    // Action logic here...
  }
}
```

## 4. Routing

Follow the [Routing Management Skill](manage-routes.md) to define the route
class and register it in the appropriate group (`open`, `unauthenticated`,
or `authenticated`).

## 5. Barrel Files (Exports)

1. **Sub-domain level**: Export the notifier and the page.
2. **Domain level**: Export `_self` and all sub-domain barrels.
3. **Global level** (`features/features.dart`): Export all domain barrels.
