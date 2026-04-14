import SwiftUI
import SwiftData
import AppKit

struct TaskDetailSceneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: AppState
    @Query private var tasks: [TaskItem]
    @State private var draftTitle: String = ""
    @State private var newSubtaskTitle: String = ""
    @State private var subtaskSearchText: String = ""
    @State private var isSubtaskSearchMode: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var isSelectingCompletedSubtasks: Bool = false
    @State private var selectedCompletedSubtaskIDs: Set<UUID> = []

    init(taskID: UUID) {
        _tasks = Query(filter: #Predicate<TaskItem> { $0.id == taskID })
    }

    private var task: TaskItem? {
        tasks.first
    }

    private var sortedSubtasks: [TaskItem] {
        guard let task else { return [] }
        return task.subtasks.sorted(by: { $0.createdAt < $1.createdAt })
    }

    private var filteredSubtasks: [TaskItem] {
        let keyword = subtaskSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return sortedSubtasks }
        return sortedSubtasks.filter { subtask in
            subtask.title.localizedCaseInsensitiveContains(keyword) ||
            (subtask.markdownNote?.localizedCaseInsensitiveContains(keyword) ?? false)
        }
    }

    private var filteredCompletedSubtasks: [TaskItem] {
        filteredSubtasks.filter(\.isCompleted)
    }

    var body: some View {
        Group {
            if let task {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gorev Detayi")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            if isEditingTitle {
                                TextField("Gorev basligi", text: $draftTitle)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        updateTitle(for: task)
                                        isEditingTitle = false
                                    }
                            } else {
                                Text(draftTitle.isEmpty ? task.title : draftTitle)
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if isEditingTitle {
                                Button {
                                    updateTitle(for: task)
                                    isEditingTitle = false
                                } label: {
                                    Image(systemName: "checkmark")
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    draftTitle = task.title
                                    isEditingTitle = false
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(.bordered)
                            } else {
                                if !task.isCompleted {
                                    Button {
                                        openTaskTimer(for: task)
                                    } label: {
                                        Image(systemName: "clock.badge.plus")
                                    }
                                    .buttonStyle(.bordered)
                                    .help("Sure belirle ve geri sayim baslat")
                                }

                                Button {
                                    isEditingTitle = true
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .help("Basligi duzenle")
                            }
                        }

                        Toggle(isOn: Binding(
                            get: { task.isCompleted },
                            set: { isCompleted in
                                task.setCompletionRecursively(isCompleted)
                                save()
                            }
                        )) {
                            Text("Tamamlandi")
                                .font(.subheadline)
                        }
                        .toggleStyle(.checkbox)

                        if let dueDate = task.dueDate {
                            Text("Son tarih: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                    )

                    Divider()

                    Text("Alt Gorevler")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField(
                            isSubtaskSearchMode ? "Alt gorev ara..." : "Alt gorev ekle...",
                            text: isSubtaskSearchMode ? $subtaskSearchText : $newSubtaskTitle
                        )
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                guard !isSubtaskSearchMode else { return }
                                addSubtask(to: task)
                            }

                        if isSubtaskSearchMode {
                            if !subtaskSearchText.isEmpty {
                                Button {
                                    subtaskSearchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                isSubtaskSearchMode = false
                                subtaskSearchText = ""
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Ekle") {
                                addSubtask(to: task)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button {
                                isSubtaskSearchMode = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if !filteredCompletedSubtasks.isEmpty {
                        HStack(spacing: 8) {
                            if isSelectingCompletedSubtasks {
                                Text("\(selectedCompletedSubtaskIDs.count) secili")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Button("Tumunu Sec") {
                                    selectedCompletedSubtaskIDs = Set(filteredCompletedSubtasks.map(\.id))
                                }
                                .buttonStyle(.bordered)
                                .disabled(filteredCompletedSubtasks.isEmpty || selectedCompletedSubtaskIDs.count == filteredCompletedSubtasks.count)

                                Button("Secimi Temizle") {
                                    selectedCompletedSubtaskIDs.removeAll()
                                }
                                .buttonStyle(.bordered)
                                .disabled(selectedCompletedSubtaskIDs.isEmpty)

                                Button("Secilenleri Sil", role: .destructive) {
                                    deleteSelectedCompletedSubtasks(from: task)
                                }
                                .buttonStyle(.bordered)
                                .disabled(selectedCompletedSubtaskIDs.isEmpty)

                                Button("Iptal") {
                                    isSelectingCompletedSubtasks = false
                                    selectedCompletedSubtaskIDs.removeAll()
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button("Tamamlananlari Sec") {
                                    isSelectingCompletedSubtasks = true
                                    selectedCompletedSubtaskIDs.removeAll()
                                }
                                .buttonStyle(.bordered)
                            }

                            Spacer()
                        }
                    }

                    List {
                        ForEach(filteredSubtasks) { subtask in
                            SubtaskRowView(
                                subtask: subtask,
                                isSelectionMode: isSelectingCompletedSubtasks,
                                isSelected: selectedCompletedSubtaskIDs.contains(subtask.id),
                                onToggle: {
                                    subtask.isCompleted.toggle()
                                    subtask.completedAt = subtask.isCompleted ? .now : nil
                                    subtask.updatedAt = .now
                                    if !subtask.isCompleted {
                                        selectedCompletedSubtaskIDs.remove(subtask.id)
                                    }
                                    subtask.updateParentCompletionFromChildren()
                                    save()
                                },
                                onSelectionToggle: {
                                    guard subtask.isCompleted else { return }
                                    if selectedCompletedSubtaskIDs.contains(subtask.id) {
                                        selectedCompletedSubtaskIDs.remove(subtask.id)
                                    } else {
                                        selectedCompletedSubtaskIDs.insert(subtask.id)
                                    }
                                },
                                onDelete: {
                                    modelContext.delete(subtask)
                                    selectedCompletedSubtaskIDs.remove(subtask.id)
                                    task.updateParentCompletionFromChildren()
                                    save()
                                },
                                onOpenMarkdown: {
                                    openSubtaskMarkdown(for: subtask)
                                },
                                onSetTimer: {
                                    openTaskTimer(for: subtask)
                                }
                            )
                            .listRowSeparator(.hidden)
                        }
                        if filteredSubtasks.isEmpty {
                            ContentUnavailableView(subtaskSearchText.isEmpty ? "Alt gorev yok" : "Arama sonucu yok", systemImage: "tray")
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    Spacer()
                }
                .padding()
                .onAppear {
                    draftTitle = task.title
                    isEditingTitle = false
                }
                .onChange(of: filteredSubtasks.map(\.id)) { _, filteredIDs in
                    let filteredSet = Set(filteredIDs)
                    selectedCompletedSubtaskIDs = selectedCompletedSubtaskIDs.intersection(filteredSet)
                    if filteredSet.isEmpty {
                        isSelectingCompletedSubtasks = false
                    }
                }
            } else {
                ContentUnavailableView("Gorev bulunamadi", systemImage: "exclamationmark.triangle")
            }
        }
        .frame(minWidth: 260, minHeight: 460)
    }

    private func updateTitle(for task: TaskItem) {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            draftTitle = task.title
            return
        }
        task.title = trimmed
        task.updatedAt = .now
        save()
    }

    private func addSubtask(to task: TaskItem) {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let detectedURL = detectedLinkURL(from: trimmed)
        let isURLSubtask = detectedURL != nil
        let subtask = TaskItem(
            title: trimmed,
            sourceType: isURLSubtask ? "url" : "subtask",
            linkURLString: detectedURL?.absoluteString,
            linkHost: detectedURL.flatMap { normalizedHost(from: $0) },
            category: task.category,
            parentTask: task
        )
        modelContext.insert(subtask)
        task.updatedAt = .now
        save()
        if let detectedURL {
            fetchLinkMetadataIfNeeded(for: subtask, url: detectedURL)
        }
        newSubtaskTitle = ""
    }

    private func deleteSelectedCompletedSubtasks(from task: TaskItem) {
        let subtasksToDelete = task.subtasks.filter {
            $0.isCompleted && selectedCompletedSubtaskIDs.contains($0.id)
        }
        guard !subtasksToDelete.isEmpty else { return }

        for subtask in subtasksToDelete {
            modelContext.delete(subtask)
        }

        selectedCompletedSubtaskIDs.removeAll()
        isSelectingCompletedSubtasks = false
        task.updateParentCompletionFromChildren()
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Save error: \(error)")
        }
        appState.refreshPendingCount(using: modelContext)
    }

    private func openSubtaskMarkdown(for subtask: TaskItem) {
        openWindow(id: "subtask-markdown-window", value: subtask.id)
    }

    private func openTaskTimer(for task: TaskItem) {
        openWindow(id: "task-timer-window", value: task.id)
        positionTimerWindowUnderMenuBar()
    }

    private func detectedLinkURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed), isWebURL(url) else { return nil }
        return url
    }

    private func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func normalizedHost(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func fetchLinkMetadataIfNeeded(for subtask: TaskItem, url: URL) {
        guard subtask.linkTitle == nil || subtask.linkTitle?.isEmpty == true else { return }
        Task {
            let metadata = await LinkMetadataFetcher.shared.fetch(for: url)
            if let title = metadata.title, !title.isEmpty {
                subtask.linkTitle = title
                subtask.title = title
            }
            if let host = metadata.host, !host.isEmpty {
                subtask.linkHost = host
            }
            subtask.updatedAt = .now
            save()
        }
    }

    private func positionTimerWindowUnderMenuBar() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.title.localizedCaseInsensitiveContains("Gorev Zamanlayici") }),
                  let screen = window.screen ?? NSScreen.main else { return }
            let visible = screen.visibleFrame
            let size = window.frame.size
            let x = visible.maxX - size.width - 14
            let y = visible.maxY - size.height - 8
            window.setFrameOrigin(NSPoint(x: x, y: y))
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
}

private struct SubtaskRowView: View {
    let subtask: TaskItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onSelectionToggle: () -> Void
    let onDelete: () -> Void
    let onOpenMarkdown: () -> Void
    let onSetTimer: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            if subtask.isCompleted && isSelectionMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                }
                .buttonStyle(.plain)
            }

            Button(action: onOpenMarkdown) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subtask.title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let linkHost = subtask.linkHost, !linkHost.isEmpty {
                        Text(linkHost)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            if !subtask.isCompleted {
                Button(action: onSetTimer) {
                    Image(systemName: "clock.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Sure belirle ve geri sayim baslat")
            }

            if let linkURL = subtask.linkURL {
                Button {
                    NSWorkspace.shared.open(linkURL)
                } label: {
                    Image(systemName: "link")
                }
                .buttonStyle(.borderless)
                .help("Linki ac")
            }

            Button(action: onOpenMarkdown) {
                Image(systemName: "doc.text")
            }
            .buttonStyle(.borderless)
            .help("Markdown aciklama duzenle")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if subtask.isCompleted && isSelectionMode {
                onSelectionToggle()
            } else {
                onOpenMarkdown()
            }
        }
    }
}

struct SubtaskMarkdownSceneView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query private var subtasks: [TaskItem]
    @State private var attributedText = NSAttributedString(string: "")
    @State private var pendingSaveWorkItem: DispatchWorkItem?
    @StateObject private var editorContext = RichTextEditorContext()

    init(subtaskID: UUID) {
        _subtasks = Query(filter: #Predicate<TaskItem> { $0.id == subtaskID })
    }

    private var subtask: TaskItem? {
        subtasks.first
    }

    var body: some View {
        Group {
            if let subtask {
                VStack(alignment: .leading, spacing: 10) {
                    RichTextEditorRepresentable(
                        attributedText: $attributedText,
                        context: editorContext,
                        style: settings.editorStylePreset.config
                    ) {
                        scheduleAutosave(for: subtask)
                    }
                    .background(
                        Color(nsColor: settings.editorStylePreset.config.background),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(alignment: .topTrailing) {
                        Picker("", selection: $settings.editorStylePreset) {
                            ForEach(EditorReadabilityStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .padding(.top, 6)
                        .padding(.trailing, 8)
                    }
                }
                .padding()
                .onAppear {
                    attributedText = decodedAttributedText(from: subtask)
                }
                .onDisappear {
                    commitChanges(for: subtask)
                }
            } else {
                ContentUnavailableView("Alt gorev bulunamadi", systemImage: "doc.text")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func scheduleAutosave(for subtask: TaskItem) {
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            commitChanges(for: subtask)
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func commitChanges(for subtask: TaskItem) {
        let plainText = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPlainText = plainText.isEmpty ? nil : attributedText.string
        let rtfData = attributedText.archivedData()
        let existingRTF = subtask.richTextRTFData

        guard subtask.markdownNote != normalizedPlainText || existingRTF != rtfData else { return }
        subtask.markdownNote = normalizedPlainText
        subtask.richTextRTFData = rtfData
        subtask.updatedAt = .now
        do {
            try modelContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    private func decodedAttributedText(from subtask: TaskItem) -> NSAttributedString {
        if let data = subtask.richTextRTFData,
           let richText = NSAttributedString.fromArchivedData(data) {
            return richText
        }
        return NSAttributedString(string: subtask.markdownNote ?? "")
    }
}

final class RichTextEditorContext: ObservableObject {
    weak var textView: NSTextView?

    func toggleBold() {
        applyFontTransform { font in
            NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        }
    }

    func toggleItalic() {
        applyFontTransform { font in
            NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
    }

    func toggleUnderline() {
        guard let textView, let storage = textView.textStorage else { return }
        let range = textView.selectedRange()
        if range.length == 0 {
            var typing = textView.typingAttributes
            let current = typing[.underlineStyle] as? Int ?? 0
            typing[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes = typing
            return
        }
        let safeLocation = min(max(0, range.location), max(0, storage.length - 1))
        let current = storage.attribute(.underlineStyle, at: safeLocation, effectiveRange: nil) as? Int ?? 0
        let newValue = current == 0 ? NSUnderlineStyle.single.rawValue : 0
        storage.addAttribute(.underlineStyle, value: newValue, range: range)
    }

    func applyHeading() {
        guard let textView else { return }
        let range = textView.selectedRange()
        let headingFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        if range.length == 0 {
            var typing = textView.typingAttributes
            typing[.font] = headingFont
            textView.typingAttributes = typing
            return
        }
        textView.textStorage?.addAttributes([.font: headingFont], range: range)
    }

    func insertBulletListItem() {
        textView?.insertText("• ", replacementRange: textView?.selectedRange() ?? NSRange(location: 0, length: 0))
    }

    func insertNumberedListItem() {
        textView?.insertText("1. ", replacementRange: textView?.selectedRange() ?? NSRange(location: 0, length: 0))
    }

    func insertLinkTemplate() {
        textView?.insertText("https://", replacementRange: textView?.selectedRange() ?? NSRange(location: 0, length: 0))
    }

    private func applyFontTransform(_ transform: (NSFont) -> NSFont) {
        guard let textView, let storage = textView.textStorage else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else {
            var typing = textView.typingAttributes
            let currentFont = (typing[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 15)
            typing[.font] = transform(currentFont)
            textView.typingAttributes = typing
            return
        }
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: 15)
            storage.addAttribute(.font, value: transform(currentFont), range: subrange)
        }
    }
}

private struct RichTextEditorRepresentable: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    typealias Coordinator = CoordinatorImpl

    @Binding var attributedText: NSAttributedString
    @ObservedObject var context: RichTextEditorContext
    let style: EditorReadabilityConfig
    var onTextChange: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.importsGraphics = true
        textView.usesFontPanel = true
        textView.usesInspectorBar = true
        textView.allowsImageEditing = true
        textView.drawsBackground = true
        textView.backgroundColor = style.background
        textView.textColor = style.text
        textView.insertionPointColor = style.text
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.defaultParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 3
            return style
        }()
        textView.typingAttributes = defaultTypingAttributes(from: textView.typingAttributes)
        textView.delegate = context.coordinator
        textView.textStorage?.setAttributedString(attributedText)
        textView.textStorage?.delegate = context.coordinator

        self.context.textView = textView
        context.coordinator.textView = textView
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }
        textView.backgroundColor = style.background
        textView.textColor = style.text
        textView.insertionPointColor = style.text
        textView.typingAttributes = defaultTypingAttributes(from: textView.typingAttributes)
        textView.textStorage?.delegate = context.coordinator
        self.context.textView = textView
        context.coordinator.textView = textView
    }

    func makeCoordinator() -> CoordinatorImpl {
        CoordinatorImpl(parent: self)
    }

    final class CoordinatorImpl: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: RichTextEditorRepresentable
        weak var textView: NSTextView?

        init(parent: RichTextEditorRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            syncAttributedTextFromEditor()
        }

        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            guard editedMask.contains(.editedAttributes) else { return }
            syncAttributedTextFromEditor()
        }

        private func syncAttributedTextFromEditor() {
            guard let textView else { return }
            parent.attributedText = textView.attributedString()
            parent.onTextChange()
        }
    }

    private func defaultTypingAttributes(from current: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var updated = current
        if updated[.font] == nil {
            updated[.font] = NSFont.systemFont(ofSize: style.fontSize)
        }
        updated[.foregroundColor] = style.text
        return updated
    }
}

private extension NSAttributedString {
    func archivedData() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    static func fromArchivedData(_ data: Data) -> NSAttributedString? {
        // Use top-level unarchive to preserve richer AppKit attachment payloads
        // (equations/LaTeX, file wrappers, etc.) created by NSTextView.
        return (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? NSAttributedString
    }
}
