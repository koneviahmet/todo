import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()
    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleReminder(for task: TaskItem) {
        guard let dueDate = task.dueDate, dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "todo hatirlatici"
        content.body = task.title
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
