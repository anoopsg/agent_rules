---
name: provide-mock-data
description: Process for creating mock data sources in the infrastructure layer.
---

# Provide Mock Data

When you need to create mock data for development or prototyping, follow these guidelines:

1. **Location**: Place mock data files inside the `lib/src/infrastructure/_mock/` directory.
2. **Naming**: Name the file using the domain name suffixed with `_mock.dart` (e.g., `notifications_mock.dart`).
3. **Structure**: 
   - Provide a pure function or constants to generate the mock data.
   - Do NOT use singletons or hold state within the mock data file itself. State should be managed by Riverpod providers/notifiers.
4. **Integration**: Create a repository class (e.g., `NotificationsRepository`) that uses the mock data generator to simulate API responses, including adding artificial delays using `Future.delayed` to simulate network latency.
5. **Separation of Concerns**: The notifier should handle all local state updates, while the repository strictly handles the "network" (mock) operations.
