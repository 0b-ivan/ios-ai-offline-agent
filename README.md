# iOS AI Offline Agent

An offline-first personal AI agent for iPhone, built with SwiftUI and Apple's Foundation Models framework.

## Goal

Build a useful personal agent that:

- runs its default reasoning and conversation path on-device;
- reaches private device data only through explicit typed tools;
- asks iOS for the minimum permissions required by each integration;
- keeps write, destructive, and external-communication actions behind app-level confirmation;
- can later route heavy workloads to an optional homelab/cloud backend.

The core path is:

> User prompt → on-device language model → typed tool → iOS framework → model response.

## Current v0.2 capabilities

- SwiftUI chat interface
- Apple `SystemLanguageModel`
- persistent `LanguageModelSession` with tool calling
- read-only Calendar lookup through EventKit
- read-only Reminders lookup
- Reminder creation with explicit in-app approval before `save`
- Contacts lookup with full or limited Contacts authorization
- central `ToolRisk` policy
- tool activity timeline for debugging
- model availability handling
- CI build and unit tests
- architecture documentation

No cloud API key is required for the current agent path.

## Requirements

- Xcode with the iOS 26 SDK or newer
- iOS 26 or newer
- Apple Intelligence-capable device for on-device generation
- Apple Intelligence enabled and the system model downloaded
- Calendar, Reminders, and Contacts permissions only when their tools are used

The system model can be unavailable on Simulator. The UI handles that state explicitly; CI uses Simulator only for compilation and deterministic unit tests.

## Try it on device

1. Open `ObiAgent.xcodeproj`.
2. Select the `ObiAgent` scheme.
3. Choose your iPhone.
4. Build and run.
5. Try:
   - **"Was habe ich morgen vor?"**
   - **"Welche Erinnerungen habe ich?"**
   - **"Suche Luca in meinen Kontakten."**
   - **"Erinnere mich morgen an Backup prüfen."**
6. Grant the relevant iOS permission when requested.
7. Reminder creation must show a second app-level approval dialog before the write occurs.

## Repository layout

```text
ObiAgent/
├── App/
│   ├── ObiAgentApp.swift
│   └── ContentView.swift
├── Agent/
│   ├── AgentViewModel.swift
│   ├── ChatMessage.swift
│   └── ToolRuntime.swift
├── Tools/
│   ├── Calendar/
│   ├── Reminders/
│   └── Contacts/
└── Supporting/
    └── Info.plist

ObiAgentTests/
├── CalendarDateParserTests.swift
└── ToolRuntimeTests.swift

docs/
└── architecture.md
```

## Security model

```text
model intent
    ↓
typed tool request
    ↓
ToolRisk policy
    ↓
read ───────────────────────────────► execute
write/destructive/external action ──► user approval
                                       ↓
                                  execute / deny
```

The language model cannot approve its own write action.

## Design principles

1. **Offline first** — local inference is the default.
2. **Least privilege** — every capability is an explicit tool.
3. **Data minimization** — platform objects are mapped into small model-facing values.
4. **Human control** — mutations and externally visible actions require app-level approval.
5. **Replaceable model layer** — device tools must not depend on one remote provider.
6. **Observable behavior** — tool execution and authorization decisions are visible in the activity timeline.

## Roadmap

- **v0.1** — chat + local model + calendar read
- **v0.2** — reminders, contacts, permission policy, activity timeline
- **v0.3** — local memory and conversation persistence
- **v0.4** — voice, App Intents, Action Button
- **v0.5** — location-aware actions
- **v0.6** — authenticated homelab tools
- **v0.7** — local document retrieval
- **v1.0** — hardened offline-first agent with optional hybrid routing

See [docs/architecture.md](docs/architecture.md) for the technical design.
