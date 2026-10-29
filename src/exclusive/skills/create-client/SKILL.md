---
name: create-client
description: Creates low-level wrappers around third-party plugins or system APIs in the infrastructure/ network, storage or device folders. Use when the user asks to create or modify an infrastructure client, implement a plugin wrapper, or add a client to an infrastructure barrel file.
---

# Client Creation Skill

This skill defines the process for creating a new low-level client in
`lib/src/infrastructure/`.

## 1. Overview

Clients are high-level wrappers around third-party plugins or system APIs 
(e.g., `shared_preferences`, `dio`, `package_info`). They encapsulate the 
configuration and complexity of these tools, providing a clean interface 
for feature repositories.

## 2. Directory Structure

Clients are grouped by concern under `lib/src/infrastructure/`:

```text
lib/src/infrastructure/
├── network/              # HTTP, sockets (network.dart barrel)
├── storage/              # Local persistence (storage.dart barrel)
├── device/               # OS, hardware, platform (device.dart barrel)
└── infrastructure.dart   # Re-exports every barrel
```

Add a new folder (with barrel, exported from `infrastructure.dart`) only
if a client fits none of these. Pure logic with no plugin or I/O is not a
client; put it in `lib/src/utils/`.

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

Export your new client from its folder's barrel (e.g. `device/device.dart`):

```dart
export 'my_plugin_client.dart';
```

Features import `infrastructure.dart`; files inside `infrastructure/`
import the specific barrel. Clients never import feature code.

## 5. Usage in Repositories

Clients are injected into repositories via their constructors. Repositories 
then use the client's clean methods to perform data operations.

```dart
class MyRepository({required final MyPluginClient _client});
```
