# Package: Riverpod (v3.x)

- Always use `@riverpod` or `@Riverpod(keepAlive: true)` code generation. No manual providers.
- Place providers in `state/` or `providers/` within the feature folder. Name: `[feature]_notifier.dart`.
- V3 Naming: `LoginNotifier` class generates `loginProvider` (not `loginNotifierProvider`).
- Handle `AsyncValue` using `.when`, `.maybeWhen`, or patterns. Avoid `.value!`.
- Use `ref.invalidate(provider)` or `ref.invalidateSelf()` to trigger re-fetches.
- `Ref.mounted` is available to check if the provider is still active.
- Prefer `AsyncNotifier` for complex async state; `Notifier` for synchronous state.
- Keep state immutable. Use `copyWith` for state updates.
- Use `ref.onDispose` for cleaning up resources (controllers, timers).
