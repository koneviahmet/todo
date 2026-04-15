import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit
import Foundation

struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \TaskCategory.createdAt, order: .forward) private var categories: [TaskCategory]
    @State private var taskInput: String = ""
    @State private var taskSearchText: String = ""
    @State private var isSearchMode: Bool = false
    @FocusState private var isTaskInputFocused: Bool
    private let parser = NaturalLanguageTaskParser()

    private var pendingTasks: [TaskItem] {
        tasks.filter {
            !$0.isCompleted &&
            $0.isRootTask &&
            $0.category?.id == appState.selectedCategoryID
        }
    }

    private var filteredPendingTasks: [TaskItem] {
        let keyword = taskSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return pendingTasks }
        return pendingTasks.filter { task in
            task.title.localizedCaseInsensitiveContains(keyword) ||
            (task.linkTitle?.localizedCaseInsensitiveContains(keyword) ?? false) ||
            (task.linkHost?.localizedCaseInsensitiveContains(keyword) ?? false)
        }
    }

    private var selectedCategory: TaskCategory? {
        categories.first(where: { $0.id == appState.selectedCategoryID })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                topBar

                VStack(spacing: 10) {
                    categorySelectorRow
                    inputRow
                    if appState.isFocusActive {
                        focusPanel
                    }
                    if let parseNotice = appState.parseNotice {
                        Text(parseNotice)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    pendingList
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 2)
            }
            .padding(12)
            .onAppear {
                ensureDefaultCategorySelection()
                appState.refreshPendingCount(using: modelContext)
                ReminderScheduler.shared.requestAuthorizationIfNeeded()
            }
            .onChange(of: tasks.count) { _, _ in
                appState.refreshPendingCount(using: modelContext)
            }
            .onChange(of: categories.count) { _, _ in
                ensureDefaultCategorySelection()
                appState.refreshPendingCount(using: modelContext)
            }
            .onDrop(of: [UTType.text, UTType.url], isTargeted: $appState.dropOverlayVisible) { providers in
                handleDrop(providers: providers)
            }
            if appState.dropOverlayVisible {
                dropOverlay
            }

            if let toast = appState.clipboardToast {
                clipboardToast(toast)
            }
        }
    }

    private var categorySelectorRow: some View {
        HStack(spacing: 8) {
            Picker("", selection: $appState.selectedCategoryID) {
                if categories.isEmpty {
                    Text("Kategori yok").tag(Optional<UUID>.none)
                } else {
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Kategoriler") {
                openWindow(id: "category-manager-window")
                activateAppAndWindow(title: "Kategori Yonetimi")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Text("todo")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            topBarIconButton(systemName: "checkmark.circle") {
                openWindow(id: "completed-window")
                activateAppAndWindow(title: "Tamamlananlar")
            }

            topBarIconButton(systemName: "gearshape.fill") {
                openSettingsWindow()
            }

            topBarIconButton(systemName: "power", role: .destructive) {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
        )
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField(
                isSearchMode ? "Gorev ara..." : "Yeni gorev ekle...",
                text: isSearchMode ? $taskSearchText : $taskInput
            )
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .focused($isTaskInputFocused)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor).opacity(0.32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isTaskInputFocused ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                .onSubmit {
                    guard !isSearchMode else { return }
                    addTaskFromInput()
                }

            if isSearchMode {
                if !taskSearchText.isEmpty {
                    Button {
                        taskSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isSearchMode = false
                    taskSearchText = ""
                    isTaskInputFocused = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            } else {
                Button("Ekle", action: addTaskFromInput)
                    .buttonStyle(.bordered)
                    .disabled(taskInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCategory == nil)
                    .controlSize(.regular)

                Button {
                    isSearchMode = true
                    isTaskInputFocused = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            Text("\(pendingTasks.count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.08), in: Capsule(style: .continuous))
        }
    }

    private var pendingList: some View {
        List {
            ForEach(filteredPendingTasks) { task in
                TaskRowView(
                    item: task,
                    onToggle: { toggleCompletion(task) },
                    onDelete: { openDeleteConfirmation(for: task) },
                    onFocus: { startFocus(for: task) },
                    onSetTimer: { openTaskTimer(for: task) },
                    onDetail: { openDetail(for: task) },
                    categoryOptions: categories,
                    onMoveToCategory: { category in
                        moveTask(task, to: category)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }

            if filteredPendingTasks.isEmpty {
                ContentUnavailableView(
                    selectedCategory == nil ? "Kategori sec" : (taskSearchText.isEmpty ? "Gorev yok" : "Arama sonucu yok"),
                    systemImage: "checkmark.circle",
                    description: Text(
                        selectedCategory == nil
                        ? "Once bir kategori olustur ve sec."
                        : (taskSearchText.isEmpty ? "Yeni bir gorev ekleyerek basla." : "\"\(taskSearchText)\" icin eslesen gorev bulunamadi.")
                    )
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var focusPanel: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.focusSessionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(appState.focusTaskTitle ?? "Gorev") • \(appState.focusTimeText)")
                    .font(.caption.bold())
                    .lineLimit(1)
            }
            Spacer()
            Button(appState.focusIsRunning ? "Duraklat" : "Devam") {
                appState.toggleFocusRunning()
            }
            .controlSize(.small)
            Button("Bitir") {
                appState.stopFocus()
            }
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.ultraThinMaterial)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.title2)
                    Text("Buraya Birak")
                        .font(.headline)
                    Text("Metin veya URL birakarak gorev olustur")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            )
            .padding(12)
    }

    private func clipboardToast(_ toast: ClipboardToast) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Panodan alindi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(toast.text)
                    .lineLimit(1)
            }
            Spacer()
            Button("Kaydet") {
                addTask(title: toast.text, sourceType: "clipboard")
                appState.clipboardToast = nil
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if appState.clipboardToast?.id == toast.id {
                    appState.clipboardToast = nil
                }
            }
        }
    }

    private func topBarIconButton(systemName: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red.opacity(0.9) : Color.secondary)
    }

    private func addTaskFromInput() {
        let trimmed = taskInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let parsed = parser.parse(trimmed)
        let finalTitle = parsed.title.isEmpty ? trimmed : parsed.title
        addTask(title: finalTitle, sourceType: "manual", dueDate: parsed.dueDate)
        switch parsed.parseStatus {
        case .parsed:
            appState.parseNotice = "Tarih/saat algilandi, hatirlatici planlandi."
        case .ambiguous:
            appState.parseNotice = "Saat ifadesi belirsiz; gorev tarih olmadan kaydedildi."
        case .notDetected:
            appState.parseNotice = nil
        }
        taskInput = ""
    }

    private func addTask(title: String, sourceType: String?, dueDate: Date? = nil) {
        guard let selectedCategory else { return }
        let detectedURL = detectedLinkURL(from: title, sourceType: sourceType)
        let isURLTask = detectedURL != nil
        let task = TaskItem(
            title: title,
            dueDate: dueDate,
            sourceType: isURLTask ? "url" : sourceType,
            linkURLString: detectedURL?.absoluteString,
            linkHost: detectedURL.flatMap { normalizedHost(from: $0) },
            category: selectedCategory
        )
        modelContext.insert(task)
        saveContext()
        if let detectedURL {
            fetchLinkMetadataIfNeeded(for: task, url: detectedURL)
        }
        ReminderScheduler.shared.scheduleReminder(for: task)
    }

    private func toggleCompletion(_ task: TaskItem) {
        task.setCompletionRecursively(!task.isCompleted)
        saveContext()
    }

    private func deleteTask(_ task: TaskItem) {
        deleteRecursively(task)
        saveContext()
    }

    private func moveTask(_ task: TaskItem, to category: TaskCategory) {
        guard task.category?.id != category.id else { return }
        task.assignCategoryRecursively(category)
        saveContext()
    }

    private func openDeleteConfirmation(for task: TaskItem) {
        if let menuWindow = NSApp.keyWindow {
            menuWindow.close()
        }
        openWindow(id: "delete-task-window", value: task.id)
        positionDeleteWindowTopRight()
    }

    private func deleteRecursively(_ task: TaskItem) {
        for subtask in task.subtasks {
            deleteRecursively(subtask)
        }
        modelContext.delete(task)
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Save error: \(error)")
        }
        appState.refreshPendingCount(using: modelContext)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard selectedCategory != nil else { return false }
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    Task { @MainActor in
                        addTask(title: url.absoluteString, sourceType: "url")
                    }
                }
                return true
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                    if let text = item as? String {
                        Task { @MainActor in
                            addTask(title: text, sourceType: "text")
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private func startFocus(for task: TaskItem) {
        appState.startFocus(
            task: task,
            workMinutes: settings.pomodoroWorkMinutes,
            breakMinutes: settings.pomodoroBreakMinutes
        )
    }

    private func openSettingsWindow() {
        openWindow(id: "settings-window")
        activateAppAndWindow(title: "Ayarlar")
    }

    private func openTaskTimer(for task: TaskItem) {
        if let menuWindow = NSApp.keyWindow {
            menuWindow.close()
        }
        openWindow(id: "task-timer-window", value: task.id)
        activateAndPositionTimerWindow()
    }

    private func activateAndPositionTimerWindow() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.title.localizedCaseInsensitiveContains("Gorev Zamanlayici") }),
                  let screen = window.screen ?? NSScreen.main else { return }
            let visible = screen.visibleFrame
            let size = window.frame.size
            let x = visible.maxX - size.width - 14
            let y = visible.maxY - size.height - 8
            window.setFrameOrigin(NSPoint(x: x, y: y))
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.level = .normal
        }
    }

    private func openDetail(for task: TaskItem) {
        openWindow(value: task.id)
        activateAppAndWindow(title: "Gorev Detayi")
    }

    private func activateAppAndWindow(title: String) {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.title.localizedCaseInsensitiveContains(title) }) {
                window.level = .floating
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.level = .normal
            }
        }
    }

    private func positionDeleteWindowTopRight() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.title.localizedCaseInsensitiveContains("Gorevi Sil") }),
                  let screen = window.screen ?? NSScreen.main else { return }
            let targetSize = NSSize(width: 360, height: 180)
            let visible = screen.visibleFrame
            let x = visible.maxX - targetSize.width - 14
            let y = visible.maxY - targetSize.height - 8
            window.setContentSize(targetSize)
            window.setFrameOrigin(NSPoint(x: x, y: y))
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.level = .normal
        }
    }

    private func detectedLinkURL(from raw: String, sourceType: String?) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if sourceType == "url", let url = URL(string: trimmed), isWebURL(url) {
            return url
        }
        if let url = URL(string: trimmed), isWebURL(url) {
            return url
        }
        return nil
    }

    private func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func normalizedHost(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func fetchLinkMetadataIfNeeded(for task: TaskItem, url: URL) {
        guard task.linkTitle == nil || task.linkTitle?.isEmpty == true else { return }
        Task {
            let metadata = await LinkMetadataFetcher.shared.fetch(for: url)
            if let title = metadata.title, !title.isEmpty {
                task.linkTitle = title
                task.title = title
            }
            if let host = metadata.host, !host.isEmpty {
                task.linkHost = host
            }
            task.updatedAt = .now
            saveContext()
        }
    }

    private func ensureDefaultCategorySelection() {
        guard !categories.isEmpty else {
            let defaultCategory = TaskCategory(name: "Genel", includeInMenuCount: true)
            modelContext.insert(defaultCategory)
            do {
                try modelContext.save()
                appState.selectedCategoryID = defaultCategory.id
                appState.refreshPendingCount(using: modelContext)
            } catch {
                print("Save error: \(error)")
            }
            return
        }
        if appState.selectedCategoryID == nil || !categories.contains(where: { $0.id == appState.selectedCategoryID }) {
            appState.selectedCategoryID = categories.first?.id
        }
    }
}
