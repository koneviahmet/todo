import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var sourceType: String?
    var linkURLString: String?
    var linkTitle: String?
    var linkHost: String?
    var markdownNote: String?
    var richTextRTFData: Data?
    var updatedAt: Date
    var category: TaskCategory?
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.parentTask) var subtasks: [TaskItem]
    var parentTask: TaskItem?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        sourceType: String? = nil,
        linkURLString: String? = nil,
        linkTitle: String? = nil,
        linkHost: String? = nil,
        markdownNote: String? = nil,
        richTextRTFData: Data? = nil,
        category: TaskCategory? = nil,
        parentTask: TaskItem? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.sourceType = sourceType
        self.linkURLString = linkURLString
        self.linkTitle = linkTitle
        self.linkHost = linkHost
        self.markdownNote = markdownNote
        self.richTextRTFData = richTextRTFData
        self.updatedAt = createdAt
        self.category = category
        self.subtasks = []
        self.parentTask = parentTask
    }

    var linkURL: URL? {
        guard let linkURLString, let url = URL(string: linkURLString) else { return nil }
        return url
    }

    var isRootTask: Bool {
        parentTask == nil
    }

    var allSubtasksCompleted: Bool {
        !subtasks.isEmpty && subtasks.allSatisfy(\.isCompleted)
    }

    func setCompletionRecursively(_ completed: Bool) {
        isCompleted = completed
        completedAt = completed ? .now : nil
        updatedAt = .now
        for subtask in subtasks {
            subtask.setCompletionRecursively(completed)
        }
        updateParentCompletionFromChildren()
    }

    func updateParentCompletionFromChildren() {
        guard let parentTask else { return }
        let allCompleted = !parentTask.subtasks.isEmpty && parentTask.subtasks.allSatisfy(\.isCompleted)
        parentTask.isCompleted = allCompleted
        parentTask.completedAt = allCompleted ? .now : nil
        parentTask.updatedAt = .now
        parentTask.updateParentCompletionFromChildren()
    }
}
