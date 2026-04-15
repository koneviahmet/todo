import SwiftUI
import SwiftData
import AppKit

@main
struct TodoApp: App {
    @StateObject private var appState: AppState
    @StateObject private var settings: AppSettings
    @StateObject private var clipboardMonitor: ClipboardMonitor
    private let container: ModelContainer
    private let clipboardQuickAddWindow: ClipboardQuickAddWindowController

    init() {
        let appState = AppState()
        let settings = AppSettings()
        let clipboardMonitor = ClipboardMonitor()
        let clipboardQuickAddWindow = ClipboardQuickAddWindowController()

        _appState = StateObject(wrappedValue: appState)
        _settings = StateObject(wrappedValue: settings)
        _clipboardMonitor = StateObject(wrappedValue: clipboardMonitor)
        self.clipboardQuickAddWindow = clipboardQuickAddWindow

        do {
            let schema = Schema([TaskItem.self, TaskCategory.self])
            let config = ModelConfiguration(
                "TodoModel",
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            Task { @MainActor in
                appState.refreshPendingCount(using: container.mainContext)
            }

            clipboardMonitor.startMonitoring { copiedText in
                appState.handleClipboardCapture(copiedText)
                let categoryDescriptor = FetchDescriptor<TaskCategory>(
                    sortBy: [SortDescriptor(\TaskCategory.createdAt)]
                )
                let categories = (try? container.mainContext.fetch(categoryDescriptor)) ?? []
                clipboardQuickAddWindow.present(
                    text: copiedText,
                    categories: categories.map { (id: $0.id, name: $0.name) },
                    selectedCategoryID: appState.selectedCategoryID
                ) { selectedCategoryID in
                    appState.selectedCategoryID = selectedCategoryID
                    let trimmed = copiedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let detectedURL = URL(string: trimmed)
                    let isWebURL = {
                        guard let detectedURL, let scheme = detectedURL.scheme?.lowercased() else { return false }
                        return scheme == "http" || scheme == "https"
                    }()
                    let selectedCategory = categories.first(where: { $0.id == selectedCategoryID })
                    let task = TaskItem(
                        title: copiedText,
                        sourceType: isWebURL ? "url" : "clipboard",
                        linkURLString: isWebURL ? detectedURL?.absoluteString : nil,
                        linkHost: isWebURL ? detectedURL?.host?.lowercased().replacingOccurrences(of: "www.", with: "") : nil,
                        category: selectedCategory
                    )
                    container.mainContext.insert(task)
                    do {
                        try container.mainContext.save()
                        appState.refreshPendingCount(using: container.mainContext)
                    } catch {
                        print("Save error: \(error)")
                    }

                    if isWebURL, let detectedURL {
                        Task { @MainActor in
                            let metadata = await LinkMetadataFetcher.shared.fetch(for: detectedURL)
                            if let title = metadata.title, !title.isEmpty {
                                task.linkTitle = title
                                task.title = title
                            }
                            if let host = metadata.host, !host.isEmpty {
                                task.linkHost = host
                            }
                            task.updatedAt = .now
                            do {
                                try container.mainContext.save()
                                appState.refreshPendingCount(using: container.mainContext)
                            } catch {
                                print("Save error: \(error)")
                            }
                        }
                    }
                }
            }
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainMenuView()
                .modelContainer(container)
                .environmentObject(appState)
                .environmentObject(settings)
                .environmentObject(clipboardMonitor)
                .frame(width: 360, height: 500)
        } label: {
            MenuBarCounterIcon(appState: appState, settings: settings)
                .id(settings.styleRenderID)
                .contextMenu {
                    Button("Uygulamayi Kapat") {
                        NSApp.terminate(nil)
                    }
                }
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Tamamlananlar", id: "completed-window") {
            CompletedTasksView()
                .modelContainer(container)
                .environmentObject(appState)
                .environmentObject(settings)
                .frame(minWidth: 260, idealWidth: 260, minHeight: 420, idealHeight: 420)
        }

        WindowGroup("Ayarlar", id: "settings-window") {
            SettingsView()
                .environmentObject(settings)
                .frame(minWidth: 480, minHeight: 420)
        }

        WindowGroup("Kategori Yonetimi", id: "category-manager-window") {
            CategoryManagerView()
                .modelContainer(container)
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 380)
        }

        WindowGroup("Gorev Detayi", id: "task-detail-window", for: UUID.self) { $taskID in
            if let taskID {
                TaskDetailSceneView(taskID: taskID)
                    .modelContainer(container)
                    .environmentObject(appState)
                    .frame(minWidth: 520, minHeight: 460)
            } else {
                ContentUnavailableView("Gorev secilmedi", systemImage: "list.bullet")
                    .frame(minWidth: 420, minHeight: 300)
            }
        }

        WindowGroup("Alt Gorev Markdown", id: "subtask-markdown-window", for: UUID.self) { $subtaskID in
            if let subtaskID {
                SubtaskMarkdownSceneView(subtaskID: subtaskID)
                    .modelContainer(container)
                    .environmentObject(settings)
                    .frame(minWidth: 820, minHeight: 520)
            } else {
                ContentUnavailableView("Alt gorev secilmedi", systemImage: "doc.text")
                    .frame(minWidth: 420, minHeight: 300)
            }
        }

        WindowGroup("Gorev Zamanlayici", id: "task-timer-window", for: UUID.self) { $taskID in
            if let taskID {
                TaskTimerSceneView(taskID: taskID)
                    .modelContainer(container)
                    .environmentObject(appState)
            } else {
                ContentUnavailableView("Gorev secilmedi", systemImage: "timer")
                    .padding(16)
            }
        }
        .windowResizability(.contentSize)

        WindowGroup("Gorevi Sil", id: "delete-task-window", for: UUID.self) { $taskID in
            if let taskID {
                DeleteTaskSceneView(taskID: taskID)
                    .modelContainer(container)
                    .environmentObject(appState)
            } else {
                ContentUnavailableView("Gorev secilmedi", systemImage: "trash")
                    .padding(16)
            }
        }
        .windowResizability(.contentSize)
    }

}
