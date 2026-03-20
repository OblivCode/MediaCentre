# AGENTS.md - MediaCentre

Guidelines for agentic coding agents operating in this Flutter repository.

---

## Build / Lint / Test Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Lint code
dart format .                # Format code
dart fix --apply             # Apply Dart fixes

flutter test                 # Run all tests
flutter test test/widget_test.dart              # Single test file
flutter test --name "test name"                 # Single test by name

flutter run -d windows       # Run on Windows
flutter run -d linux         # Run on Linux
flutter devices              # List available devices
```

---

## Development Workflow (Agile)

This project follows an agile methodology with sprint-based development.

### Sprint Process

1. **Each sprint = one commit** - All changes for a sprint are committed together
2. **Working code required** - Ensure the app builds, tests pass, and features work before completing a sprint
3. **Sprint summary required** - Document changes in `/docs/sprint-summaries/sprintN-summary.md`

### Sprint Summary Format

Create a file `docs/sprint-summaries/sprintN-summary.md` for each sprint:

```markdown
# Sprint N: [Sprint Title] - Summary

**Status:** Complete | In Progress
**Date:** YYYY-MM-DD

---

## What Was Implemented

- [List of features/changes]

## Files Changed

- [List of modified/added files]

## Definition of Done

- [x] flutter analyze passes
- [x] flutter test passes
- [x] Manual testing complete
- [x] Sprint summary written

## Next Sprint Considerations

- [Ideas for future work]
```

### Before Completing a Sprint

1. Run `flutter analyze` - must pass
2. Run `flutter test` - all tests must pass
3. Test the app manually on at least one platform
4. Write sprint summary to `docs/sprint-summaries/`
5. Commit with message: `Sprint N: [brief description]`

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models (immutable)
│   ├── models.dart              # Barrel file + factory
│   ├── media_block.dart         # Abstract base class
│   ├── movie_block.dart         # Movie entity
│   └── collection_block.dart    # Collection/container
├── screens/                     # UI screens/widgets
└── services/                    # Business logic / storage
```

---

## Code Style Guidelines

### Imports
Order: Dart SDK → Flutter SDK → External packages → Relative imports
```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
```
Use relative imports (not `package:media_centre/...`).

### Naming Conventions
- **Classes**: PascalCase (`MovieBlock`, `LibraryScreen`)
- **Variables/Methods**: camelCase (`_loadLibrary`, `userRating`)
- **Private members**: Prefix with underscore (`_library`, `_isLoading`)
- **Files**: snake_case (`movie_block.dart`)

### Formatting
- Trailing commas in multi-line parameter lists
- Use `const` constructors whenever possible
- No comments unless absolutely necessary

### Widget Pattern
```dart
class MyWidget extends StatelessWidget {
  final MyModel model;
  final VoidCallback onDelete;

  const MyWidget({super.key, required this.model, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container();
}

class _PrivateWidget extends StatelessWidget {
  const _PrivateWidget({required this.data});
  // ...
}
```

### Stateful Widget Pattern
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async { /* ... */ }

  @override
  Widget build(BuildContext context) { /* ... */ }
}
```

---

## Models (Immutable Pattern)

All models are immutable with `copyWith`, `toJson()`, and `fromJson()`:
```dart
class MovieBlock extends MediaBlock {
  final int runtimeMinutes;
  final int userRating;

  MovieBlock({
    required super.id,
    required super.title,
    this.runtimeMinutes = 0,
    this.userRating = 0,
  });

  MovieBlock copyWith({String? id, String? title, int? runtimeMinutes, int? userRating}) {
    return MovieBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      userRating: userRating ?? this.userRating,
    );
  }
}
```

---

## Error Handling

Return safe defaults on error rather than throwing:
```dart
Future<CollectionBlock> loadLibrary() async {
  try {
    return CollectionBlock.fromJson(json);
  } catch (e) {
    return _createEmptyLibrary();
  }
}
```

Form validation:
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter a title';
  }
  return null;
},
```

---

## Linter Rules (analysis_options.yaml)

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: false
```

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `path_provider` | ^2.1.1 | Cross-platform file storage |
| `uuid` | ^4.1.0 | Unique ID generation |

---

## Before Committing

Follow the sprint workflow above. Ensure:
1. `flutter analyze` passes
2. `dart format .` applied
3. `flutter test` passes
4. Manual testing complete
5. Sprint summary written
