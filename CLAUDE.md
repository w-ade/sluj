# CLAUDE.md — SLUJ

## What SLUJ is

A small, read-only, visual developer-storage scanner for macOS.

> Separate actual work from rebuildable garbage.

It measures where developer storage goes, classifies it, aggregates it, and
draws it. It is **not** a disk cleaner, a file manager, or a deletion tool.

Core loop: `SCAN → CLASSIFY → AGGREGATE → VISUALIZE → INSPECT`

## v0.1 scope (current)

This is a **functional wireframe**, not final visual design.

- Real: architecture, model, invariants, treemap, filtering, inspector, tests.
- Fixture-backed: every number in the UI comes from `Sources/SLUJ/Fixtures/FixtureReport.swift`.
- Not implemented: the filesystem crawler. `FilesystemScanner.scan` throws
  `ScannerError.notImplemented` on purpose. Choosing folders records the URLs
  and shows the fixture report.

## Stack

macOS 14+, Swift 6, SwiftUI, Foundation, Swift Concurrency. AppKit only where
SwiftUI needs it (`NSOpenPanel`, activation policy).

**Zero third-party dependencies.** No networking, backend, auth, analytics,
cloud, telemetry, or persistence. Do not add any.

## Read-only guarantee — non-negotiable

SLUJ never modifies user files. Nothing in this codebase may:

- call `removeItem` / `trashItem` / `moveItem` / `copyItem` on user paths
- shell out to `rm`, cleanup, or prune commands
- offer delete/trash/clean buttons in the UI
- request Full Disk Access automatically, install a privileged helper, or
  escalate permissions

The contract is documented on `StorageScanner`. Keep it there if that
protocol changes.

## Classification vocabulary

| Term | Meaning |
| --- | --- |
| `KEEP` | Authored work or source-of-truth material. |
| `REBUILDABLE` | Generated material recreatable from source/configuration. |
| `CLEANABLE` | Known disposable developer residue, e.g. tool caches. |
| `REVIEW` | Not enough evidence to classify safely. |

### The REVIEW safety rule

**REVIEW never counts toward reclaimable storage.** So does KEEP. This is
enforced in `ScanEntry.init`, which clamps `reclaimableBytes` to 0 for both,
and to at most the entry's own size. `ScanReport` derives all totals from
entries, so the headline figure can never drift from its justification.
Tests in `Tests/SLUJCoreTests` cover this. Do not weaken them.

SLUJ prefers being uncertain over being dangerously confident.

## Architecture

```
Sources/SLUJCore/       no UI, no SwiftUI import
  Model/                ScanEntry, StorageClassification, ByteFormatting
  Classification/       ClassificationRule + starter rule set
  Ownership/            attributing storage to a project
  Report/               ScanReport, grouping, totals
  Scanner/              StorageScanner protocol + read-only contract
Sources/SLUJ/           the app
  App/ Views/ ViewModels/ Fixtures/
Tests/SLUJCoreTests/
```

`SLUJCore` must not import SwiftUI. `TreemapLayout` must not import SwiftUI or
SLUJCore — it is generic over `Identifiable` so the algorithm stays swappable.

## UI principles

One window. It should read as a small native developer utility, not a SaaS
dashboard. Monochrome; classification is carried by fill weight and a badge,
not colour. REVIEW gets a dashed edge because "SLUJ doesn't know" is the one
thing the user must not misread. Compact density, system type, monospace only
for paths and technical metadata.

Avoid: hero type, card grids, gradients, glassmorphism, big sidebars,
marketing copy, decorative anything.

## Build

```
swift build && swift test
./Scripts/make-app.sh          # produces a launchable SLUJ.app
```

## Do not add without clear product justification

Persistence, scan history, accounts, cloud sync, update systems, analytics,
Docker/package-manager API integrations, notarization, branding work. The
next real step is the filesystem scanner behind the existing protocol —
nothing else.
