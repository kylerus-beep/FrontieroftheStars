import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadSnapshot(context: ModelContext) throws -> (PersistedGameState, GameSnapshot) {
        let descriptor = FetchDescriptor<PersistedGameState>()
        if let existing = try context.fetch(descriptor).first {
            let snapshot = try decoder.decode(GameSnapshot.self, from: existing.snapshotData)
            return (existing, snapshot)
        }

        let snapshot = GameSnapshot.freshStart()
        let record = PersistedGameState(snapshotData: try encoder.encode(snapshot))
        context.insert(record)
        try context.save()
        return (record, snapshot)
    }

    func save(snapshot: GameSnapshot, into record: PersistedGameState, context: ModelContext) throws {
        record.updatedAt = .now
        record.schemaVersion = snapshot.schemaVersion
        record.snapshotData = try encoder.encode(snapshot)
        try context.save()
    }

    func reset(context: ModelContext) throws -> GameSnapshot {
        let descriptor = FetchDescriptor<PersistedGameState>()
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }

        let snapshot = GameSnapshot.freshStart()
        let record = PersistedGameState(snapshotData: try encoder.encode(snapshot))
        context.insert(record)
        try context.save()
        return snapshot
    }
}
