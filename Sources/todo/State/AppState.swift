import Foundation
import SwiftData
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    enum FocusSessionKind {
        case pomodoro
        case taskTimer
    }

    @Published var pendingCount: Int = 0
    @Published var dropOverlayVisible: Bool = false
    @Published var clipboardToast: ClipboardToast?
    @Published var parseNotice: String?
    @Published var focusTaskID: UUID?
    @Published var focusTaskTitle: String?
    @Published var focusRemainingSeconds: Int = 0
    @Published var focusIsRunning: Bool = false
    @Published var focusIsBreak: Bool = false
    @Published var focusModeNotice: String?
    @Published var selectedCategoryID: UUID?

    private var timer: Timer?
    private var breakMinutes: Int = 5
    private var focusSessionKind: FocusSessionKind = .pomodoro
    private var taskTimerCompletionHandler: (() -> Void)?

    var isFocusActive: Bool {
        focusTaskID != nil
    }

    var focusSessionLabel: String {
        switch focusSessionKind {
        case .pomodoro:
            return focusIsBreak ? "Mola" : "Odak"
        case .taskTimer:
            return "Gorev geri sayim"
        }
    }

    var focusTimeText: String {
        let minutes = focusRemainingSeconds / 60
        let seconds = focusRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func refreshPendingCount(using modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { item in
                !item.isCompleted && item.parentTask == nil
            }
        )
        let pendingTasks = (try? modelContext.fetch(descriptor)) ?? []
        pendingCount = pendingTasks.filter { task in
            task.category?.includeInMenuCount == true
        }.count
    }

    func startFocus(task: TaskItem, workMinutes: Int, breakMinutes: Int) {
        stopFocus()
        focusSessionKind = .pomodoro
        taskTimerCompletionHandler = nil
        focusTaskID = task.id
        focusTaskTitle = task.title
        focusIsBreak = false
        focusIsRunning = true
        focusRemainingSeconds = max(workMinutes, 1) * 60
        self.breakMinutes = max(breakMinutes, 1)
        startTimer()
    }

    func startTaskTimer(task: TaskItem, durationSeconds: Int, onCompletion: @escaping () -> Void) {
        stopFocus()
        focusSessionKind = .taskTimer
        taskTimerCompletionHandler = onCompletion
        focusTaskID = task.id
        focusTaskTitle = task.title
        focusIsBreak = false
        focusIsRunning = true
        focusRemainingSeconds = max(durationSeconds, 1)
        startTimer()
    }

    func toggleFocusRunning() {
        guard isFocusActive else { return }
        focusIsRunning.toggle()
        if focusIsRunning {
            startTimer()
        } else {
            invalidateTimer()
        }
    }

    func stopFocus() {
        invalidateTimer()
        focusTaskID = nil
        focusTaskTitle = nil
        focusRemainingSeconds = 0
        focusIsRunning = false
        focusIsBreak = false
        taskTimerCompletionHandler = nil
        focusSessionKind = .pomodoro
    }

    private func startTimer() {
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard focusIsRunning else { return }
        guard focusRemainingSeconds > 0 else {
            transitionIfNeeded()
            return
        }
        focusRemainingSeconds -= 1
        if focusRemainingSeconds == 0 {
            transitionIfNeeded()
        }
    }

    private func transitionIfNeeded() {
        if focusSessionKind == .taskTimer {
            taskTimerCompletionHandler?()
            focusModeNotice = "Sure doldu, gorev tamamlandi."
            sendFocusNotification(title: "Gorev zamanlayici", body: "Sure doldu, gorev tamamlandi.")
            stopFocus()
            return
        }

        if !focusIsBreak {
            focusIsBreak = true
            focusRemainingSeconds = breakMinutes * 60
            focusModeNotice = "Odak suresi bitti, mola basladi."
            sendFocusNotification(title: "Pomodoro", body: "Odak suresi tamamlandi. Mola zamani.")
        } else {
            focusModeNotice = "Mola bitti."
            sendFocusNotification(title: "Pomodoro", body: "Mola tamamlandi.")
            stopFocus()
        }
    }

    private func sendFocusNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct ClipboardToast: Identifiable {
    let id = UUID()
    let text: String
}

extension AppState {
    func handleClipboardCapture(_ text: String) {
        clipboardToast = ClipboardToast(text: text)
    }
}
