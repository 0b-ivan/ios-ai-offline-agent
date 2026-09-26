import Foundation
import FoundationModels

struct ContactLookupTool: Tool {
    let name = "search_contacts"
    let description = """
    Searches the person's contacts by name.
    Use this only when the answer depends on private contact data.
    """

    private let store: ContactStore
    private let runtime: ToolRuntime

    @Generable
    struct Arguments {
        @Guide(description: "Name or partial name to search for.")
        let name: String
    }

    init(store: ContactStore, runtime: ToolRuntime) {
        self.store = store
        self.runtime = runtime
    }

    func call(arguments: Arguments) async throws -> String {
        let query = arguments.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return "A contact name is required."
        }

        await runtime.record(
            toolName: name,
            risk: .read,
            status: .started,
            summary: "Search contacts for “\(query)”."
        )

        do {
            let contacts = try await store.search(name: query)

            await runtime.record(
                toolName: name,
                risk: .read,
                status: .completed,
                summary: "Returned \(contacts.count) contact(s) for “\(query)”."
            )

            guard !contacts.isEmpty else {
                return "No matching contacts found for “\(query)”."
            }

            return contacts.map { contact in
                let phones = contact.phoneNumbers.isEmpty
                    ? "no phone number"
                    : contact.phoneNumbers.joined(separator: ", ")
                let emails = contact.emailAddresses.isEmpty
                    ? "no email address"
                    : contact.emailAddresses.joined(separator: ", ")

                return "\(contact.displayName) — phones: \(phones) — emails: \(emails)"
            }
            .joined(separator: "\n")
        } catch {
            await runtime.record(
                toolName: name,
                risk: .read,
                status: .failed,
                summary: error.localizedDescription
            )
            throw error
        }
    }
}
