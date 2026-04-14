import AppKit
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var hideWorkItem: DispatchWorkItem?
    private var onTextCaptured: ((String) -> Void)?

    func startMonitoring(onTextCaptured: @escaping (String) -> Void) {
        self.onTextCaptured = onTextCaptured
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func pollPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }
        lastChangeCount = pasteboard.changeCount
        guard let copiedText = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !copiedText.isEmpty else {
            return
        }
        onTextCaptured?(copiedText)
    }
}
