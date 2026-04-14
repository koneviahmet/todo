import SwiftUI
import AppKit

struct MenuBarCounterIcon: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings: AppSettings

    var body: some View {
        let style = settings.currentStyle
        Image(nsImage: renderedIcon(style: style))
            .renderingMode(.original)
        .accessibilityLabel(appState.isFocusActive ? "Odak suresi: \(appState.focusTimeText)" : "Bekleyen gorev: \(appState.pendingCount)")
    }

    private func displayText(for _: MenuBarStylePreset) -> String {
        if appState.isFocusActive {
            return appState.focusTimeText
        }

        let count = min(appState.pendingCount, 99)
        return "\(count)"
    }

    private func renderedIcon(style: MenuBarStyle) -> NSImage {
        let isFocus = appState.isFocusActive
        let text = displayText(for: settings.stylePreset)
        let activeStyle = isFocus ? pomodoroStyle() : style
        let fontSize = CGFloat(isFocus ? max(10, activeStyle.textSize) : activeStyle.textSize)
        let font = resolvedFont(for: activeStyle, size: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(activeStyle.textColor)
        ]
        let textSize = text.size(withAttributes: attrs)
        let horizontalPadding: CGFloat = isFocus ? 10 : 0
        let width = isFocus ? max(34, ceil(textSize.width + horizontalPadding * 2)) : 23
        let height: CGFloat = isFocus ? 22 : 23
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        let inset = CGFloat(max(1, activeStyle.borderWidth / 2))
        let rect = NSRect(x: inset, y: inset, width: size.width - (inset * 2), height: size.height - (inset * 2))
        let path: NSBezierPath
        switch activeStyle.iconShape {
        case .circle:
            path = NSBezierPath(ovalIn: rect)
        case .roundedRect:
            path = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)
        case .capsule:
            path = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        }

        NSColor(activeStyle.backgroundColor).setFill()
        path.fill()
        NSColor(activeStyle.borderColor).setStroke()
        path.lineWidth = CGFloat(activeStyle.borderWidth)
        path.stroke()

        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attrs)
        image.isTemplate = false
        return image
    }

    private func pomodoroStyle() -> MenuBarStyle {
        MenuBarStyle(
            backgroundColor: Color(hex: "#B91C1C"),
            textColor: .white,
            borderColor: Color(hex: "#FCA5A5"),
            borderWidth: 1.4,
            iconShape: .capsule,
            textDesign: .monospaced,
            textSize: 12
        )
    }

    private func resolvedFont(for style: MenuBarStyle, size: CGFloat) -> NSFont {
        let fontName: String
        switch style.textDesign {
        case .rounded:
            fontName = "SFProRounded-Bold"
        case .monospaced:
            fontName = "SFMono-Bold"
        case .serif:
            fontName = "TimesNewRomanPS-BoldMT"
        default:
            fontName = "SFProDisplay-Bold"
        }
        return NSFont(name: fontName, size: size) ?? NSFont.boldSystemFont(ofSize: size)
    }
}
