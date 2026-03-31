import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: PrinterSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Printer IP Address", text: $settings.printerIP)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Access Code", text: $settings.accessCode)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Bambu Lab Printer")
                } footer: {
                    Text("Find the Access Code in your printer's touchscreen under Settings > Network.")
                }

                Section {
                    LabeledContent("Stream URL") {
                        if settings.isConfigured {
                            Text("rtsps://\(settings.printerIP):322")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not configured")
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Connection")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
