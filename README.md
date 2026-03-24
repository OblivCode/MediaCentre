# Media Centre

A robust Flutter application for managing your personal media library. Organize movies, books, audiobooks, comic books, TV shows, and music into a clean, searchable, and sortable collection.

## Features

- **Multi-domain Media Management:** 
  - **Video:** Movies, TV Shows, Seasons, Episodes
  - **Audio:** Albums, Tracks, Audiobooks
  - **Reading:** Books, Comic Books
- **Nested Collections:** Group your media logically into collections.
- **Sorting & Filtering:** Sort by alphabetical order, user rating, or date added.
- **Interactive UI:** Smooth pull-to-refresh library syncing and built-in interactive modals (e.g., Listening Modal with volume management).
- **Persistent Storage:** Saves library state to the local file system using immutable models.

## Development Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd media_centre
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Development Commands

This project strictly adheres to quality and formatting standards. Before committing, ensure you run the following checks:

```bash
flutter analyze              # Lint code
dart format .                # Format code
dart fix --apply             # Apply Dart fixes
flutter test                 # Run the test suite
```

## Architecture & Code Style

- **Immutable Models:** All data models (`MovieBlock`, `BookBlock`, etc.) extend the base `MediaBlock` and enforce immutability with `copyWith`, `toJson`, and `fromJson` serialization.
- **Sprint-based Workflow:** Development is tracked via sprints in the `docs/sprint-summaries` directory.
- **Clean UI:** Extracted robust widgets such as `ListeningModal` and separation of domains (`LibraryDomain` mapping).

## Contributing

This project uses an Agile approach. Follow the format for commits and Sprint Summaries outlined in `AGENTS.md`.

## License

This project is licensed under standard open-source provisions (refer to LICENSE if available).
