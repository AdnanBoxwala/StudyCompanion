# StudyCompanion

An iOS app that helps students extract text from textbook photos, generate summaries, and create flashcards — all powered by on-device Apple Intelligence.

## Features

- **Multi-photo selection** — Select up to 3 textbook pages at once
- **OCR text extraction** — Accurate text recognition using the Vision framework
- **AI summarization** — Concise summaries with key points via Apple Intelligence
- **Flashcard generation** — Configurable flashcard count (3–15) from extracted text
- **Organized library** — Save study materials by Subject, Chapter, and Topic using SwiftData
- **Image viewer** — Full-screen viewing with pinch-to-zoom

## Requirements

- iOS 26.0+
- iPhone 15 Pro or later (Apple Intelligence required)
- Xcode 26+

## Architecture

```
StudyCompanion/
├── App/                    # App entry point
├── Models/
│   ├── AI/                 # Flashcard, FlashcardSet, TextSummary (@Generable)
│   └── SwiftData/          # Subject, Chapter, StudyEntry, SchemaVersions
├── Services/
│   ├── AIService/          # Protocol + Apple Intelligence implementation
│   ├── OCRService.swift    # Vision text extraction
│   ├── PhotoLoaderService.swift
│   └── StudyErrors.swift   # Typed error enums
├── ViewModels/             # StudyViewModel with dependency injection
└── Views/
    ├── Study/              # Main study flow (photo selection, extraction)
    ├── Library/            # Saved materials browsing
    ├── Flashcards/         # Card list and review
    ├── Summary/            # Summary display
    ├── Save/               # Save sheet
    └── Common/             # Shared components
```

**Key patterns:**
- Service protocols with typed throws for dependency injection and testability
- `@Observable` view models (not `ObservableObject`)
- Cooperative task cancellation
- Typed error handling with retry support
- SwiftData with `VersionedSchema` and `SchemaMigrationPlan`

## Frameworks

| Framework | Usage |
|---|---|
| SwiftUI | UI layer |
| FoundationModels | On-device AI (summarization, flashcard generation) |
| Vision | OCR text recognition |
| PhotosUI | Photo picker |
| SwiftData | Persistence |

## Getting Started

1. Open `StudyCompanion.xcodeproj` in Xcode 26+
2. Select an iPhone 15 Pro (or later) simulator or device
3. Build and run

## License

This project is for personal/educational use.
