# CLAUDE.md — SLUJ

## What SLUJ is

The long-term product is in `README.md` and `docs/PRODUCT_OVERVIEW.md`.
What exists today (v0.2) is much smaller:

> A tiny native Mac window that watches one running app.

Pick an app, see its CPU, memory, energy and GPU, with a green / yellow / red
status and a per-process breakdown. Built for checking that your own apps
(Tauri, SwiftUI, Electron) run smoothly and aren't too heavy for the machine.

The v0.1 storage-scanner wireframe is archived at the tag
`archive/storage-scanner`. Don't resurrect it into `main`.

## Decisions (from the 2026-10-03 planning session)

- One fixed **280 × 385** window, Dock icon, no menu bar extra. Pin button
  floats it (`NSWindow.level = .floating`). Closing the window quits.
- Picker: apps whose executable is inside `~/Developer` are listed under
  "Mine" automatically; a star adds any other app (persisted in
  `@AppStorage("starredApps")`).
- Numbers: CPU, memory (physical footprint), energy, GPU. Energy is CPU
  energy only (`ri_energy_nj`), shown in mW / W. It is not Apple's unitless
  "Energy Impact".
- Helpers and dev tooling count toward the app (see `AppGroup`).
- Status: yellow = CPU > 30% for 10s or memory > 1 GB; red = CPU > 80% for 10s
  or memory > 3 GB (`Limits.standard`).
- Samples every 1s while any part of the window is visible
  (`NSWindow.occlusionState`), nothing otherwise.
- Current numbers only. Recordings and the menu bar icon are in `ROADMAP.md`.

## Stack

macOS 14+, Apple Silicon, Swift 6, SwiftUI, Swift Concurrency. AppKit only
where SwiftUI needs it (`NSRunningApplication`, `NSWorkspace`, window level and
occlusion, activation policy). Process data comes from libproc
(`proc_pidinfo`, `proc_pid_rusage`), `sysctl(KERN_PROCARGS2)`, the IORegistry
(`AGXDeviceUserClient` `AppUsage` under `IOAccelerator`) for GPU time, and the
private `responsibility_get_pid_responsible_for_pid`, looked up with `dlsym`.

**Zero third-party dependencies.** No networking, backend, auth, analytics,
cloud, or telemetry. Do not add any.

## Read-only guarantee — non-negotiable

SLUJ watches; it never touches. Nothing in this codebase may:

- quit, signal (`kill`), suspend, renice or otherwise change another process
- offer quit / force-quit buttons
- write into a user's projects or modify user files
- request admin rights, install a privileged helper, or ask for Full Disk Access

The only thing SLUJ stores is its own preferences (pin, starred apps,
breakdown open/closed) in `UserDefaults`.

## Grouping rules (`AppGroup`)

The part most likely to be wrong, so it is tested against fixtures modelled
on a real Tauri dev session (`Tests/SLUJCoreTests/AppGroupTests.swift`).

- **Launcher**: for an app inside a `~/Developer` project, walk up the parent
  chain while each parent's working directory is inside the project and it
  isn't a shell. Everything under the top launcher counts (vite, Tauri CLI).
- **Helpers, app opened normally**: every process whose responsible pid is the
  app.
- **Helpers, app launched from a terminal**: macOS makes the terminal
  responsible. Only WebKit XPC helpers are considered, and each goes to the
  Dock app under that terminal that started most recently before it.
- `guiApps` must contain only `.regular` (Dock) apps. `NSWorkspace` also lists
  WebKit helpers and CLI tools; letting them in makes helpers claim
  themselves.

## Architecture

```
Sources/SLUJCore/       no UI, no SwiftUI import
  ProcessSnapshot       one process at one moment (counters)
  ProcessTable          reads all processes; cwd and argv on demand
  AppGroup              which processes count as the app
  ProjectRoot           ~/Developer/<Category>/<Name> from an executable path
  Sampler               snapshots → rates (Reading)
  Status                Limits + StatusTracker
  Format                display formatting, process display names
Sources/SLUJ/           the app
  App/SLUJApp           window scene, AppDelegate (activation policy, quit on close)
  Monitor               @Observable sampling loop for the watched app
  Views/                MainView (+ PinButton, WindowObserver), PickerView,
                        MonitorView (+ MetricRow), DesignTokens
Tests/SLUJCoreTests/
```

`SLUJCore` must not import SwiftUI. Sampling runs off the main actor in a
detached task; a full snapshot takes about 5 ms.

## UI principles

One small window that reads as a native developer utility. Colour carries
meaning only, from the palette in `DesignTokens.swift`:

| Use | Colour |
| --- | --- |
| fine / warm / too heavy | `#20C76A` / `#FFD84A` / `#F04452` |
| CPU / memory / energy / GPU | `#4B73FF` / `#8B5CF6` / `#2EC5E8` / `#E94BFF` |
| recording (roadmap) | `#FF9F1A` |

Everything else is system monochrome. Rows keep a stable order (main process
first, then by name) so nothing jumps every second. Avoid: hero type, card
grids, gradients, glassmorphism, marketing copy, decorative anything.

## Build

```
swift build && swift test
./scripts/make-app.sh          # launchable SLUJ.app (prints its path)
./scripts/install.sh           # release build into /Applications
```

## Do not add without clear product justification

Anything beyond the roadmap: accounts, sync, update systems, analytics,
notarization, process control. Roadmap items come in order.
