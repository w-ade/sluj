# SLUJ

**SLUJ remembers your projects.**

Projects rarely live in one place. They exist across local folders,
repositories, design files, deployments, references, conversations, and
half-finished ideas.

SLUJ brings that context back together.

---

## BOOT → DIG → PROJECT

**BOOT** — Name the project.

```
SLUJ

What are we working on?

[ Reference Garden                    ]
```

**DIG** — SLUJ discovers what belongs to it. Local folder, repository, design
file, deployment, domain, references, agent conversations. You watch the context
assemble rather than watching a spinner.

**PROJECT** — The project becomes a living file containing its technical,
creative, and historical context: where it exists, what state it is in, how much
it weighs, what you already decided, and what you still owe it.

The principle underneath all three:

> Capture first. Context accumulates. Organization emerges afterward.

SLUJ is not Jira, Linear, Notion, a task manager, a Kanban board, a disk
cleaner, a Git GUI, or a bookmark manager. It surfaces information from several
of those domains without becoming any of them.

Full product definition: **[PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md)**.

## Current state — v0.1

**The app today is a functional wireframe of the storage layer only.** BOOT,
DIG, and PROJECT are not built. The app runs and every interaction is real, but
the data is not.

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
  developer Mac (~70 GB across 8 projects and 5 tools). Choosing folders records
  the URLs you picked and then shows that same fixture report.

The next technical step is implementing the real filesystem scanner behind the
existing `StorageScanner` protocol. See
[Current scope](PRODUCT_OVERVIEW.md#current-scope) and
[Future direction](PRODUCT_OVERVIEW.md#future-direction).

## Storage in SLUJ

Storage is one part of project memory, not the product itself. It answers how
much a project weighs and where the weight is — so `428 MB` resolves into the
source you wrote versus the `node_modules` that can be regenerated.

SLUJ is read-only. It measures and explains; it never deletes.

### Classification model

| Term | Meaning |
| --- | --- |
| `KEEP` | Authored work or source-of-truth material. |
| `REBUILDABLE` | Generated material that can be recreated from source or configuration. |
| `CLEANABLE` | Known disposable developer residue, such as tool caches. |
| `REVIEW` | Ambiguous material SLUJ does not have enough evidence to classify safely. |

Every entry carries its own justification — a reason, the evidence SLUJ
observed, and the command that rebuilds it where one exists. A classification
you cannot interrogate is not worth showing.

**KEEP and REVIEW never count toward reclaimable storage.** This is enforced in
`ScanEntry.init`, not at the call site: reclaimable bytes are clamped to zero
for those classifications, and to the entry's own size otherwise. `ScanReport`
derives every total from its entries, so the headline figure cannot drift away
from the entries that justify it.

SLUJ would rather be uncertain than dangerously confident. Storage it does not
understand goes to REVIEW and stays out of the number.

## Safety

SLUJ is read-only. It does not delete, trash, move, or modify anything.

- no delete or clean actions anywhere in the UI
- no `removeItem`, `trashItem`, `moveItem`, or shell deletion
- no automatic Full Disk Access request
- no privileged helper, no administrator permissions
- no network access in the current build

The contract is documented on the `StorageScanner` protocol, which any future
scanner must honour.

## Stack

macOS 14+, Swift 6, SwiftUI, Foundation, Swift Concurrency. AppKit appears only
where SwiftUI needs it.

Zero third-party dependencies. No backend, authentication, analytics, cloud
services, or persistence.

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

`SLUJCore` never imports SwiftUI. `TreemapLayout` is generic over `Identifiable`
and imports neither SwiftUI nor SLUJCore, so the layout algorithm can be
replaced on its own.

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

## Documentation

- **[PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md)** — the canonical product
  document: problem, core idea, BOOT/DIG/PROJECT, the Reference Garden example,
  project memory, character, scope, and direction
- **[CLAUDE.md](CLAUDE.md)** — working notes and constraints for agents in this
  repo
