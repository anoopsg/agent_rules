---
name: add-translations
description: Adds or changes localized strings with slang (lib/i18n/*.i18n.json) and registers error codes with their messages. Use when adding UI text, a translation key or locale string, or an AppErrorCode and its message.
---

# Internationalization Skill

This skill defines the process for adding, modifying, and using localized
strings in the project. The project uses `slang` for internationalization,
configured in `slang.yaml` (which also names the base locale).

## 1. Directory Structure

Translation source files are located in `lib/i18n/`:

```text
lib/i18n/
├── en.i18n.json         # English translations (source locale)
└── ar.i18n.json         # Arabic translations
```

Every `*.i18n.json` file there is a locale. The Dart code generated from
them goes to the `gen/` folder beside them; never edit it by hand.

## 2. Formatting Guidelines

Follow these rules when adding or modifying translations:

- **Key Naming**: Use `camelCase` for translation keys.
- **Namespacing**: Organize keys by features or common namespaces.
- **Sync**: Ensure every key added to `en.i18n.json` is also added to
  `ar.i18n.json` (and any other locale file) to keep them in sync.
- **Reuse**: Check for an existing key before adding a new one. Never
  hardcode user-facing text in widgets.
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
error code defined in Dart. The key is the code's **value**, not the enum
name (e.g. `unknown('unknownError')` → `errors.unknownError`):

1. Add the code to `lib/src/infrastructure/error_codes.dart`:
   ```dart
   enum AppErrorCode(@override final String value, [final String? backend])
       implements ErrorCode {
     myError('myError'),
     myApiError('myApiError', 'MY_API_ERROR'), // API sends its own code
   }
   ```
   If the backend sends its own code for the error, pass it as the second
   argument; the API maps it to your code automatically (`fromBackend`).
2. Add the translation under the `errors` key in **every** locale file
   (`lib/i18n/*.i18n.json`), then regenerate (§4):
   ```json
   "errors": {
     "myError": "A localized description of the error."
   }
   ```

Server-provided messages use `AppErrorCode.remote` and need no key.

## 4. Re-generating Translations

After modifying JSON files, run the translation tool to generate updated
Dart types:

```bash
melos run translate
```

Then check that every locale has exactly the base locale's keys: compare
the key paths of each `*.i18n.json` with `en.i18n.json`, and add any that
are missing or remove any extras. This skill ships a script that does the
comparison (pass the project's i18n folder):

```bash
python3 -I <this skill>/scripts/check_keys.py lib/i18n
```

It prints one `missing` or `extra` line per key to fix, or `in sync`.

## 5. Usage in Code

To avoid repeated access overhead, assign `context.$.tr` to a local variable
(e.g., `tr`) when accessing translations inside build methods. `tr` comes
from `package:<project_name>/i18n/app_localizations.dart`:

```dart
final tr = context.$.tr;

// Basic usage
Text(tr.auth.login)

// With placeholders
Text(tr.auth.welcome(name: 'User'))

// For failure mapping (lib/src/shared/failure.dart)
final message = failure.toError(tr);
```
