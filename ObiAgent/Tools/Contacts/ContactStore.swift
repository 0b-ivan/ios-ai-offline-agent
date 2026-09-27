import Contacts
import Foundation

struct ContactSummary: Sendable {
    let displayName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
}

actor ContactStore {
    enum StoreError: LocalizedError {
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Contacts access was not granted."
            }
        }
    }

    private let store = CNContactStore()

    func search(name: String) async throws -> [ContactSummary] {
        guard try await ensureAccess() else {
            throw StoreError.accessDenied
        }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]

        let predicate = CNContact.predicateForContacts(matchingName: name)
        let contacts = try store.unifiedContacts(
            matching: predicate,
            keysToFetch: keys
        )

        return contacts.prefix(20).map { contact in
            let components = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
            let displayName = components.isEmpty
                ? "Unnamed contact"
                : components.joined(separator: " ")

            let phoneNumbers = Array(
                contact.phoneNumbers
                    .map { $0.value.stringValue }
                    .prefix(5)
            )
            let emailAddresses = Array(
                contact.emailAddresses
                    .map { String($0.value) }
                    .prefix(5)
            )

            return ContactSummary(
                displayName: displayName,
                phoneNumbers: phoneNumbers,
                emailAddresses: emailAddresses
            )
        }
    }

    private func ensureAccess() async throws -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return try await store.requestAccess(for: .contacts)
        default:
            return false
        }
    }
}
