import Foundation
import Testing
@testable import Ebb

@Suite("EntryPersistence")
struct EntryPersistenceTests {
    @Test func saveFailedMessageIsUserFacing() {
        #expect(!EntryPersistence.saveFailedMessage.isEmpty)
        #expect(!EntryPersistence.deleteFailedMessage.isEmpty)
    }
}
