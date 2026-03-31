import SwiftUI

struct ContentView: View {
    @StateObject private var settings = PrinterSettings()
    @State private var showSettings = false
    @State private var isStreaming = false
    @State private var statusText = ""
    @State private var pipAction: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isStreaming, let url = settings.streamURL {
                CameraView(url: url, statusText: $statusText) { action in
                    pipAction = action
                }
                .ignoresSafeArea()
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)

                    if !settings.isConfigured {
                        Text("Configure your printer to get started")
                            .foregroundColor(.gray)
                        Button("Open Settings") {
                            showSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Ready to connect to \(settings.printerIP)")
                            .foregroundColor(.gray)
                        Button {
                            isStreaming = true
                        } label: {
                            Label("Start Stream", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }

            // Status overlay
            if !statusText.isEmpty {
                VStack {
                    Spacer()
                    Text(statusText)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.7), in: Capsule())
                        .padding(.bottom, 60)
                }
            }

            // Floating controls overlay
            VStack {
                HStack {
                    if isStreaming {
                        Button {
                            isStreaming = false
                            statusText = ""
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.red.opacity(0.8), in: Circle())
                        }
                    }
                    Spacer()
                    if isStreaming {
                        Button {
                            pipAction?()
                        } label: {
                            Image(systemName: "pip.enter")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }
}
