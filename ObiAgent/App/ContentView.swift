import SwiftUI

struct ContentView: View {
    @StateObject private var agent = AgentViewModel()

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
                                    description: Text("Frag zum Beispiel: „Was habe ich morgen vor?“")
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
        .foregroundStyle(agent.isModelAvailable ? .secondary : .orange)
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

#Preview {
    ContentView()
}
