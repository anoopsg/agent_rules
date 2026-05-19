---
name: create-feature
description: >-
  Scaffold a new feature in lib/src/features/ using the DDD-lite
  architecture (state, view, page, bindings, ViewProps). Use when
  adding a new screen, sub-domain, or routed feature, or when wiring
  a feature into go_router.
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

## 4. Routing

Add a static class to `lib/src/routes/routes.dart` and attach it to 
`lib/src/routes/router.dart` in the appropriate group (`open`, 
`unauthenticated`, or `authenticated`).

## 5. Barrel Files (Exports)

1. **Sub-domain level**: Export the notifier and the page.
2. **Domain level**: Export `_self` and all sub-domain barrels.
3. **Global level** (`features/features.dart`): Export all domain barrels.

## 6. Tests (Mandatory)

A feature is not complete without its tests. Per the [testable-code](../../../skills/testable-code/SKILL.md)
skill matrix, ship at least:
- **Notifier unit test** at `test/features/<f>/state/<f>_notifier_test.dart`
  covering each state transition and error mapping.
- **Widget test** at `test/features/<f>/view/<f>_view_test.dart` for
  any interactive logic in the view.
- **Golden test** at `test/goldens/features/<f>/<f>_view_golden_test.dart`
  via [golden-sandbox](../../../skills/golden-sandbox/SKILL.md) for
  visual coverage across the device matrix.
- **Route smoke test** if the feature introduces a new route.

Run the suite (`flutter test`) and the golden loop before reporting
the task complete. The turn summary must include both the `tests:`
and `goldens:` disclosure lines.
