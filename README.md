# iOS AI Offline Agent

An offline-first personal AI agent for iPhone, built with SwiftUI and Apple's Foundation Models framework.

## Goal

The project explores a useful personal agent that:

- runs the default reasoning/conversation path on-device;
- uses explicit, typed tools instead of unrestricted device access;
- asks iOS for the minimum permissions required by each tool;
- keeps destructive or externally visible actions behind confirmation gates;
- can later route heavy workloads to an optional homelab/cloud backend.

The first milestone proves the complete local path:

> User prompt → on-device language model → Calendar tool → EventKit → model response.

## v0.1 scope

- SwiftUI chat interface
- Apple `SystemLanguageModel`
- `LanguageModelSession` with tool calling
- read-only calendar lookup through EventKit
- model availability handling
- minimal CI build
- architecture documentation

No cloud API key is required for the v0.1 agent path.

## Requirements

- Xcode with the iOS 26 SDK or newer
- iOS 26 or newer
- Apple Intelligence-capable device for on-device generation
- Apple Intelligence enabled and the system model downloaded
- Calendar permission for calendar questions

The model can be unavailable on Simulator. The UI handles that state explicitly.

## Run

1. Open `ObiAgent.xcodeproj`.
2. Select the `ObiAgent` target.
3. Choose your iPhone.
4. Build and run.
5. Ask: **"Was habe ich morgen vor?"**
6. Grant Calendar access when iOS requests it.

## Repository layout

```text
ObiAgent/
├── App/
│   ├── ObiAgentApp.swift
│   └── ContentView.swift
├── Agent/
│   ├── AgentViewModel.swift
│   └── ChatMessage.swift
├── Tools/
│   └── Calendar/
│       ├── CalendarDateParser.swift
│       ├── CalendarStore.swift
│       └── CalendarTool.swift
└── Supporting/
    └── Info.plist

docs/
└── architecture.md
```

## Design principles

1. **Offline first** — local inference is the default.
2. **Least privilege** — every capability is an explicit tool.
3. **Read before write** — read-only integrations ship before mutating ones.
4. **Human control** — destructive/external actions require confirmation.
5. **Replaceable model layer** — agent tools should not depend on one model provider.
6. **Observable behavior** — future releases will expose tool calls and authorization decisions in a debug timeline.

## Roadmap

- **v0.1** — chat + local model + calendar read
- **v0.2** — reminders, contacts, permission policy
- **v0.3** — local memory and conversation persistence
- **v0.4** — voice, App Intents, Action Button
- **v0.5** — location-aware actions
- **v0.6** — authenticated homelab tools
- **v0.7** — local document retrieval
- **v1.0** — hardened offline-first agent with optional hybrid routing

See [docs/architecture.md](docs/architecture.md) for the technical design.
