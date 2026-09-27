# Architecture

## Product boundary

The iPhone app is an **offline-first personal agent**, not an unrestricted autonomous process.

iOS remains the security boundary. The model can only perform operations exposed through explicit Swift tools, and every tool is responsible for authorization, validation, and data minimization.

## v0.1 data flow

```text
SwiftUI UI
    |
    v
AgentViewModel
    |
    v
SystemLanguageModel
    |
    | tool call
    v
CalendarTool
    |
    v
CalendarStore / EventKit
    |
    | event summaries
    v
SystemLanguageModel
    |
    v
final response
```

## Layers

### App

Owns presentation and interaction. It must not contain direct EventKit or model-provider logic.

### Agent

Owns the language-model session and conversation state.

Responsibilities:

- check model availability;
- maintain the active session;
- submit prompts;
- expose response state to the UI;
- eventually host policy decisions around tool risk and confirmation.

### Tools

A tool is the only path from model intent into application capabilities.

A future common policy should classify tools as:

```swift
enum ToolRisk {
    case read
    case write
    case destructive
    case externalCommunication
}
```

v0.1 only ships a read tool.

### Platform adapters

Platform-specific APIs such as EventKit stay behind small adapters. This keeps model-facing code testable and makes permission behavior explicit.

## Calendar tool

The model provides a calendar date as an ISO `yyyy-MM-dd` value. `CalendarDateParser` accepts that format and the local convenience terms today/tomorrow and heute/morgen.

`CalendarStore`:

1. checks EventKit authorization;
2. requests full calendar access only when needed;
3. creates a one-day predicate;
4. maps `EKEvent` objects into small value types;
5. returns only the fields the model needs.

Raw `EKEvent` objects never enter the model layer.

## Privacy

v0.1 sends no prompt, calendar event, or model response to a project-controlled server.

A later hybrid backend must be explicit, observable, and independently configurable.

## Model availability

The app treats these as normal product states:

- device not eligible;
- Apple Intelligence disabled;
- model not ready or still downloading.

## Future authorization model

Before write tools are added, execution will be separated into:

```text
model intent
    |
    v
typed tool request
    |
    v
policy evaluation
    |
    v
optional user confirmation
    |
    v
execution
    |
    v
auditable result
```

The model itself does not decide whether a destructive action is authorized.

## Hybrid routing

A later release can introduce a replaceable model abstraction:

```text
small/private/current task -> on-device model
complex/large opt-in task  -> homelab or cloud model
```

Routing must never silently move private device data off-device.
