import Foundation
import SwiftData

/// Shared save helpers for symptom entry writes.
enum EntryPersistence {
    static let saveFailedMessage = "Couldn't save your entry. Try again in a moment."
    static let deleteFailedMessage = "Couldn't delete this entry. Try again in a moment."

    @discardableResult
    static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            NSLog("Symptom entry save failed: %@", error.localizedDescription)
            return false
        }
    }
}
