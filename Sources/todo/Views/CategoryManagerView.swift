import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @Query(sort: \TaskCategory.createdAt, order: .forward) private var categories: [TaskCategory]
    @Query private var tasks: [TaskItem]
    @State private var newCategoryName: String = ""
    @State private var pendingDeleteCategory: TaskCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori Yonetimi")
                .font(.title3.bold())

            HStack(spacing: 8) {
                TextField("Yeni kategori adi", text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(createCategory)
                Button("Ekle", action: createCategory)
                    .buttonStyle(.borderedProminent)
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            List {
                ForEach(categories) { category in
                    CategoryRow(
                        category: category,
                        onRename: { newName in
                            category.name = newName
                            category.updatedAt = .now
                            save()
                        },
                        onCounterToggle: { includeInCount in
                            category.includeInMenuCount = includeInCount
                            category.updatedAt = .now
                            save()
                        },
                        onDelete: {
                            pendingDeleteCategory = category
                        }
                    )
                }
            }
            .listStyle(.plain)
            .confirmationDialog(
                "Kategori silinsin mi?",
                isPresented: Binding(
                    get: { pendingDeleteCategory != nil },
                    set: { newValue in
                        if !newValue { pendingDeleteCategory = nil }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Sil", role: .destructive) {
                    if let pendingDeleteCategory {
                        deleteCategory(pendingDeleteCategory)
                    }
                    pendingDeleteCategory = nil
                }
                Button("Vazgec", role: .cancel) {
                    pendingDeleteCategory = nil
                }
            } message: {
                if let pendingDeleteCategory {
                    Text("\"\(pendingDeleteCategory.name)\" altindaki gorevler Genel kategorisine tasinacak.")
                }
            }

            HStack {
                Spacer()
                Button("Kapat") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 380)
    }

    private func createCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !categories.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        let category = TaskCategory(name: trimmed)
        modelContext.insert(category)
        newCategoryName = ""
        save()
        appState.selectedCategoryID = category.id
    }

    private func deleteCategory(_ category: TaskCategory) {
        let fallbackCategory = fallbackCategory(excluding: category)
        for task in tasks where task.category?.id == category.id {
            task.category = fallbackCategory
            task.updatedAt = .now
        }
        let deletingSelected = appState.selectedCategoryID == category.id
        modelContext.delete(category)
        save()
        if deletingSelected {
            appState.selectedCategoryID = fallbackCategory?.id
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

    private func fallbackCategory(excluding removed: TaskCategory) -> TaskCategory? {
        if let existing = categories.first(where: { $0.id != removed.id }) {
            return existing
        }
        let general = TaskCategory(name: "Genel", includeInMenuCount: true)
        modelContext.insert(general)
        return general
    }
}

private struct CategoryRow: View {
    let category: TaskCategory
    let onRename: (String) -> Void
    let onCounterToggle: (Bool) -> Void
    let onDelete: () -> Void
    @State private var draftName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Kategori adi", text: $draftName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(renameIfNeeded)
                Button {
                    renameIfNeeded()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            Toggle("Menu bardaki sayaca dahil et", isOn: Binding(
                get: { category.includeInMenuCount },
                set: { newValue in
                    onCounterToggle(newValue)
                }
            ))
            .toggleStyle(.switch)
            .font(.caption)
        }
        .padding(.vertical, 4)
        .onAppear {
            draftName = category.name
        }
        .onChange(of: category.name) { _, newValue in
            draftName = newValue
        }
    }

    private func renameIfNeeded() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            draftName = category.name
            return
        }
        onRename(trimmed)
    }
}
