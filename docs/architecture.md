# Architecture

## Product boundary

The iPhone app is an **offline-first personal agent**, not an unrestricted autonomous process.

iOS remains the platform security boundary. The model can only reach application capabilities through typed Foundation Models tools. Tool implementations own validation, permission checks, data minimization, and authorization policy.

## Current data flow

```text
SwiftUI
   |
   v
AgentViewModel
   |
   v
LanguageModelSession / SystemLanguageModel
   |
   | chooses a typed tool
   v
CalendarTool | ReminderListTool | CreateReminderTool | ContactLookupTool
   |
   +--------------------+
   |                    |
   v                    v
ToolRuntime        Platform adapter
risk + activity   EventKit / Contacts
   |                    |
   | write?             | minimized result
   v                    |
User approval <---------+
   |
   v
tool result
   |
   v
SystemLanguageModel
   |
   v
final response
```

## Layers

### App

SwiftUI owns presentation and direct human interaction. It renders chat, model status, the tool activity timeline, and approval dialogs.

The UI is the only component that can resolve a pending write approval.

### Agent

`AgentViewModel` owns the active `LanguageModelSession`, conversation state, and the tool runtime.

The model receives tools at session creation and can decide when a read or write tool is relevant. It does **not** decide whether a mutation is authorized.

### Tool runtime

`ToolRuntime` centralizes cross-tool execution policy.

```swift
enum ToolRisk {
    case read
    case write
    case destructive
    case externalCommunication
}
```

Current rule:

- `read` — no additional app-level confirmation after the iOS privacy permission.
- `write` — explicit app-level confirmation required.
- `destructive` — explicit confirmation required.
- `externalCommunication` — explicit confirmation required.

A write tool suspends while approval is pending. Only the SwiftUI layer can resume it as approved or denied.

The runtime also keeps a bounded activity timeline with started, waiting, approved, denied, completed, and failed states.

### Platform adapters

Framework-specific APIs remain outside model-facing tools:

- `CalendarStore` → EventKit events
- `ReminderStore` → EventKit reminders
- `ContactStore` → Contacts

Raw EventKit and Contacts objects do not enter the language-model layer.

## Calendar

`CalendarTool` is read-only.

The model supplies one calendar date in `yyyy-MM-dd` form. `CalendarDateParser` also accepts today/tomorrow and heute/morgen. `CalendarStore` requests EventKit access when needed, executes a one-day query, and returns only title, time, all-day state, and calendar name.

## Reminders

`ReminderListTool` is read-only and can list incomplete reminders or include completed reminders when relevant.

`CreateReminderTool` is a `write` action:

```text
model proposes reminder
        |
        v
validate title/date
        |
        v
ToolRuntime requests approval
        |
   +----+----+
   |         |
 deny      approve
   |         |
 return      v
 denial   EventKit save
```

No call to `EKEventStore.save` occurs before the approval resolves to true.

## Contacts

`ContactLookupTool` searches by name and returns a minimized representation containing:

- display name
- up to five phone numbers
- up to five email addresses

Both full and limited Contacts authorization are accepted. Limited access naturally constrains which contacts the app can retrieve.

## Privacy

The current implementation sends no prompt, calendar event, reminder, contact value, or model response to a project-controlled server.

A later hybrid backend must be opt-in, visible in the UI, and separately configurable. Routing must never silently move private device data off-device.

## Model availability

The app treats these as normal states instead of crashes:

- device not eligible;
- Apple Intelligence disabled;
- model not ready or still downloading.

## Testing

CI performs:

1. a full iOS Simulator build of the app target;
2. unit tests on an available iOS 26 iPhone Simulator.

Current deterministic tests cover:

- risk classes that do and do not require confirmation;
- denial of a pending write approval;
- immediate handling of read authorization;
- ISO date parsing;
- German relative-date parsing;
- invalid-date rejection.

Device-only behavior such as real Apple Intelligence generation and actual Calendar/Reminders/Contacts permission prompts must still be validated on physical hardware.

## Future hybrid routing

A later release can introduce a replaceable model abstraction:

```text
small/private/current task -> on-device model
complex/large opt-in task  -> homelab or cloud model
```

Remote routing must remain explicit and observable.
