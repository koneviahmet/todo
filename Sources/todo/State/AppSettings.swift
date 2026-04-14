import SwiftUI
import ServiceManagement
import AppKit

@MainActor
final class AppSettings: ObservableObject {
    @Published var stylePreset: MenuBarStylePreset {
        didSet { defaults.set(stylePreset.rawValue, forKey: Keys.stylePreset) }
    }
    @Published var customBackgroundHex: String {
        didSet { defaults.set(customBackgroundHex, forKey: Keys.customBackgroundHex) }
    }
    @Published var customTextHex: String {
        didSet { defaults.set(customTextHex, forKey: Keys.customTextHex) }
    }
    @Published var borderWidth: Double {
        didSet { defaults.set(borderWidth, forKey: Keys.borderWidth) }
    }
    @Published var textSize: Double {
        didSet { defaults.set(textSize, forKey: Keys.textSize) }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin()
        }
    }
    @Published var hotkeyHint: String {
        didSet { defaults.set(hotkeyHint, forKey: Keys.hotkeyHint) }
    }
    @Published var autoArchiveEnabled: Bool {
        didSet { defaults.set(autoArchiveEnabled, forKey: Keys.autoArchiveEnabled) }
    }
    @Published var pomodoroWorkMinutes: Int {
        didSet { defaults.set(pomodoroWorkMinutes, forKey: Keys.pomodoroWorkMinutes) }
    }
    @Published var pomodoroBreakMinutes: Int {
        didSet { defaults.set(pomodoroBreakMinutes, forKey: Keys.pomodoroBreakMinutes) }
    }
    @Published var editorStylePreset: EditorReadabilityStyle {
        didSet { defaults.set(editorStylePreset.rawValue, forKey: Keys.editorStylePreset) }
    }

    @Published var lastLaunchAtLoginError: String?

    private let defaults = UserDefaults.standard

    init() {
        stylePreset = MenuBarStylePreset(rawValue: defaults.string(forKey: Keys.stylePreset) ?? "") ?? .modernNeon
        customBackgroundHex = defaults.string(forKey: Keys.customBackgroundHex) ?? "#2563EB"
        customTextHex = defaults.string(forKey: Keys.customTextHex) ?? "#FFFFFF"
        borderWidth = defaults.object(forKey: Keys.borderWidth) as? Double ?? 1.5
        textSize = defaults.object(forKey: Keys.textSize) as? Double ?? 10
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        hotkeyHint = defaults.string(forKey: Keys.hotkeyHint) ?? "Cmd+Shift+T"
        autoArchiveEnabled = defaults.object(forKey: Keys.autoArchiveEnabled) as? Bool ?? true
        pomodoroWorkMinutes = defaults.object(forKey: Keys.pomodoroWorkMinutes) as? Int ?? 25
        pomodoroBreakMinutes = defaults.object(forKey: Keys.pomodoroBreakMinutes) as? Int ?? 5
        editorStylePreset = EditorReadabilityStyle(rawValue: defaults.string(forKey: Keys.editorStylePreset) ?? "") ?? .charcoal
        applyLaunchAtLogin()
    }

    var currentStyle: MenuBarStyle {
        stylePreset.style(
            backgroundHex: customBackgroundHex,
            textHex: customTextHex,
            borderWidth: borderWidth,
            textSize: textSize
        )
    }

    var styleRenderID: String {
        "\(stylePreset.rawValue)-\(customBackgroundHex)-\(customTextHex)-\(borderWidth)-\(textSize)"
    }

    private func applyLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                lastLaunchAtLoginError = nil
            } catch {
                lastLaunchAtLoginError = error.localizedDescription
            }
        }
    }

    private enum Keys {
        static let stylePreset = "stylePreset"
        static let customBackgroundHex = "customBackgroundHex"
        static let customTextHex = "customTextHex"
        static let borderWidth = "borderWidth"
        static let textSize = "textSize"
        static let launchAtLogin = "launchAtLogin"
        static let hotkeyHint = "hotkeyHint"
        static let autoArchiveEnabled = "autoArchiveEnabled"
        static let pomodoroWorkMinutes = "pomodoroWorkMinutes"
        static let pomodoroBreakMinutes = "pomodoroBreakMinutes"
        static let editorStylePreset = "editorStylePreset"
    }
}

enum EditorReadabilityStyle: String, CaseIterable, Identifiable {
    case charcoal = "Charcoal"
    case midnightBlue = "Midnight Blue"
    case graphite = "Graphite"
    case evergreen = "Evergreen"
    case plum = "Plum"
    case sepia = "Sepia"
    case paper = "Paper"
    case highContrast = "High Contrast"
    case ocean = "Ocean"
    case terminal = "Terminal"

    var id: String { rawValue }

    var config: EditorReadabilityConfig {
        switch self {
        case .charcoal:
            return .init(background: NSColor(calibratedWhite: 0.1, alpha: 1), text: .white, fontSize: 15)
        case .midnightBlue:
            return .init(background: NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.2, alpha: 1), text: NSColor(calibratedRed: 0.87, green: 0.91, blue: 1, alpha: 1), fontSize: 15)
        case .graphite:
            return .init(background: NSColor(calibratedWhite: 0.16, alpha: 1), text: NSColor(calibratedWhite: 0.95, alpha: 1), fontSize: 16)
        case .evergreen:
            return .init(background: NSColor(calibratedRed: 0.06, green: 0.14, blue: 0.1, alpha: 1), text: NSColor(calibratedRed: 0.82, green: 0.95, blue: 0.88, alpha: 1), fontSize: 15)
        case .plum:
            return .init(background: NSColor(calibratedRed: 0.17, green: 0.1, blue: 0.2, alpha: 1), text: NSColor(calibratedRed: 0.97, green: 0.9, blue: 1, alpha: 1), fontSize: 15)
        case .sepia:
            return .init(background: NSColor(calibratedRed: 0.2, green: 0.16, blue: 0.11, alpha: 1), text: NSColor(calibratedRed: 0.96, green: 0.89, blue: 0.77, alpha: 1), fontSize: 16)
        case .paper:
            return .init(background: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1), text: NSColor(calibratedWhite: 0.1, alpha: 1), fontSize: 16)
        case .highContrast:
            return .init(background: .black, text: .white, fontSize: 17)
        case .ocean:
            return .init(background: NSColor(calibratedRed: 0.03, green: 0.18, blue: 0.22, alpha: 1), text: NSColor(calibratedRed: 0.79, green: 0.95, blue: 0.98, alpha: 1), fontSize: 15)
        case .terminal:
            return .init(background: NSColor(calibratedRed: 0.02, green: 0.07, blue: 0.02, alpha: 1), text: NSColor(calibratedRed: 0.45, green: 1, blue: 0.42, alpha: 1), fontSize: 15)
        }
    }
}

struct EditorReadabilityConfig {
    let background: NSColor
    let text: NSColor
    let fontSize: CGFloat
}

enum MenuBarStylePreset: String, CaseIterable, Identifiable {
    case modernNeon = "Modern Neon"
    case classicMono = "Classic Mono"
    case pastelSoft = "Pastel Soft"
    case sunsetGlow = "Sunset Glow"
    case oceanDeep = "Ocean Deep"
    case forestMint = "Forest Mint"
    case lavenderDream = "Lavender Dream"
    case roseGold = "Rose Gold"
    case cyberLime = "Cyber Lime"
    case midnightAmber = "Midnight Amber"
    case arcticFrost = "Arctic Frost"
    case transparentMinimal = "Transparent Minimal"
    case transparentSoft = "Transparent Soft"
    case custom = "Custom"

    var id: String { rawValue }

    func style(backgroundHex: String, textHex: String, borderWidth: Double, textSize: Double) -> MenuBarStyle {
        switch self {
        case .modernNeon:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#2563EB"),
                textColor: .white,
                borderColor: Color(hex: "#7DD3FC"),
                borderWidth: 1.5,
                iconShape: .circle,
                textDesign: .rounded,
                textSize: 10
            )
        case .classicMono:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#111827"),
                textColor: .white,
                borderColor: Color(hex: "#6B7280"),
                borderWidth: 1.0,
                iconShape: .roundedRect,
                textDesign: .monospaced,
                textSize: 10
            )
        case .pastelSoft:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#BFDBFE"),
                textColor: Color(hex: "#1E3A8A"),
                borderColor: Color(hex: "#93C5FD"),
                borderWidth: 1.2,
                iconShape: .capsule,
                textDesign: .serif,
                textSize: 10
            )
        case .sunsetGlow:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#F97316"),
                textColor: .white,
                borderColor: Color(hex: "#FDBA74"),
                borderWidth: 1.6,
                iconShape: .roundedRect,
                textDesign: .rounded,
                textSize: 10
            )
        case .oceanDeep:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#0C4A6E"),
                textColor: Color(hex: "#E0F2FE"),
                borderColor: Color(hex: "#38BDF8"),
                borderWidth: 1.4,
                iconShape: .circle,
                textDesign: .rounded,
                textSize: 10
            )
        case .forestMint:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#14532D"),
                textColor: Color(hex: "#DCFCE7"),
                borderColor: Color(hex: "#4ADE80"),
                borderWidth: 1.4,
                iconShape: .capsule,
                textDesign: .rounded,
                textSize: 10
            )
        case .lavenderDream:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#6D28D9"),
                textColor: Color(hex: "#F5F3FF"),
                borderColor: Color(hex: "#C4B5FD"),
                borderWidth: 1.3,
                iconShape: .roundedRect,
                textDesign: .rounded,
                textSize: 10
            )
        case .roseGold:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#BE185D"),
                textColor: Color(hex: "#FFE4E6"),
                borderColor: Color(hex: "#FDA4AF"),
                borderWidth: 1.3,
                iconShape: .circle,
                textDesign: .rounded,
                textSize: 10
            )
        case .cyberLime:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#3F6212"),
                textColor: Color(hex: "#ECFCCB"),
                borderColor: Color(hex: "#A3E635"),
                borderWidth: 1.5,
                iconShape: .roundedRect,
                textDesign: .monospaced,
                textSize: 10
            )
        case .midnightAmber:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#1F2937"),
                textColor: Color(hex: "#FEF3C7"),
                borderColor: Color(hex: "#F59E0B"),
                borderWidth: 1.4,
                iconShape: .capsule,
                textDesign: .rounded,
                textSize: 10
            )
        case .arcticFrost:
            return MenuBarStyle(
                backgroundColor: Color(hex: "#E0F2FE"),
                textColor: Color(hex: "#0C4A6E"),
                borderColor: Color(hex: "#7DD3FC"),
                borderWidth: 1.2,
                iconShape: .circle,
                textDesign: .serif,
                textSize: 10
            )
        case .transparentMinimal:
            return MenuBarStyle(
                backgroundColor: .clear,
                textColor: .white,
                borderColor: .clear,
                borderWidth: 0,
                iconShape: .roundedRect,
                textDesign: .rounded,
                textSize: 10
            )
        case .transparentSoft:
            return MenuBarStyle(
                backgroundColor: Color.white.opacity(0.12),
                textColor: .white,
                borderColor: Color.white.opacity(0.22),
                borderWidth: 1.0,
                iconShape: .capsule,
                textDesign: .rounded,
                textSize: 10
            )
        case .custom:
            return MenuBarStyle(
                backgroundColor: Color(hex: backgroundHex),
                textColor: Color(hex: textHex),
                borderColor: Color(hex: textHex),
                borderWidth: borderWidth,
                iconShape: .roundedRect,
                textDesign: .rounded,
                textSize: textSize
            )
        }
    }
}

enum MenuBarIconShape {
    case circle
    case roundedRect
    case capsule
}

struct MenuBarStyle {
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let borderWidth: Double
    let iconShape: MenuBarIconShape
    let textDesign: Font.Design
    let textSize: Double
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        if cleaned.count == 6 {
            (r, g, b) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        } else {
            (r, g, b) = (37, 99, 235)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
