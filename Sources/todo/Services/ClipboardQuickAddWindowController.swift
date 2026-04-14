import AppKit
import Foundation
import SwiftUI

@MainActor
final class ClipboardQuickAddWindowController {
    private var panel: NSPanel?
    private let compactPanelSize = NSSize(width: 52, height: 52)
    private let expandedPanelSize = NSSize(width: 300, height: 132)
    private let autoCloseDuration: TimeInterval = 10
    private var countdownTimer: Timer?
    private var countdownModel: ClipboardQuickAddCountdownModel?
    private var isExpanded: Bool = false

    func present(
        text: String,
        categories: [(id: UUID, name: String)],
        selectedCategoryID: UUID?,
        onAdd: @escaping (UUID?) -> Void
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ensurePanel()
        guard let panel else { return }

        let preview = String(trimmed.prefix(80))
        let displayText = trimmed.count > 80 ? "\(preview)..." : preview
        let countdownModel = ClipboardQuickAddCountdownModel(totalDuration: autoCloseDuration)
        self.countdownModel = countdownModel
        let content = ClipboardQuickAddView(
            countdownModel: countdownModel,
            text: displayText,
            categories: categories,
            selectedCategoryID: selectedCategoryID,
            onAdd: { [weak self] in
                onAdd($0)
                self?.close()
            },
            onDismiss: { [weak self] in
                self?.close()
            },
            onHoverChanged: { [weak self] isHovering in
                guard let self else { return }
                if isHovering {
                    self.pauseAutoClose()
                } else {
                    self.resumeAutoClose()
                }
            },
            onExpandedChanged: { [weak self] isExpanded in
                self?.setExpanded(isExpanded)
            }
        )
        panel.contentView = NSHostingView(rootView: content)
        isExpanded = false
        updatePanelSize(isExpanded: false)
        panel.orderFrontRegardless()
        scheduleAutoClose()
    }

    func close() {
        invalidateCountdown()
        countdownModel = nil
        isExpanded = false
        panel?.orderOut(nil)
    }

    private func ensurePanel() {
        guard panel == nil else { return }
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: compactPanelSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        self.panel = panel
    }

    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visibleFrame = screen.visibleFrame
        let origin = CGPoint(
            x: visibleFrame.maxX - size.width - 16,
            y: visibleFrame.maxY - size.height - 10
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func scheduleAutoClose() {
        countdownModel?.remainingDuration = autoCloseDuration
        countdownModel?.isPaused = false
        startCountdownIfNeeded()
    }

    private func startCountdownIfNeeded() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickCountdown()
            }
        }
    }

    private func tickCountdown() {
        guard let countdownModel else { return }
        guard !countdownModel.isPaused else { return }
        countdownModel.remainingDuration = max(0, countdownModel.remainingDuration - 0.05)
        if countdownModel.remainingDuration <= 0 {
            close()
        }
    }

    private func invalidateCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updatePanelSize(isExpanded: Bool) {
        guard let panel else { return }
        let targetSize = isExpanded ? expandedPanelSize : compactPanelSize
        positionPanel(panel, size: targetSize)
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded
        DispatchQueue.main.async { [weak self] in
            self?.updatePanelSize(isExpanded: expanded)
        }
    }

    private func pauseAutoClose() {
        countdownModel?.isPaused = true
    }

    private func resumeAutoClose() {
        guard let countdownModel else { return }
        guard countdownModel.remainingDuration > 0 else { return }
        countdownModel.isPaused = false
    }
}

@MainActor
final class ClipboardQuickAddCountdownModel: ObservableObject {
    let totalDuration: TimeInterval
    @Published var remainingDuration: TimeInterval
    @Published var isPaused: Bool = false

    init(totalDuration: TimeInterval) {
        self.totalDuration = totalDuration
        self.remainingDuration = totalDuration
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remainingDuration / totalDuration))
    }
}

private struct ClipboardQuickAddView: View {
    @ObservedObject var countdownModel: ClipboardQuickAddCountdownModel
    let text: String
    let categories: [(id: UUID, name: String)]
    let selectedCategoryID: UUID?
    let onAdd: (UUID?) -> Void
    let onDismiss: () -> Void
    let onHoverChanged: (Bool) -> Void
    let onExpandedChanged: (Bool) -> Void
    @State private var selectedID: UUID?
    @State private var isExpanded: Bool = false

    var body: some View {
        Group {
            if isExpanded {
                HStack(spacing: 10) {
                    countdownIcon
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Panodan")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }

                        Text(text)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)

                        HStack {
                            Picker("", selection: $selectedID) {
                                Text("Kategorisiz").tag(Optional<UUID>.none)
                                ForEach(categories, id: \.id) { category in
                                    Text(category.name).tag(Optional(category.id))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)

                            Button("Kaydet") {
                                onAdd(selectedID)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(4)
            } else {
                countdownIcon
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            selectedID = selectedCategoryID
        }
        .onChange(of: selectedCategoryID) { _, newValue in
            selectedID = newValue
        }
        .onHover { isHovering in
            onHoverChanged(isHovering)
            isExpanded = isHovering
            onExpandedChanged(isHovering)
        }
    }

    private var countdownIcon: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 3)
            Circle()
                .trim(from: 0, to: countdownModel.progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: "clipboard")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
        .frame(width: 34, height: 34)
    }
}
