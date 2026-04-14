import SwiftUI
import SwiftData

struct TaskTimerSceneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Query private var tasks: [TaskItem]

    @State private var hours: Int = 0
    @State private var minutes: Int = 25
    @State private var secondsValue: Int = 0

    init(taskID: UUID) {
        _tasks = Query(filter: #Predicate<TaskItem> { $0.id == taskID })
    }

    private var task: TaskItem? {
        tasks.first
    }

    private var totalSeconds: Int {
        (hours * 3600) + (minutes * 60) + secondsValue
    }

    var body: some View {
        Group {
            if let task {
                VStack(alignment: .leading, spacing: 10) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        timePicker("Saat", selection: $hours, range: 0...12)
                        timePicker("Dakika", selection: $minutes, range: 0...59)
                        timePicker("Saniye", selection: $secondsValue, range: 0...59)
                    }

                    HStack(spacing: 6) {
                        presetButton(label: "5 dk", seconds: 5 * 60)
                        presetButton(label: "15 dk", seconds: 15 * 60)
                        presetButton(label: "25 dk", seconds: 25 * 60)
                        presetButton(label: "45 dk", seconds: 45 * 60)
                    }

                    HStack {
                        Text(format(totalSeconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Iptal") {
                            dismiss()
                        }
                        .controlSize(.small)
                        Button("Tamam") {
                            startCountdown(for: task)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(12)
                .fixedSize()
            } else {
                ContentUnavailableView("Gorev bulunamadi", systemImage: "timer")
                    .padding(16)
                    .fixedSize()
            }
        }
    }

    private func startCountdown(for task: TaskItem) {
        appState.startTaskTimer(task: task, durationSeconds: max(1, totalSeconds)) {
            task.setCompletionRecursively(true)
            save()
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Save error: \(error)")
        }
        appState.refreshPendingCount(using: modelContext)
    }

    private func timePicker(_ title: String, selection: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(String(format: "%02d", selection.wrappedValue))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .frame(width: 74)
            Stepper("", value: selection, in: range)
                .labelsHidden()
                .controlSize(.small)
        }
    }

    private func presetButton(label: String, seconds: Int) -> some View {
        Button(label) {
            apply(seconds: seconds)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func apply(seconds: Int) {
        let safe = max(1, seconds)
        hours = safe / 3600
        minutes = (safe % 3600) / 60
        secondsValue = safe % 60
    }

    private func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
