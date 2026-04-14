import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Menu Bar Gorunumu") {
                Picker("Stil", selection: $settings.stylePreset) {
                    ForEach(MenuBarStylePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                Text("Menu cubugu rozetinin renk ve cizgi stilini secersin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settings.stylePreset == .custom {
                    TextField("Arka plan HEX", text: $settings.customBackgroundHex)
                    Text("Arka plan rengi icin HEX kodu gir (ornek: #2563EB).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Yazi HEX", text: $settings.customTextHex)
                    Text("Yazi ve cerceve rengini bu HEX kodu belirler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Border kalinligi")
                        Slider(value: $settings.borderWidth, in: 0...4, step: 0.5)
                        Text(settings.borderWidth, format: .number.precision(.fractionLength(1)))
                            .monospacedDigit()
                    }
                    Text("Cerceve kalinligini kaydirarak canli olarak ayarlarsin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Yazi boyutu")
                        Slider(value: $settings.textSize, in: 7...14, step: 1)
                        Text(settings.textSize, format: .number.precision(.fractionLength(0)))
                            .monospacedDigit()
                    }
                    Text("Rozet icindeki sayi boyutunu belirler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Davranis") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Text("Uygulamayi bilgisayar acildiginda otomatik baslatir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Auto-Archive (24 saat)", isOn: $settings.autoArchiveEnabled)
                Text("24 saati gecen tamamlanmis gorevleri arsive tasir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Hizli gorev hotkey notu", text: $settings.hotkeyHint)
                Text("Kisayol bilgisini kendine not olarak saklarsin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Pomodoro") {
                Stepper("Odak suresi: \(settings.pomodoroWorkMinutes) dk", value: $settings.pomodoroWorkMinutes, in: 5...90, step: 5)
                Text("Bir odak turunun kac dakika surecegini belirler.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper("Mola suresi: \(settings.pomodoroBreakMinutes) dk", value: $settings.pomodoroBreakMinutes, in: 1...30, step: 1)
                Text("Her odak turundan sonraki mola suresini ayarlar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let launchError = settings.lastLaunchAtLoginError {
                Section("Uyari") {
                    Text("Launch at Login guncellenemedi: \(launchError)")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let settingsWindow = NSApp.windows.first(where: { $0.title.localizedCaseInsensitiveContains("Ayarlar") }) {
                    settingsWindow.makeKeyAndOrderFront(nil)
                    settingsWindow.orderFrontRegardless()
                }
            }
        }
    }
}
