# SLUJ

A visual developer-storage scanner for separating actual work from rebuildable garbage.

---

## Purpose

Developer machines accumulate storage that looks identical from the outside.
`node_modules`, `DerivedData`, build output, and package caches sit next to
source you wrote and assets you can never regenerate. Finder shows you sizes.
It does not tell you which bytes are *work*.

SLUJ measures developer storage, classifies it, and draws it, so the
difference is visible in one screen.

```
SCAN → CLASSIFY → AGGREGATE → VISUALIZE → INSPECT
```

SLUJ is not a disk cleaner, a file manager, or a deletion utility. It is
read-only and offline.

## Current state — v0.1

This is a **functional wireframe**. The app runs, and every interaction is
real, but the data is not.

Working:

- one native macOS window: stats, mode switch, filters, treemap, inspector
- squarified treemap sized by real proportions, with selection
- three grouping modes: By Project, By Type, Reclaimability
- per-classification filtering
- inspector showing path, size, classification, confidence, ownership,
  reasoning, evidence, and rebuild recipe
- the reclaimable invariants, enforced in the model and covered by tests
- `NSOpenPanel` folder selection

Fixture-backed:

- **every number in the UI.** The report comes from
  `Sources/SLUJ/Fixtures/FixtureReport.swift`, which describes a plausible
  developer Mac (~70 GB across 8 projects and 5 tools). Choosing folders
  records the URLs you picked and then shows that same fixture report.

## Stack

macOS 14+, Swift 6, SwiftUI, Foundation, Swift Concurrency. AppKit appears
only where SwiftUI needs it.

Zero third-party dependencies. No networking, backend, authentication,
analytics, cloud services, or persistence.

## Architecture

```
sluj/
├── Sources/
│   ├── SLUJCore/            scanning + classification model (no UI)
│   │   ├── Model/           ScanEntry, StorageClassification, ByteFormatting
│   │   ├── Classification/  ClassificationRule + starter rule set
│   │   ├── Ownership/       attributing storage to a project
│   │   ├── Report/          ScanReport, grouping, totals
│   │   └── Scanner/         StorageScanner protocol (read-only contract)
│   └── SLUJ/                the application
│       ├── App/             SLUJApp
│       ├── Views/           MainView, ReportView, TreemapView, InspectorView
│       ├── ViewModels/      ReportViewModel
│       └── Fixtures/        FixtureReport
├── Tests/SLUJCoreTests/
└── Scripts/make-app.sh
```

`SLUJCore` never imports SwiftUI. `TreemapLayout` is generic over
`Identifiable` and imports neither SwiftUI nor SLUJCore, so the layout
algorithm can be replaced on its own.

## Classification model

| Term | Meaning |
| --- | --- |
| `KEEP` | Authored work or source-of-truth material. |
| `REBUILDABLE` | Generated material that can be recreated from source or configuration. |
| `CLEANABLE` | Known disposable developer residue, such as tool caches. |
| `REVIEW` | Ambiguous material SLUJ does not have enough evidence to classify safely. |

Every entry carries its own justification — a reason, the evidence SLUJ
observed, and the command that rebuilds it where one exists. A classification
you cannot interrogate is not worth showing.

### The rule that matters

**KEEP and REVIEW never count toward reclaimable storage.**

This is enforced in `ScanEntry.init`, not at the call site: reclaimable bytes
are clamped to zero for those classifications, and to the entry's own size
otherwise. `ScanReport` derives every total from its entries, so the headline
figure cannot drift away from the entries that justify it.

SLUJ would rather be uncertain than dangerously confident. Storage it does
not understand goes to REVIEW and stays out of the number.

## Safety

SLUJ is read-only. It does not delete, trash, move, or modify anything.

- no delete or clean actions anywhere in the UI
- no `removeItem`, `trashItem`, `moveItem`, or shell deletion
- no automatic Full Disk Access request
- no privileged helper, no administrator permissions
- no network access of any kind

The contract is documented on the `StorageScanner` protocol, which any future
scanner must honour.

## Build and run

Requires Xcode 16+ / Swift 6 on macOS 14+.

```bash
swift build
swift test

# launchable app bundle
./Scripts/make-app.sh
open .build/release/SLUJ.app
```

`swift run SLUJ` also works for a quick debug launch.

Pass `--sample` to open straight into the fixture report, skipping the empty
state — useful for design iteration and screenshots:

```bash
open -a .build/release/SLUJ.app --args --sample
```

## Not implemented yet

Deliberately out of scope for v0.1:

- the actual filesystem crawler — `FilesystemScanner.scan` throws
  `ScannerError.notImplemented`
- any form of deletion or cleanup
- Docker or package-manager integrations
- scan history, persistence, or settings
- accounts, sync, analytics, updates, notarization

The next real step is implementing the scanner behind the existing protocol.
Visual design continues in Figma from this wireframe.
