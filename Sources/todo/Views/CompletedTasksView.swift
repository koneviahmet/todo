import SwiftUI
import SwiftData
import AppKit

struct CompletedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted && $0.parentTask == nil }, sort: \TaskItem.completedAt, order: .reverse)
    private var completedTasks: [TaskItem]
    @Query(sort: \TaskCategory.createdAt, order: .forward)
    private var categories: [TaskCategory]
    @State private var selectedTab: CategoryTab = .all
    @State private var isSelectionMode: Bool = false
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var searchText: String = ""

    private var baseVisibleCompletedTasks: [TaskItem] {
        guard settings.autoArchiveEnabled else { return completedTasks }
        let threshold = Date().addingTimeInterval(-24 * 60 * 60)
        return completedTasks.filter { ($0.completedAt ?? .distantPast) >= threshold }
    }

    private var hasUncategorizedCompletedTask: Bool {
        baseVisibleCompletedTasks.contains { $0.category == nil }
    }

    private var selectedCategoryLabel: String {
        switch selectedTab {
        case .all:
            return "Tumu"
        case .categorized(let id):
            return categories.first(where: { $0.id == id })?.name ?? "Kategori"
        case .uncategorized:
            return "Kategorisiz"
        }
    }

    private var visibleCompletedTasks: [TaskItem] {
        switch selectedTab {
        case .all:
            return baseVisibleCompletedTasks
        case .categorized(let id):
            return baseVisibleCompletedTasks.filter { $0.category?.id == id }
        case .uncategorized:
            return baseVisibleCompletedTasks.filter { $0.category == nil }
        }
    }

    private var filteredCompletedTasks: [TaskItem] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return visibleCompletedTasks }
        return visibleCompletedTasks.filter { task in
            task.title.localizedCaseInsensitiveContains(keyword) ||
            (task.linkTitle?.localizedCaseInsensitiveContains(keyword) ?? false) ||
            (task.linkHost?.localizedCaseInsensitiveContains(keyword) ?? false)
        }
    }

    private var selectionActionTitle: String {
        isSelectionMode ? "Kapat" : "Sec"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Tamamlananlar")
                    .font(.headline.weight(.semibold))
                Spacer()
                Text("\(filteredCompletedTasks.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.08), in: Capsule(style: .continuous))
                Button(selectionActionTitle) {
                    isSelectionMode.toggle()
                    if !isSelectionMode {
                        selectedTaskIDs.removeAll()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            categoryTabs
            searchField
            Text(selectedCategoryLabel)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if isSelectionMode && !filteredCompletedTasks.isEmpty {
                HStack(spacing: 8) {
                    Text("\(selectedTaskIDs.count) secili")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button("Tumunu Sec") {
                        selectedTaskIDs = Set(filteredCompletedTasks.map(\.id))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(filteredCompletedTasks.isEmpty || selectedTaskIDs.count == filteredCompletedTasks.count)
                    Button("Temizle") {
                        selectedTaskIDs.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(selectedTaskIDs.isEmpty)
                    Button("Kaldir", role: .destructive) {
                        deleteSelectedTasks()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(selectedTaskIDs.isEmpty)
                    Spacer()
                }
            }

            List {
                ForEach(filteredCompletedTasks) { task in
                    TaskRowView(
                        item: task,
                        onToggle: { uncomplete(task) },
                        onDelete: { delete(task) },
                        onDetail: { openDetail(for: task) },
                        categoryOptions: categories,
                        onMoveToCategory: { category in
                            moveTask(task, to: category)
                        },
                        isSelectionMode: isSelectionMode,
                        isSelected: selectedTaskIDs.contains(task.id),
                        onSelectionToggle: {
                            toggleSelection(for: task)
                        }
                    )
                    .listRowSeparator(.hidden)
                }
                if filteredCompletedTasks.isEmpty {
                    ContentUnavailableView(searchText.isEmpty ? "Kayit yok" : "Arama sonucu yok", systemImage: "tray")
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: ensureValidSelectedTab)
        .onChange(of: categories.map(\.id)) { _, newIDs in
            if case .categorized(let selectedID) = selectedTab, !newIDs.contains(selectedID) {
                selectedTab = .all
            }
        }
        .onChange(of: filteredCompletedTasks.map(\.id)) { _, filteredIDs in
            let filteredSet = Set(filteredIDs)
            selectedTaskIDs = selectedTaskIDs.intersection(filteredSet)
            if filteredSet.isEmpty {
                isSelectionMode = false
            }
        }
        .onChange(of: hasUncategorizedCompletedTask) { _, _ in
            ensureValidSelectedTab()
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryTabButton(title: "Tumu", tab: .all)
                ForEach(categories) { category in
                    categoryTabButton(title: category.name, tab: .categorized(category.id))
                }
                if hasUncategorizedCompletedTask {
                    categoryTabButton(title: "Kategorisiz", tab: .uncategorized)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Tamamlanan ara...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func categoryTabButton(title: String, tab: CategoryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.24) : Color.primary.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private func ensureValidSelectedTab() {
        if case .uncategorized = selectedTab, !hasUncategorizedCompletedTask {
            selectedTab = .all
        }
    }

    private func uncomplete(_ task: TaskItem) {
        task.setCompletionRecursively(false)
        selectedTaskIDs.remove(task.id)
        saveContext()
    }

    private func delete(_ task: TaskItem) {
        selectedTaskIDs.remove(task.id)
        deleteRecursively(task)
        saveContext()
    }

    private func moveTask(_ task: TaskItem, to category: TaskCategory) {
        guard task.category?.id != category.id else { return }
        task.assignCategoryRecursively(category)
        selectedTaskIDs.remove(task.id)
        saveContext()
    }

    private func toggleSelection(for task: TaskItem) {
        guard isSelectionMode else { return }
        if selectedTaskIDs.contains(task.id) {
            selectedTaskIDs.remove(task.id)
        } else {
            selectedTaskIDs.insert(task.id)
        }
    }

    private func deleteSelectedTasks() {
        let tasksToDelete = filteredCompletedTasks.filter { selectedTaskIDs.contains($0.id) }
        guard !tasksToDelete.isEmpty else { return }
        for task in tasksToDelete {
            deleteRecursively(task)
        }
        selectedTaskIDs.removeAll()
        isSelectionMode = false
        saveContext()
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

    private func openDetail(for task: TaskItem) {
        openWindow(value: task.id)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private enum CategoryTab: Equatable {
    case all
    case categorized(UUID)
    case uncategorized
}
