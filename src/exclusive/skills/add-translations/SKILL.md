---
name: add-translations
description: >
  Use when adding or modifying translation keys, localized strings, i18n
  keys, or errors. Handles en.i18n.json, ar.i18n.json, and melos run translate.
---

# Internationalization Skill

This skill defines the process for adding, modifying, and using localized
strings in the project. The project uses `slang` for internationalization.

## 1. Directory Structure

Translation source files are located in `lib/i18n/`:

```text
lib/i18n/
├── en.i18n.json         # English translations (source locale)
└── ar.i18n.json         # Arabic translations
```

## 2. Formatting Guidelines

Follow these rules when adding or modifying translations:

- **Key Naming**: Use `camelCase` for translation keys.
- **Namespacing**: Organize keys by features or common namespaces.
- **Sync**: Ensure every key added to `en.i18n.json` is also added to
  `ar.i18n.json` to keep them in sync.
- **Placeholders**: Use `${variableName}` syntax for dynamic placeholders.

### 2.1 JSON Example

```json
{
  "auth": {
    "login": "Login",
    "welcome": "Welcome, ${name}!"
  },
  "errors": {
    "myError": "Something went wrong."
  }
}
```

## 3. Registering Error Codes

When translating errors, the translation key must match the technical
error code defined in Dart:

1. Add the code to `lib/src/infrastructure/error_codes.dart`:
   ```dart
   enum AppErrorCode implements ErrorCode {
     myError('myError'),
   }
   ```
2. Add the translation under the `errors` key in translation JSONs:
   ```json
   "errors": {
     "myError": "A localized description of the error."
   }
   ```

## 4. Re-generating Translations

After modifying JSON files, run the translation tool to generate updated
Dart types:

```bash
melos run translate
```

## 5. Usage in Code

To avoid repeated access overhead, assign `context.$.tr` to a local variable
(e.g., `tr`) when accessing translations inside build methods:

```dart
final tr = context.$.tr;

// Basic usage
Text(tr.auth.login)

// With placeholders
Text(tr.auth.welcome(name: 'User'))

// For failure mapping
final message = failure.toError(tr);
```
