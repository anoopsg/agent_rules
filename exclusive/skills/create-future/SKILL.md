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
