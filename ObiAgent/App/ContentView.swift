import SwiftUI

struct ContentView: View {
    @StateObject private var agent = AgentViewModel()
    @State private var showingToolActivity = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modelStatus

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if agent.messages.isEmpty {
                                ContentUnavailableView(
                                    "Obi Agent",
                                    systemImage: "brain.head.profile",
                                    description: Text("Frag z. B. nach Kalender, Erinnerungen oder Kontakten.")
                                )
                                .padding(.top, 80)
                            }

                            ForEach(agent.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if agent.isResponding {
                                HStack {
                                    ProgressView()
                                    Text("Denke lokal …")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: agent.messages.count) {
                        guard let last = agent.messages.last else { return }
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Nachricht", text: $agent.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .submitLabel(.send)
                        .onSubmit {
                            Task { await agent.send() }
                        }

                    Button {
                        Task { await agent.send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(!agent.canSend)
                    .accessibilityLabel("Senden")
                }
                .padding()
            }
            .navigationTitle("Obi Agent")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingToolActivity = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                    .accessibilityLabel("Tool-Aktivität")
                }
            }
            .sheet(isPresented: $showingToolActivity) {
                ToolActivityView(activities: agent.toolActivities)
            }
            .alert(
                "Aktion bestätigen",
                isPresented: Binding(
                    get: { agent.pendingApproval != nil },
                    set: { isPresented in
                        if !isPresented, agent.pendingApproval != nil {
                            agent.resolvePendingApproval(approved: false)
                        }
                    }
                )
            ) {
                Button("Abbrechen", role: .cancel) {
                    agent.resolvePendingApproval(approved: false)
                }

                Button("Ausführen") {
                    agent.resolvePendingApproval(approved: true)
                }
            } message: {
                Text(agent.pendingApproval?.summary ?? "")
            }
        }
    }

    private var modelStatus: some View {
        HStack(spacing: 8) {
            Image(
                systemName: agent.isModelAvailable
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            Text(agent.modelStatus)
                .font(.footnote)
            Spacer()
        }
        .foregroundStyle(agent.isModelAvailable ? Color.secondary : Color.orange)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .padding(.horizontal)
    }

    private var bubble: some View {
        Text(message.text)
            .textSelection(.enabled)
            .padding(12)
            .background(
                message.role == .assistant
                    ? Color.secondary.opacity(0.12)
                    : Color.accentColor.opacity(0.16),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

private struct ToolActivityView: View {
    let activities: [ToolActivity]

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Tool-Aktivität",
                        systemImage: "wrench.and.screwdriver"
                    )
                } else {
                    List(activities) { activity in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(activity.toolName)
                                    .font(.headline)
                                Spacer()
                                Text(activity.risk.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(activity.summary)
                                .font(.subheadline)

                            HStack {
                                Text(activity.status.rawValue)
                                Spacer()
                                Text(activity.createdAt, style: .time)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Tool-Aktivität")
        }
    }
}

#Preview {
    ContentView()
}
