---
name: create-client
description: >-
  Create a low-level client wrapper in lib/src/infrastructure/_clients/
  around a third-party plugin or system API. Use when adding a new
  client class, wiring its Riverpod provider, or registering it in the
  clients barrel file.
---
# Client Creation Skill

This skill defines the process for creating a new low-level client in the 
`infrastructure/_clients/` directory.

## 1. Overview

Clients are high-level wrappers around third-party plugins or system APIs 
(e.g., `shared_preferences`, `dio`, `package_info`). They encapsulate the 
configuration and complexity of these tools, providing a clean interface 
for the rest of the infrastructure layer.

## 2. Directory Structure

Clients are stored in `lib/src/infrastructure/_clients/`:

```text
lib/src/infrastructure/_clients/
├── _clients.dart        # Barrel file
├── my_plugin_client.dart # The client implementation
└── ...
```

## 3. Implementation Pattern

Follow these rules when creating a client:

- **Naming**: Use `PascalCase` + `Client` (e.g., `LocationClient`).
- **DI**: Provide the client via a Riverpod provider with `keepAlive: true`.
- **Encapsulation**: Hide plugin-specific types behind your own methods where 
  possible.
- **Error Handling**: Use `try/catch` blocks and log errors using 
  `dart:developer`.

### 3.1 Example Implementation

```dart
import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_plugin/my_plugin.dart';

part 'my_plugin_client.g.dart';

@Riverpod(keepAlive: true)
MyPluginClient myPluginClient(Ref ref) => MyPluginClient();

class MyPluginClient {
  final _plugin = MyPlugin();

  Future<bool> doSomething() async {
    try {
      await _plugin.execute();
      return true;
    } on Object catch (e, st) {
      developer.log(
        'MyPluginClient.doSomething failed',
        name: 'MyPluginClient',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
```

## 4. Barrel File

Always export your new client in `lib/src/infrastructure/_clients/_clients.dart`:

```dart
export 'my_plugin_client.dart';
```

## 5. Usage in Repositories

Clients are injected into repositories via their constructors. Repositories 
then use the client's clean methods to perform data operations.

```dart
class MyRepository {
  MyRepository({required MyPluginClient client}) : _client = client;
  final MyPluginClient _client;
}
```

## 6. Tests (Mandatory)

Per the [testable-code](../../../skills/testable-code/SKILL.md) skill,
ship a unit test alongside the client at
`test/infrastructure/_clients/<c>_client_test.dart`. Mock the underlying
plugin and assert:
- The success path returns the documented value.
- Each thrown error type is swallowed and returns the documented
  sentinel (e.g. `false`, `null`, or an `Err`).
- `developer.log` is called on failure with the expected name and error.

Run `flutter test` and include the `tests:` disclosure line per
[core/testability.md](../../../rules/core/testability.md) before
reporting the task complete.
