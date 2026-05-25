import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var dataStore = DataStore.shared

    var body: some View {
        Form {
            Section {
                Picker("Window Mode", selection: $dataStore.settings.windowMode) {
                    ForEach(WindowMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Picker("Retention Period", selection: $dataStore.settings.retentionPeriod) {
                    ForEach(RetentionPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.radioGroup)

                Stepper(value: $dataStore.settings.maxItemCount, in: 50...500, step: 50) {
                    Text("Max Items: \(dataStore.settings.maxItemCount)")
                }

                Toggle("Launch at Login", isOn: $dataStore.settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320, height: 280)
        .onChangeCompat(of: dataStore.settings.retentionPeriod) { _ in
            dataStore.saveSettings()
        }
        .onChangeCompat(of: dataStore.settings.maxItemCount) { _ in
            dataStore.saveSettings()
        }
        .onChangeCompat(of: dataStore.settings.launchAtLogin) { newValue in
            AutoLaunchManager.setEnabled(newValue)
            dataStore.saveSettings()
        }
        .onChangeCompat(of: dataStore.settings.windowMode) { _ in
            dataStore.saveSettings()
            dataStore.onWindowModeChanged?()
        }
    }
}
