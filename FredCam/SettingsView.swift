import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: PrinterSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showAccessCode = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // decimalPad gives digits + "." key so the user types the dots themselves
                    TextField("192.168.1.1", text: $settings.printerIP)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .monospaced()
                        .onChange(of: settings.printerIP) { _, newValue in
                            // Strip anything that isn't a digit or dot
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                settings.printerIP = filtered
                            }
                        }

                    // Access Code with show/hide toggle
                    HStack {
                        if showAccessCode {
                            TextField("Access Code", text: $settings.accessCode)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .monospaced()
                        } else {
                            SecureField("Access Code", text: $settings.accessCode)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .monospaced()
                        }
                        Button {
                            showAccessCode.toggle()
                        } label: {
                            Image(systemName: showAccessCode ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
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
