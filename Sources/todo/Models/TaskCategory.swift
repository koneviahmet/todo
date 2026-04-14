import Foundation
import SwiftData

@Model
final class TaskCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var includeInMenuCount: Bool
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.category) var tasks: [TaskItem]

    init(
        id: UUID = UUID(),
        name: String,
        includeInMenuCount: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.includeInMenuCount = includeInMenuCount
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.tasks = []
    }
}
