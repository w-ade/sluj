# SLUJ

**Understand what you're building.**

SLUJ is a project understanding system for people who design, build, ship, break, abandon, revive, and maintain software.

Modern software projects rarely exist in one place.

A project can simultaneously exist as:

- a folder on your computer
- a Git repository
- a GitHub repository
- a Vercel deployment
- a domain
- a Figma file
- a collection of dependencies
- a set of environment variables
- a backlog
- several unfinished notes
- a deployment configuration
- build artifacts
- screenshots
- references
- decisions
- terminal commands
- agent conversations
- and a vague memory of what you were trying to do three weeks ago

The project itself may be perfectly healthy while the **human understanding around it becomes fragmented**.

SLUJ exists to bring that understanding back together.

It gives a project a small, readable operating layer and gives the person building it a visual way to understand:

> What is this project?

> What is inside it?

> How is it built?

> Where does it exist?

> What is connected to what?

> What changed?

> What is healthy?

> What is broken?

> What needs attention?

> What can safely disappear?

> What should happen next?

SLUJ should make software projects feel less like mysterious collections of files and services and more like systems that can be inspected, understood, learned from, and maintained confidently.

---

# The Core Idea

SLUJ has two primary product surfaces built around the same underlying understanding of a project.

```text
                    SLUJ

                      │
                understanding
                      │
          ┌───────────┴───────────┐
          │                       │
   SLUJ Dashboard             SLUJ for macOS
          │                       │
      one project              all projects
          │                       │
   local operating           system-wide project
       layer                    understanding
```

## SLUJ Dashboard

**Understand this project.**

SLUJ Dashboard is an extremely lightweight project-local operating layer that can be added to a software project.

The goal is not to turn every repository into another project-management application.

The goal is to give every project a **small cockpit**.

From one local dashboard, someone should be able to understand the project's:

- structure
- context
- Git state
- GitHub connection
- dependencies
- environment
- build system
- deployment state
- storage footprint
- health
- tasks
- issues
- blockers
- notes
- decisions
- recent activity
- external references

The dashboard should live close to the project rather than requiring the project to live inside SLUJ.

A future installation flow might look something like:

```bash
npx sluj init
```

followed by:

```bash
npx sluj
```

which could open a lightweight local interface in the browser.

The exact CLI syntax and implementation are not yet finalized.

The product principle is what matters:

> **Add SLUJ to a project. Open one place. Understand the project.**

---

# A Portable Project Operating Layer

The dashboard is not intended to become another proprietary system that owns the project.

It should be a **portable project operating layer**.

That means:

- it travels with the project
- it remains lightweight
- it works locally
- it should not require a hosted account for basic functionality
- it should not require every project to run background services
- it should avoid significant storage overhead
- it should use project data that already exists wherever possible
- it should remain useful even if SLUJ itself is removed later

SLUJ should **read and interpret existing reality before asking the user to document more reality manually**.

For example:

```text
Filesystem          → discovered
Git repository      → discovered
Git branch          → discovered
Git status          → discovered
GitHub remote       → discovered
package manager     → discovered
dependencies        → discovered
build system        → discovered
generated output    → discovered
storage             → measured
deployment hints    → discovered
```

Only information a computer cannot reliably infer should require human context.

That might include:

```text
What are we building?
Why does it exist?
Who is it for?
What are we currently focused on?
What did we decide?
What is blocked?
What should happen next?
```

The result should be a project that is **heavier in understanding without becoming heavier in infrastructure**.

---

# Zero-Use Cost

One of SLUJ Dashboard's most important design constraints is:

> **If you do not use it, it should barely cost you anything.**

Adding SLUJ to a project should not mean:

- hundreds of dependencies
- a giant `node_modules`
- another database
- another SaaS account
- another synchronization service
- another background daemon
- another configuration system that constantly needs maintenance

The project-local footprint should remain deliberately small.

SLUJ should prefer:

- Markdown
- small structured files where necessary
- Git metadata
- GitHub primitives
- existing project configuration
- filesystem inspection
- generated runtime information

over inventing duplicate systems.

The underlying project should remain understandable without SLUJ.

SLUJ is an interface over the project.

It is not the project.

---

# Project Context

A software scanner can discover a great deal about a project.

It cannot discover everything.

It can identify:

```text
package.json
.git/
node_modules/
.next/
.env.local
origin/main
a Vercel configuration
3 modified files
842 MB of local storage
```

But it cannot reliably know:

> Why was this project started?

> What problem are we solving?

> Why did we choose this architecture?

> Which design direction is current?

> Why did we abandon the previous approach?

> What is the next thing that actually matters?

SLUJ therefore needs a **tiny human context layer** alongside automatically discovered technical context.

This idea grew out of the earlier Project Frame experiment: a reusable Markdown structure intended to keep product, design, development, research, decisions, tasks, and project history understandable over time.

SLUJ should preserve the strongest idea from Project Frame while becoming dramatically lighter.

Instead of requiring a deep folder hierarchy for every project, SLUJ can establish a small optional project-context convention.

A possible future shape might resemble:

```text
.sluj/
├── project.md
├── notes.md
├── decisions.md
└── tasks.md
```

This is conceptual, not finalized.

The important principle is:

> **SLUJ should automatically discover everything it reasonably can and ask humans to document only what machines cannot know.**

---

# SLUJ Dashboard

The dashboard should feel like a designed operating surface for a software project.

Not an admin dashboard.

Not Jira.

Not Linear.

Not a GitHub clone.

Not a terminal with prettier typography.

Not a wall of developer metrics.

It should feel like **beautiful industrial software for understanding a project**.

A possible high-level information architecture:

```text
SLUJ

PROJECT
├── Overview
├── Structure
├── Health
├── Work
├── Context
├── Activity
└── Learn
```

These categories are directional rather than final.

---

## Overview

The first screen should answer:

> **What is going on with this project right now?**

Possible information:

```text
PROJECT
PomoDorado

STATUS
Active

CURRENT FOCUS
Prototype core focus loop

LOCAL
~/Projects/pomodorado

GIT
main · clean

GITHUB
Connected

DEPLOYMENT
Not deployed

STACK
React · TypeScript

STORAGE
418 MB

WORK
3 open · 1 active · 7 complete
```

The overview should prioritize **meaning over metrics**.

Every number should help someone make a decision.

---

# Structure

SLUJ should provide a visual representation of the project's actual filesystem.

This is not just a file browser.

The tree should increasingly become an **interpretation layer**.

Example:

```text
pomodorado/
├── src/
├── public/
├── .git/
├── node_modules/
├── package.json
├── package-lock.json
└── README.md
```

SLUJ should eventually understand what these objects mean.

Selecting:

```text
node_modules/
```

could reveal:

```text
DEPENDENCIES

Size
684 MB

Authored by you
No

Rebuildable
Yes

Tracked by Git
No

Created by
npm

Recreate with
npm install
```

Selecting:

```text
.git/
```

could explain:

```text
GIT REPOSITORY DATA

Contains the local repository's:

• history
• branches
• references
• configuration

Current branch
main

Remote
origin

Provider
GitHub
```

The tree therefore becomes both navigation and education.

---

# Health

Project health should summarize signals already present across the filesystem and development tooling.

Possible health checks include:

- Git repository detected
- Git remote detected
- Git working tree clean
- current branch
- uncommitted changes
- package manager detected
- lockfile present
- dependencies installed
- environment configuration detected
- expected environment files missing
- build output detected
- known generated directories
- stale generated output
- deployment configuration detected
- GitHub repository reachable
- project context present
- unusually large local storage
- duplicate project clues
- broken or missing relationships
- abandoned/stale state indicators

Health should not become a meaningless score.

Avoid:

```text
PROJECT HEALTH
87/100
```

unless that number has an extremely defensible meaning.

Prefer specific, actionable statements:

```text
✓ Git remote connected
✓ Working tree clean
✓ Environment detected
△ 4 outdated dependencies
△ 612 MB of rebuildable dependencies
○ No deployment detected
```

SLUJ should explain **why something matters**.

---

# Work

SLUJ should include a lightweight work-management surface.

This is intentionally not intended to compete with full project-management platforms.

The project-local goal is:

> **What needs to happen next?**

A small Kanban-style surface could provide:

```text
TO DO
────────────
Issue 14
Create timer state

Issue 16
Prototype world tile


DOING
────────────
Issue 12
Define session model


DONE
────────────
Issue 08
Create README
```

The underlying work should remain portable.

Potential sources could include:

- GitHub Issues
- small local Markdown task files
- a lightweight structured task representation
- eventually another connected issue provider

When a GitHub repository exists, GitHub Issues may become a natural canonical store.

When one does not, SLUJ should still be capable of supporting lightweight local project work.

The dashboard should ideally **visualize existing project work rather than creating another isolated task database**.

---

# Issues

An especially useful future behavior would be making issue creation incredibly cheap.

Someone building a project often notices problems while working:

> Button alignment is wrong.

> Need empty state.

> Mobile navigation breaks.

> Investigate auth callback.

> Rename this component.

Instead of leaving these in:

- memory
- screenshots
- agent conversations
- random notes
- browser tabs
- sticky notes

SLUJ could provide a tiny universal capture action.

Create issue.

Done.

If the project is connected to GitHub, the issue can eventually synchronize with GitHub Issues.

The dashboard then becomes the visual work surface.

This is particularly valuable because the project itself remains the center of gravity.

---

# Context

Project context is the human meaning surrounding the technical project.

Possible context includes:

- project brief
- purpose
- audience
- current state
- current focus
- goals
- constraints
- decisions
- notes
- references
- design links
- documentation links
- known questions
- unresolved thinking

This layer should remain extremely lightweight.

SLUJ is not trying to replace Notion or Obsidian.

It is trying to preserve the **minimum context future-you needs to understand the project again**.

---

# Decisions

Decisions deserve explicit treatment because projects become difficult to understand when only the outcome survives.

Knowing:

> We use localStorage.

is less useful than knowing:

> We chose localStorage for v0 because the product does not yet require accounts or cross-device synchronization.

SLUJ should allow projects to preserve:

```text
Decision
Context
Reason
Date
Alternatives
Current status
```

without requiring an elaborate decision-management system.

Future SLUJ could also infer when major technical changes occurred and ask whether they represent decisions worth documenting.

---

# Notes

Projects need somewhere for lightweight thought.

Not every thought belongs in permanent documentation.

Not every note belongs in a personal knowledge system.

A tiny project-local notes surface could handle:

- scratch notes
- questions
- implementation discoveries
- debugging notes
- small ideas
- things to revisit
- useful commands
- temporary observations

The rule should remain:

> **Project notes belong to the project. Personal knowledge belongs to your personal knowledge system.**

---

# Activity

SLUJ can derive useful project history from systems that already contain history.

Potential sources:

- Git commits
- changed files
- created files
- branch changes
- GitHub activity
- issues
- deployments
- project-context changes

A simple activity view might look like:

```text
TODAY

10:42
Updated README

10:19
Created PomoDorado repository

09:58
Added project direction


YESTERDAY

18:31
Changed app navigation

17:02
Deployed production
```

This should not become surveillance.

It is project memory.

The purpose is to answer:

> **What happened here recently?**

---

# Storage

Storage remains an important SLUJ capability, but it is no longer the product definition.

Storage answers:

> **How much does this project actually weigh, and why?**

A project reported by Finder as:

```text
842 MB
```

does not tell someone much.

SLUJ should resolve that into:

```text
SOURCE
18 MB

DEPENDENCIES
612 MB

BUILD OUTPUT
173 MB

GIT HISTORY
31 MB

OTHER
8 MB
```

That immediately teaches the difference between authored work and regenerable material.

SLUJ's current storage classification vocabulary remains useful:

### KEEP

Authored work or source-of-truth material.

### REBUILDABLE

Generated material that can be recreated from source or configuration.

### CLEANABLE

Known disposable developer residue such as caches.

### REVIEW

Material SLUJ cannot classify confidently enough.

SLUJ should continue to prefer uncertainty over dangerous confidence.

Storage understanding should help users learn.

It should not become an aggressive cleanup product.

---

# Safety

Understanding comes before destructive action.

SLUJ should remain conservative around files and developer environments.

The current macOS implementation is read-only.

That principle should remain foundational.

SLUJ should never silently:

- delete files
- move files
- rewrite projects
- modify Git state
- remove dependencies
- delete caches
- archive repositories
- change deployments

Future actions may eventually exist, but they should be:

- explicit
- explainable
- reversible where possible
- tightly scoped
- supported by evidence

SLUJ should always be able to answer:

> Why are you recommending this?

---

# Git

Git is one of the central systems SLUJ should make legible.

SLUJ should help someone understand:

- whether a directory is a Git repository
- current branch
- repository status
- staged changes
- unstaged changes
- untracked files
- remotes
- upstream tracking
- local vs remote state
- commit history
- ignored files

The point is not to replace Git.

The point is to make Git **understandable in the context of the project**.

---

# GitHub

SLUJ should connect local projects to their GitHub counterparts.

Example:

```text
LOCAL
~/Projects/sluj

        ↓

GIT
origin

        ↓

GITHUB
wade/sluj
```

SLUJ should eventually identify:

- repositories connected correctly
- repositories existing only locally
- repositories existing only remotely
- archived repositories
- duplicate local clones
- stale repositories
- remote mismatches
- branches ahead or behind
- GitHub Issues
- relevant repository metadata

GitHub is not Git.

SLUJ should make that distinction obvious.

---

# Deployments

Projects increasingly exist across development and deployment systems.

SLUJ should eventually understand relationships such as:

```text
LOCAL PROJECT
       ↓
GIT REPOSITORY
       ↓
GITHUB
       ↓
VERCEL
       ↓
PRODUCTION DOMAIN
```

These systems are related but not equivalent.

SLUJ should help someone understand:

- whether a project is deployed
- which provider hosts it
- production vs preview
- which repository/branch feeds deployment
- which domain points to production
- whether deployment configuration appears stale
- whether a GitHub repository exists without a deployment
- whether a deployment exists for a project not currently present locally

A repository does **not** need a deployment.

A local project does **not** need GitHub.

SLUJ should visualize these states rather than treating one workflow as mandatory.

---

# Dependencies

Dependency management is one of the first places software projects become physically and conceptually confusing.

SLUJ should explain:

- which package manager a project uses
- direct dependencies
- development dependencies
- transitive dependencies
- installed dependency size
- lockfiles
- version relationships
- missing installations
- potentially outdated dependencies
- rebuildability

The goal is not merely:

```text
node_modules
612 MB
```

The goal is:

> This directory contains installed project dependencies.

> You did not author most of it.

> It can generally be recreated from the project's package manifest and lockfile.

That is understanding.

---

# Builds

SLUJ should distinguish authored source from generated output.

Examples may include:

```text
.next/
dist/
build/
DerivedData/
```

Different frameworks and platforms generate different output.

SLUJ should increasingly know:

- what generated the directory
- whether it is expected
- whether Git should track it
- whether it can be recreated
- how large it is
- what command rebuilds it

---

# Environment

Projects depend on environment configuration that often becomes invisible until something breaks.

SLUJ should identify environment-related files and configuration while treating secrets carefully.

Possible visibility:

```text
ENVIRONMENT

.env.local
Detected

Sensitive
Yes

Tracked by Git
No

Variables
8 detected
```

SLUJ should never expose secret values unnecessarily.

The product should teach the difference between:

- development configuration
- secrets
- production configuration
- local environment
- deployed environment

---

# Local vs Remote

This is one of SLUJ's most important educational concepts.

A project can simultaneously have several different states:

```text
Mac
│
├── local files
│
├── local Git repository
│
└── local generated output

GitHub
│
└── remote Git repository

Vercel
│
└── deployed application

Domain
│
└── public address
```

These are not interchangeable.

SLUJ should make the relationships visible.

---

# SLUJ for macOS

**Understand everything you're building.**

SLUJ Dashboard operates at the level of one project.

SLUJ for macOS operates at the level of the development environment.

The macOS app should answer questions like:

> What projects are on this computer?

> Which ones are active?

> Which exist on GitHub?

> Which are deployed?

> Which haven't been touched in months?

> Which have uncommitted work?

> Which projects exist locally but nowhere remotely?

> Which repositories exist remotely but are not cloned here?

> Which projects are consuming significant storage?

> Which ones contain rebuildable data?

> Which are likely abandoned?

> Which have missing project context?

> What was I working on recently?

> If I wiped this Mac today, what would survive?

A conceptual project index:

```text
SLUJ

PROJECTS

PomoDorado
Local        ✓
Git          ✓
GitHub       ✓
Deployment   —
Health       Good

Rabit
Local        ✓
Git          ✓
GitHub       ✓
Deployment   Vercel
Health       Attention

Old Experiment
Local        ✓
Git          —
GitHub       —
Deployment   —
Health       Unknown
```

The macOS application becomes the **fleet view**.

SLUJ Dashboard is the cockpit.

---

# One Project vs All Projects

The relationship should remain extremely simple:

```text
SLUJ Dashboard
one project
↓
deep understanding


SLUJ for macOS
all projects
↓
system understanding
```

Both products should eventually share as much of the same underlying project-inspection logic as practical.

---

# SLUJ Core

Conceptually, SLUJ should have a shared understanding engine.

```text
                   SLUJ CORE

                       │
        project inspection + interpretation
                       │
       ┌───────────────┴───────────────┐
       │                               │
SLUJ Dashboard                   SLUJ for macOS
```

Potential SLUJ Core responsibilities:

- filesystem inspection
- project detection
- Git inspection
- GitHub relationships
- package manifests
- dependencies
- build artifacts
- storage classification
- environment detection
- project health
- project context
- deployment signals
- project activity
- explanatory metadata

The existing `SLUJCore` architecture in the macOS project is an early technical foundation for this separation.

The current implementation should not be discarded simply because the product direction expanded.

The architecture should evolve deliberately.

---

# SLUJ Learn

**Understand development itself.**

SLUJ should not only tell someone what exists.

It should help them understand why it exists.

The emerging learning path covers the systems knowledge that often gets skipped when people learn development primarily through building.

## Developer Systems Literacy

1. Filesystem
2. Terminal
3. Projects
4. Package Managers
5. Git
6. GitHub
7. Branches
8. Dependencies
9. Environment Variables
10. Builds
11. Deployments
12. Caches
13. Local vs Remote
14. Backups
15. Archives
16. Naming
17. Deletion

This is not intended to replace conventional web-development education.

It addresses a different problem:

> **What the fuck am I actually looking at?**

Someone may already know how to create a React component while still not fully understanding:

- why `node_modules` exists
- what `.git` contains
- what `origin/main` means
- whether GitHub is a backup
- what Vercel actually stores
- whether `.next` is safe to remove
- where environment variables live
- what survives when a computer is wiped
- why package lockfiles matter
- what a cache actually is

SLUJ Learn fills in that connective tissue.

---

# Contextual Learning

The most important difference between SLUJ Learn and a normal tutorial is context.

Traditional documentation might say:

> `.next` is the default Next.js build output directory.

SLUJ can say:

```text
YOUR PROJECT

.next/
418 MB

Generated by
Next.js

Authored source
No

Rebuildable
Yes

Git tracked
No

Learn
Builds → Generated output
```

That transforms learning from abstraction into explanation of the person's actual environment.

Likewise:

```text
YOUR PROJECT

origin/main

origin
Your Git remote

main
The branch being referenced

Provider
GitHub

Learn
GitHub → Local vs Remote
```

The user learns development by understanding the development environment they already have.

That is a central SLUJ idea.

> **Learn your development environment by understanding the one you already have.**

---

# SLUJ Docs

SLUJ Learn and SLUJ Docs should be distinct.

## Learn

Explains development.

Example:

> What is Git?

## Docs

Explains SLUJ.

Example:

> How does SLUJ detect a Git repository?

Conceptually:

```text
SLUJ

├── Dashboard
│   Understand this project
│
├── macOS
│   Understand all projects
│
├── Learn
│   Understand development
│
└── Docs
    Understand SLUJ
```

Documentation should preferably remain:

- Markdown or MDX
- stored in Git
- portable
- source-controlled
- usable by humans
- usable by agents
- independent of a specific documentation SaaS

The final rendering platform can remain a separate decision.

---

# Canonical Documentation

SLUJ should prefer primary technical sources when teaching concepts.

Examples:

```text
Web platform
→ MDN

Git
→ git-scm.com

GitHub
→ GitHub Docs

npm
→ npm Docs

Next.js
→ Next.js Docs

Vercel
→ Vercel Docs

Cloudflare
→ Cloudflare Docs

Apple platforms
→ Apple Developer Documentation
```

SLUJ should be able to provide its own plain-language explanation while still showing:

> **Here is the canonical documentation behind this explanation.**

---

# BOOT → DIG → PROJECT

The existing BOOT / DIG / PROJECT concept can still remain useful, particularly as an onboarding and discovery model for SLUJ for macOS.

## BOOT

Name or select the project.

```text
SLUJ

What are we working on?

[ Reference Garden ]
```

## DIG

SLUJ discovers what belongs to the project.

Potential sources:

- local folder
- Git
- GitHub repository
- design file
- deployment
- domain
- project context
- references
- agent conversations

Discovery should be visible.

The user should see context assembling rather than stare at a generic loading spinner.

## PROJECT

SLUJ creates the project's understandable view.

Technical, creative, operational, and historical context converge into one project surface.

BOOT / DIG / PROJECT should not define the entire product architecture.

It is a useful interaction model for **discovering and assembling project context**.

---

# Automatic Understanding

SLUJ should aggressively reduce manual project maintenance.

If a fact can be confidently derived, SLUJ should derive it.

Examples:

```text
Project name
→ package metadata / folder / Git remote

Git state
→ Git

GitHub repository
→ Git remote

Package manager
→ lockfiles

Framework
→ dependencies + config

Dependencies
→ package manifest

Storage
→ filesystem

Recent activity
→ Git history

Deployment
→ provider configuration / integration

Project structure
→ filesystem
```

The user should not need to manually maintain a dashboard full of information the computer already knows.

---

# Human Context

SLUJ should reserve manual input for information with human meaning.

Examples:

```text
Why are we building this?

What is the current direction?

Who is this for?

What are we trying to learn?

Why did we choose this approach?

What is blocked?

What matters next?
```

This is the information future-you usually loses.

That is the information worth preserving deliberately.

---

# Agents

A predictable project-understanding layer is also useful for software agents.

Today, an agent entering a repository often has to infer project context by reading:

- README
- package files
- folder structure
- Git history
- random documentation
- scattered notes
- configuration
- previous conversations

SLUJ can provide a clearer project context surface.

A future agent could understand:

```text
PROJECT
PomoDorado

PURPOSE
Focus timer + persistent frontier progression

CURRENT FOCUS
Prototype timer/world loop

TECH
React

GIT
main · clean

GITHUB
connected

WORK
3 open issues

DECISIONS
Local-first v0

DEPLOYMENT
none
```

Project understanding becomes more predictable for:

- humans
- agents
- tools
- future collaborators

without requiring the project to depend on an AI system.

---

# Design Direction

SLUJ should be a meaningful design contribution to developer tooling.

The product should challenge the assumption that developer infrastructure must look:

- terminal-inspired
- cyberpunk
- hyper-dense
- enterprise
- metric-heavy
- GitHub-like
- Linear-like
- visually intimidating

SLUJ should feel considered.

Possible qualities:

- calm
- precise
- visual
- spatial
- information-dense without being overwhelming
- excellent typography
- excellent hierarchy
- restrained color
- meaningful status indicators
- high-quality tree interaction
- native-feeling where appropriate
- genuinely useful motion
- clear explanations
- progressive disclosure

The visual system should serve comprehension.

The project tree, status surfaces, health signals, inspector, work board, and context should feel like parts of **one designed object**.

The ambition is not merely:

> Make developer tooling prettier.

It is:

> **Design developer tooling for people who understand complex systems visually.**

---

# ADHD-Friendly by Structure, Not Gimmick

SLUJ should be particularly useful for people who build quickly, jump between projects, lose project context, accumulate unfinished work, or become overwhelmed by invisible technical state.

That does not mean covering the product in gamification.

It means reducing cognitive load through:

- fewer decisions
- persistent context
- obvious state
- visual structure
- clear next actions
- automatic discovery
- progressive disclosure
- human explanations
- reliable terminology
- low maintenance
- easy re-entry after absence

A successful SLUJ project should be understandable again after weeks or months away.

That is a more meaningful accessibility goal than simply adding productivity features.

---

# What SLUJ Is Not

SLUJ is not trying to become:

- Jira
- Linear
- Notion
- Obsidian
- Finder
- GitHub
- a Git GUI
- a disk cleaner
- a deployment platform
- a package manager
- a code editor
- a full IDE
- a cloud drive
- a generic AI assistant

SLUJ may surface information from several of these domains.

Its job is different:

> **SLUJ connects project information into understanding.**

---

# Product Principles

## 1. Understanding before action

Explain the system before changing the system.

## 2. Discover before asking

If SLUJ can determine something reliably, the user should not have to enter it manually.

## 3. Context should travel with the project

Project understanding should not depend entirely on a remote workspace.

## 4. Zero-use cost should approach zero

SLUJ should not burden projects that barely use it.

## 5. The underlying project remains portable

Removing SLUJ should not destroy the project's knowledge or functionality.

## 6. Prefer open project primitives

Filesystem, Markdown, Git, repository metadata, and documented formats should be preferred over proprietary state.

## 7. Uncertainty should be visible

SLUJ should distinguish:

```text
KNOWN
LIKELY
UNKNOWN
```

rather than invent certainty.

## 8. Every classification needs a reason

If SLUJ says something is rebuildable, stale, healthy, broken, connected, or safe, the user should be able to ask why.

## 9. Local-first by default

A project should be understandable without requiring a hosted SLUJ account.

## 10. Never hide the underlying system

SLUJ should reveal development concepts rather than creating another abstraction users become dependent on.

## 11. One project should remain simple

The local dashboard must resist feature creep.

## 12. All-project intelligence belongs in macOS

Cross-project complexity should not make every individual repository heavier.

## 13. Learning should emerge from context

Explain concepts at the moment they become relevant.

## 14. Design is functional

Beauty should improve comprehension, orientation, confidence, and desire to use the tool.

---

# Current Build

The current SLUJ implementation is a native macOS application written in:

- Swift 6
- SwiftUI
- Foundation
- Swift Concurrency
- limited AppKit where required

The current codebase includes a separated `SLUJCore` layer for project/storage logic and the native SLUJ application layer.

The present UI is primarily a functional wireframe for **storage understanding**.

Current implemented surfaces include:

- one native macOS window
- storage statistics
- grouping modes
- filters
- squarified treemap
- item selection
- inspector
- storage classifications
- confidence
- ownership
- reasoning
- evidence
- rebuild recipes
- folder selection

The storage model currently uses fixture-backed data.

The interface works.

The underlying real filesystem scanner is not yet complete.

BOOT, DIG, the complete PROJECT experience, SLUJ Dashboard, GitHub intelligence, project health, work management, cross-project understanding, and SLUJ Learn are **product direction**, not completed functionality.

The README and product documentation should remain explicit about that distinction.

## Repository layout

```text
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
└── scripts/make-app.sh
```

`SLUJCore` never imports SwiftUI. `TreemapLayout` is generic over `Identifiable` and imports neither SwiftUI nor SLUJCore, so the layout algorithm can be replaced on its own.

There are zero third-party dependencies. No backend, authentication, analytics, cloud services, or persistence.

## Build and run

Requires Xcode 16+ / Swift 6 on macOS 14+.

```bash
swift build
swift test

# launchable app bundle
./scripts/make-app.sh
open .build/release/SLUJ.app
```

`swift run SLUJ` also works for a quick debug launch.

Pass `--sample` to open straight into the fixture report, skipping the empty state — useful for design iteration and screenshots:

```bash
open -a .build/release/SLUJ.app --args --sample
```

## Repository documentation

- **[docs/PRODUCT_OVERVIEW.md](docs/PRODUCT_OVERVIEW.md)** — product document: problem, core idea, BOOT/DIG/PROJECT, project memory, character, scope, and direction
- **[docs/CHARACTER.md](docs/CHARACTER.md)** — the SLUJ character: states, motion principle, and how it maps to BOOT/DIG/PROJECT
- **[CLAUDE.md](CLAUDE.md)** — working notes and constraints for agents in this repo

---

# Current Storage Model

The current implementation classifies storage into:

```text
KEEP
REBUILDABLE
CLEANABLE
REVIEW
```

This remains useful.

Storage is now understood as one subsystem within the broader SLUJ project model.

A future project object might eventually contain:

```text
PROJECT

Identity
Context
Structure
Git
GitHub
Dependencies
Environment
Build
Deployment
Storage
Health
Work
Activity
Learning
```

Storage does not disappear.

It becomes properly contextualized.

---

# Emerging Product Architecture

Conceptually:

```text
                        SLUJ

                          │
                     SLUJ Core
                          │
            project understanding engine
                          │
          ┌───────────────┴───────────────┐
          │                               │
  SLUJ Dashboard                    SLUJ for macOS
      one project                    all projects
          │                               │
          └───────────────┬───────────────┘
                          │
                     SLUJ Learn
                          │
                 contextual education
                          │
                     SLUJ Docs
```

Potential understanding domains:

```text
Identity
Filesystem
Project Context
Git
GitHub
Dependencies
Environment
Builds
Deployments
Storage
Health
Issues
Tasks
Activity
Learning
```

This is directional architecture.

Implementation boundaries should be determined deliberately as the product evolves.

---

# The SLUJ Relationship Model

A project can be thought of as a network of related objects:

```text
                         PROJECT

                            │
           ┌────────────────┼────────────────┐
           │                │                │
        LOCAL              GIT             CONTEXT
           │                │                │
       Filesystem        History         Purpose
       Storage           Branches        Decisions
       Generated         Remote          Notes
       Source             │              Work
                           │
                        GITHUB
                           │
                  Issues / Repository
                           │
                       DEPLOYMENT
                           │
                    Production / Preview
                           │
                         DOMAIN
```

SLUJ should visualize these relationships.

The user should not have to mentally maintain this graph.

---

# The Long-Term Question

SLUJ ultimately tries to answer a deceptively simple question:

> **What the fuck is going on with my project?**

And then:

> **Why?**

And eventually:

> **What should I do about it?**

The first answer comes from inspection.

The second comes from explanation.

The third comes from understanding.

---

# Product Thesis

**SLUJ is a portable project operating layer and project-understanding system.**

At the individual-project level, SLUJ Dashboard gives every repo a lightweight visual cockpit for structure, health, work, context, and activity.

At the system level, SLUJ for macOS understands the collection of projects across the computer and their relationships to Git, GitHub, deployments, storage, and project history.

SLUJ Learn turns those same observations into contextual developer education.

SLUJ Docs explains the product itself.

Together:

```text
SLUJ Dashboard
Understand this project.

SLUJ for macOS
Understand everything you're building.

SLUJ Learn
Understand development.

SLUJ Docs
Understand SLUJ.
```

The goal is not to hide complexity.

The goal is to make complexity **legible**.

> **See it. Understand it. Learn why. Know what to do.**
