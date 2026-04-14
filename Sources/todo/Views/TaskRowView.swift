import SwiftUI
import AppKit

struct TaskRowView: View {
    let item: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onFocus: (() -> Void)? = nil
    var onSetTimer: (() -> Void)? = nil
    var onDetail: (() -> Void)? = nil
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onSelectionToggle: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .secondary : .tertiary)
                    .font(.system(size: 16, weight: .regular))
            }
            .buttonStyle(.plain)

            if isSelectionMode {
                Button(action: {
                    onSelectionToggle?()
                }) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 15, weight: .regular))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let onDetail {
                    Button(action: onDetail) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .medium))
                            .strikethrough(item.isCompleted, color: .secondary)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .strikethrough(item.isCompleted, color: .secondary)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .lineLimit(1)
                }
                if let dueDate = item.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let linkHost = item.linkHost {
                    Text(linkHost.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let onSetTimer, !item.isCompleted {
                Button(action: onSetTimer) {
                    Image(systemName: "clock.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Sure belirle ve geri sayim baslat")
            }

            Menu {
                if let onFocus, !item.isCompleted {
                    Button("Odak Baslat", systemImage: "timer", action: onFocus)
                }

                if let onSetTimer, !item.isCompleted {
                    Button("Gorev zamanlayici", systemImage: "clock.badge.plus", action: onSetTimer)
                }

                if let onDetail {
                    Button("Detayi Ac", systemImage: "info.circle", action: onDetail)
                }

                if let linkURL = item.linkURL {
                    Button("Linki Ac", systemImage: "arrow.up.right.square") {
                        NSWorkspace.shared.open(linkURL)
                    }
                }

                Divider()

                Button("Sil", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Color.clear
                    .frame(width: 8, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .foregroundStyle(.tertiary)
            .help("Gorev islemleri")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
