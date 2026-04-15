import SwiftUI
import SwiftData

struct DeleteTaskSceneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Query private var tasks: [TaskItem]

    init(taskID: UUID) {
        _tasks = Query(filter: #Predicate<TaskItem> { $0.id == taskID })
    }

    private var task: TaskItem? {
        tasks.first
    }

    var body: some View {
        Group {
            if let task {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Gorev tamamen silinsin mi?")
                        .font(.title3.bold())

                    Text("\"\(task.title)\" ve varsa alt gorevleri kalici olarak silinecek.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button("Vazgec") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Tamamen Sil", role: .destructive) {
                            deleteTask(task)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(18)
            } else {
                VStack(spacing: 12) {
                    ContentUnavailableView("Gorev bulunamadi", systemImage: "trash.slash")
                    Button("Kapat") {
                        dismiss()
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 360, minHeight: 160, idealHeight: 180, maxHeight: 180)
    }

    private func deleteTask(_ task: TaskItem) {
        deleteRecursively(task)
        do {
            try modelContext.save()
        } catch {
            print("Save error: \(error)")
        }
        appState.refreshPendingCount(using: modelContext)
    }

    private func deleteRecursively(_ task: TaskItem) {
        for subtask in task.subtasks {
            deleteRecursively(subtask)
        }
        modelContext.delete(task)
    }
}
