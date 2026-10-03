# CLAUDE.md — SLUJ

## What SLUJ is

The long-term product is in `README.md` and `docs/PRODUCT_OVERVIEW.md`.
What exists today (v0.2) is much smaller:

> A tiny native Mac window that watches one running app.

Pick an app, see its CPU, memory, energy or GPU as a total, a status, and one
bar per process. Built for checking that your own apps
(Tauri, SwiftUI, Electron) run smoothly and aren't too heavy for the machine.

The v0.1 storage-scanner wireframe is archived at the tag
`archive/storage-scanner`. Don't resurrect it into `main`.

## Decisions (from the 2026-10-03 planning session)

- The UI is the SLJ-20261003-002 Figma page (`docs/design/`): the whole window is
  the card, fixed **500 × 396**, Dock icon, no menu bar extra. The title reads
  "sluj"; clicking it goes back to the app picker. A metric menu switches
  between CPU / Memory / Energy / GPU (`@AppStorage("metric")`). Pin button
  floats it (`NSWindow.level = .floating`). Closing the window quits.
- The real traffic lights sit at the 25 pt content inset (24 + 1 pt border): `WindowObserver`
  stretches the titlebar container and moves the buttons. Never set
  `window.backgroundColor`: on macOS 26 it hides the traffic lights.
  SwiftUI adds a 28 pt titlebar inset when sizing the window, so the scene
  frame is `windowHeight - titlebarInset`.
- Inter (OFL, `Resources/Fonts/`) is bundled by `make-app.sh` and registered
  with `ATSApplicationFontsPath`. Its name is `InterVariable`, not "Inter".
  `swift run` has no bundle and falls back to the system font.
- Light and dark follow the system until the animated half-circle beside
  the pin is clicked; its choice is persisted in `UserDefaults("theme")`.
  The icon spins a half-turn with spring settling and respects Reduce Motion.
  `--appearance dark` and `--watch <app>` force them for screenshots.
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

The only thing SLUJ stores is its own preferences (pin, theme, starred apps,
chosen metric) in `UserDefaults`.

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

One small card that reads as a native developer utility. Colour carries
meaning only, from the palette in `DesignTokens.swift`:

| Use | Colour |
| --- | --- |
| fine / busy / heavy | `#20C76A` / `#FFD84A` / `#F04452` |
| process bars, in order | `#4B73FF` `#2EC5E8` `#8B5CF6` `#E94BFF` `#FF9F1A` `#FFD84A` `#20C76A` `#F04452` |
| recording (roadmap) | `#FF9F1A` |

Each process gets its bar colour once, largest memory first, and keeps it
across metrics. Equal-width columns sort by the selected metric, with values
above and two-line process names below. Eight fit across; larger groups scroll.
Idle processes keep a 2 pt column. Updates animate for 0.4s and respect Reduce Motion.
Neutrals are `#737373` / `#E5E5E5` / black on white, and
`#A1A1A1` / `#262626` / `#FAFAFA` on `#171717` in dark mode. Avoid: hero type, card
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
