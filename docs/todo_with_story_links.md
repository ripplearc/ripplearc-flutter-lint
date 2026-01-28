# todo_with_story_links

Ensures TODO comments include YouTrack story links for proper project management and technical debt tracking. This rule flags TODO comments that don't include a valid YouTrack URL, ensuring technical debt is properly linked to product backlog items.

## Bad ❌
```dart
//TODO: Fix this later  // LINT: Missing YouTrack URL
// TODO: Refactor this method  // LINT: Missing YouTrack URL
//TODO: Add error handling  // LINT: Missing YouTrack URL
```

## Good ✅
```dart
//TODO: https://ripplearc.youtrack.cloud/issue/CA-123
// TODO: https://ripplearc.youtrack.cloud/issue/UI-456
//TODO: https://ripplearc.youtrack.cloud/issue/BE-789 - Fix authentication timeout
```

## Valid YouTrack URL Format
- **Domain**: `https://ripplearc.youtrack.cloud/issue/`
- **Project code**: Any uppercase letters (e.g., `CA`, `UI`, `BE`, `API`, `PERF`)
- **Issue number**: Any digits (e.g., `123`, `456`, `789`)

## Excluded Files
- **Test files**: Files with `_test.dart` or in `/test/` directories are ignored
- **Regular comments**: Comments not starting with `TODO:` are ignored
- **Block comments**: `/* TODO: */` and `/** TODO: */` are ignored
