# SLUJ

**SLUJ remembers your projects.**

This is the canonical product document. It defines what SLUJ is, the experience
it is built around, and how much of that exists today.

---

## Table of contents

- [Product summary](#product-summary)
- [Problem](#problem)
- [Core idea](#core-idea)
- [Product principle](#product-principle)
- [The three moments](#the-three-moments)
  - [01 — BOOT](#01--boot)
  - [02 — DIG](#02--dig)
  - [03 — PROJECT](#03--project)
- [Reference Garden example](#reference-garden-example)
- [Project memory](#project-memory)
- [Storage and local context](#storage-and-local-context)
- [Agent context and capture](#agent-context-and-capture)
- [The SLUJ character](#the-sluj-character)
- [Product qualities](#product-qualities)
- [What SLUJ is not](#what-sluj-is-not)
- [Current scope](#current-scope)
- [Future direction](#future-direction)
- [Product language](#product-language)

---

## Product summary

SLUJ is a lightweight, living memory layer for projects. It understands the many
places and conversations a project exists across, and it brings them back
together into one coherent object.

A project is not a folder. A project is a folder, plus a repository, plus a
design file, plus a deployment, plus a domain, plus the references you saved,
plus the decisions you made, plus the things you told an agent, plus the ideas
you have not finished yet.

SLUJ holds that whole thing.

## Problem

A modern project is scattered by default. At any moment it may exist across:

- a local folder
- Git
- GitHub
- Figma
- deployments
- domains
- files and screenshots
- references and links
- conversations with AI agents
- prompts
- decisions
- unfinished ideas
- storage
- branches and commits
- documentation

None of those places know about each other. The connective tissue lives in your
head, and it decays. You end up re-deriving your own project every time you come
back to it: which folder was it, which branch was I on, where is the Figma file,
did I ship that, what did I decide about the specimen view, what was that
reference I saved.

The work is not lost. The context is.

## Core idea

**SLUJ remembers your projects.**

The shorter framing: **capture for projects.**

SLUJ should make a project feel like one object again, and answer the questions
you actually ask when you sit back down:

- Where does this project exist?
- What is connected to it?
- How much local storage is it using?
- What is the repository state?
- What branch am I on?
- Is anything uncommitted?
- Where is the Figma file?
- Where is production?
- What references have I saved for this project?
- What have I told agents about this project?
- What decisions have already been made?
- What am I still planning to do?
- What changed recently?
- What parts of the project are getting messy?

The goal is to reduce the mental overhead of remembering and manually organizing
all of it.

## Product principle

> **Capture first. Context accumulates. Organization emerges afterward.**

You should not have to perfectly file something at the exact moment it happens.
That is the failure mode of every organizational tool: it demands structure at
the point of lowest patience, while you are mid-thought.

SLUJ inverts it. If a project-related artifact appears while you are working,
SLUJ should eventually be capable of associating it with that project on its
own. Structure is a consequence of accumulated context, not a prerequisite for
capturing it.

## The three moments

The SLUJ experience is built around three moments: **BOOT → DIG → PROJECT**.

### 01 — BOOT

SLUJ starts almost completely bare. The application should feel quiet and
lightweight.

The primary interaction is essentially this:

```
SLUJ

What are we working on?

[ Reference Garden                    ]
```

You give SLUJ a project name. That begins discovery.

BOOT is intentionally minimal. SLUJ does not open onto a dashboard, a task
system, or a setup workflow. There is nothing to configure before the product is
useful.

You name the thing. SLUJ goes looking.

### 02 — DIG

DIG is the discovery phase, where the SLUJ agent investigates the project and
assembles its context.

The interface communicates discoveries as they happen:

```
Local project found
GitHub repository found
Figma file found
Production deployment found
Domain found
12 related references found
4 relevant agent conversations found
```

This is not a loading spinner with extra steps. The point is that you watch the
project context assemble itself — each discovery lands as a discrete, legible
fact rather than dissolving into an indeterminate progress bar.

DIG is a large part of the SLUJ personality. The SLUJ character reacts visually
while investigating. The experience should feel alive, smooth, playful, and
extremely polished without becoming heavy or distracting.

### 03 — PROJECT

After discovery, SLUJ opens the project.

This is not a generic SaaS dashboard of equally weighted cards. Think of it as a
**living project dossier** — a project file, a technical and creative memory
surface. It should make the entire context of one project understandable at a
glance.

Information areas:

| Area | Contents |
| --- | --- |
| **Identity** | project name, description, domain, status, last touched |
| **Local** | local path, folder structure, storage usage, largest directories, `node_modules` size, `.git` size, assets size, source size |
| **Git** | repository, branch, working tree status, uncommitted changes, recent commits, sync state |
| **Surfaces** | Figma, GitHub, deployment, domain, documentation, other important project URLs |
| **Memory** | previous decisions, relevant prompts, relevant agent conversations, notes, product direction |
| **References** | inspiration, saved links, Cosmos, Are.na, screenshots, external examples, research |
| **Open loops** | unfinished ideas, unresolved questions, planned improvements, things you said you wanted to revisit |
| **Activity** | what changed recently, recent files, recent commits, recent project-related actions |

The dashboard stays visually calm even when the information is dense. Density is
allowed; noise is not.

## Reference Garden example

Reference Garden is the canonical example used throughout this document.

> **Illustrative only.** The values below demonstrate the mental model. They are
> not verified data about any real project, and SLUJ does not produce them
> today.

You boot SLUJ and enter:

```
Reference Garden
```

SLUJ begins DIG, and opens onto something like:

```
REFERENCE GARDEN

Local              ~/Projects/ref-garden
GitHub             w-ade/ref-garden
Website            ref.garden
Figma              Reference Garden
Deployment         Vercel
Storage            428 MB
Git                main · 12 uncommitted changes

Project structure
  src/
  components/
  public/
  references/

Recent activity
  worked on component specimens
  changed landing layout
  added animation references

References
  Cosmos links
  interaction references
  component inspiration
  animation studies

Agent memory
  discussions about making Ref Garden a living reference library
  plans for copyable components
  animation studies
  interface specimens
  decisions about visual direction

Open loops
  redesign specimen view
  add copyable components
  add animation studies
  improve project structure
```

Read that top to bottom and you know where the project lives, what state it is
in, what you were last doing, what you already decided, and what you still owe
it. That is the entire product in one screen.

## Project memory

Memory is what separates SLUJ from a dashboard. A dashboard shows current state.
Memory shows how the project got here.

Memory covers:

- **Decisions** — what was settled, so it is not relitigated
- **Prompts and agent conversations** — what you have already explained about
  this project, and to whom
- **Notes and product direction** — the intent behind the code
- **References** — the inspiration and research the work is drawing on
- **Open loops** — the ideas, questions, and improvements still outstanding

Open loops matter as much as decisions. Most project context is lost in the gap
between "I should do that at some point" and the next time you open the folder.

## Storage and local context

Storage is not discarded from the product — it becomes one part of the larger
project-memory model.

Storage answers "how much does this project weigh, and where is the weight?"
A project should eventually be able to show:

```
REFERENCE GARDEN

Local                       428 MB
  node_modules              311 MB
  .git                       74 MB
  assets                     28 MB
  source                     15 MB

GitHub                      synced
Production                  live
Working tree                dirty
Last touched                today
```

The core promise:

> **This project exists in 3 places. Here they are.**

Storage information helps you understand project weight, duplication, clutter,
and local organization. It exists to describe a project, not to sell you a
cleanup. SLUJ is not a disk cleaner.

The existing classification work serves this: material is distinguished as
authored work versus material that can be rebuilt, so "428 MB" resolves into
"15 MB you wrote and 311 MB `npm` can regenerate." See
[README](../README.md#classification-model) for the current model, and
[Current scope](#current-scope) for what is actually implemented.

## Agent context and capture

Increasingly, a large share of project context is produced in conversation with
agents — decisions, plans, references, and URLs that never land in a file.

**Intended behavior.** If you tell an agent:

> "Draw this on the Reference Garden Figma page." *(with the Figma URL)*

SLUJ should understand that the Figma file belongs to Reference Garden, and
preserve that relationship inside the Reference Garden project context. You said
it once, in the natural course of working. That should be enough.

The same applies to anything shared while discussing a project:

- a Cosmos reference
- an Are.na link
- a GitHub repo
- a deployment URL
- a local directory
- a screenshot
- a design reference

SLUJ should eventually recognize and capture these as part of that project's
living context.

> **Status: not implemented.** No automatic capture exists today. This section
> describes intended product behavior, not current behavior.

## The SLUJ character

The name is intentionally weird and fun, and the product keeps that personality.

The SLUJ character is the little creature that digs through project sludge and
comes back with useful context. Its states should track what the agent is
actually doing:

| State | Meaning |
| --- | --- |
| Idle | waiting, quiet |
| Scanning | looking around |
| Digging | actively investigating (the DIG phase) |
| Found something | a discovery landed |
| Thinking | reasoning about what it found |
| Concerned | the project is messy |
| Satisfied | the project is clean and understood |

The character is not decoration. It reinforces what the agent is doing, and it
stays quiet when nothing is happening.

The logo/mark may eventually carry subtle motion, in the manner of highly
polished native applications where the brand mark feels alive. Motion should be
subtle, smooth, premium, lightweight, and purposeful.

## Product qualities

SLUJ should feel:

- extremely polished, visually top-tier
- smooth, lightweight, fast
- local-aware and technically competent
- playful without becoming childish
- dense when necessary, never overwhelming
- useful before impressive
- alive without being distracting

One hard constraint: the application must stay light enough that using a
project-management tool does not itself become another heavy project.

## What SLUJ is not

SLUJ is not:

- Jira, Linear, or Notion
- a generic task manager or Kanban board
- a traditional project-management suite
- merely a storage analyzer
- merely a Git GUI
- merely a bookmark manager

It surfaces information from several of those domains without becoming any one
of them. It is also not a disk cleaner, a file manager, or a deletion tool — see
the read-only guarantee in [README](../README.md#safety).

## Current scope

Honest accounting of the gap between this document and the code.

**What exists today (v0.1):** a functional wireframe of the storage layer, as a
single native macOS window.

- squarified treemap sized by real proportions, with selection
- three grouping modes: By Project, By Type, Reclaimability
- per-classification filtering
- an inspector showing path, size, classification, confidence, ownership,
  reasoning, evidence, and rebuild recipe
- the reclaimable invariants, enforced in the model and covered by tests
- folder selection via `NSOpenPanel`

**Fixture-backed:** every number in the UI. The report comes from
`Sources/SLUJ/Fixtures/FixtureReport.swift`. Choosing folders records the URLs
you picked and then shows that same fixture report.

**Not built yet:**

- BOOT, DIG, and PROJECT — none of the three moments exist in the app
- the filesystem crawler (`FilesystemScanner.scan` throws
  `ScannerError.notImplemented` on purpose)
- any project model beyond storage: Git state, surfaces, memory, references,
  open loops, activity
- any automatic capture, agent-context ingestion, or persistence
- the SLUJ character and its states

The immediate technical step is unchanged: implement the real scanner behind the
existing `StorageScanner` protocol. Local truth first — a project view built on
fixtures cannot tell you anything you did not already know.

## Future direction

Roughly ordered, deliberately not a schedule:

1. **Real local truth.** Implement the filesystem scanner behind
   `StorageScanner`, so storage figures describe the actual machine.
2. **The project object.** A project becomes a first-class model — identity,
   local path, and storage — rather than a report over folders.
3. **Git state.** Branch, working tree, uncommitted changes, recent commits,
   sync state.
4. **Surfaces.** GitHub, Figma, deployment, and domain attached to a project,
   answering "this project exists in N places."
5. **BOOT and DIG.** Name a project, watch its context assemble.
6. **Memory, references, and open loops.** Decisions, notes, saved links, and
   unfinished ideas that persist across sessions.
7. **Capture.** Recognizing project-related artifacts as they appear, including
   from agent conversations.
8. **Character and motion.** The SLUJ creature, its states, and a mark that
   feels alive.

Each step should be useful on the day it ships. SLUJ earns the right to remember
more by being correct about what it already knows.

## Product language

The strongest phrasing, to be used where it fits naturally rather than forced
into every surface:

> **SLUJ remembers your projects.**
>
> **Capture for projects.**
>
> **Project memory.**
>
> **Your project, wherever it exists.**
>
> **Capture first. Context accumulates. Organization emerges afterward.**
>
> **This project exists in 3 places. Here they are.**
