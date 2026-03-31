import SwiftUI

enum StreamState {
    case idle
    case connecting
    case live
    case error(String)
}

struct ContentView: View {
    @StateObject private var settings = PrinterSettings()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var showSettings = false
    @State private var streamState: StreamState = .idle
    @State private var pipAction: (() -> Void)?
    @State private var startButtonPressed = false

    // True for every state except idle — keeps CameraView alive through errors
    private var isStreaming: Bool {
        if case .idle = streamState { return false }
        return true
    }

    // Landscape on iPhone = compact vertical size class
    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isStreaming {
                streamingLayout
                    .transition(.opacity)
            } else {
                idleLayout
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: isStreaming)
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }

    // MARK: - Streaming layout

    /// Video and control bar side-by-side (landscape) or stacked (portrait).
    /// CameraView is always at a stable structural position inside videoArea.
    @ViewBuilder
    private var streamingLayout: some View {
        if isLandscape {
            HStack(spacing: 0) {
                videoArea
                landscapeControlBar
                    .frame(width: 88)
            }
        } else {
            VStack(spacing: 0) {
                videoArea
                portraitControlBar
                    .frame(height: 88)
            }
        }
    }

    private var videoArea: some View {
        ZStack {
            Color.black

            if let url = settings.streamURL {
                CameraView(url: url, streamState: $streamState) { action in
                    pipAction = action
                }
                .opacity(streamState.isLive ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: streamState.isLive)
            }

            if case .connecting = streamState {
                connectingOverlay
                    .transition(.opacity)
            }

            if case .error(let msg) = streamState {
                errorOverlay(message: msg)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: streamState.phase)
    }

    // MARK: - Control bars (portrait and landscape are separate views with stable identity)

    private var portraitControlBar: some View {
        controlBarBackground(edge: .top) {
            HStack(spacing: 32) {
                stopButton
                Spacer()
                if case .live = streamState { pipButton.transition(.scale.combined(with: .opacity)) }
                settingsButton
            }
            .padding(.horizontal, 28)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: streamState.isLive)
    }

    private var landscapeControlBar: some View {
        controlBarBackground(edge: .leading) {
            VStack(spacing: 24) {
                stopButton
                Spacer()
                if case .live = streamState { pipButton.transition(.scale.combined(with: .opacity)) }
                settingsButton
            }
            .padding(.vertical, 20)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: streamState.isLive)
    }

    // MARK: - Individual buttons

    private var stopButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                streamState = .idle
                pipAction = nil
            }
        } label: {
            Image(systemName: "stop.fill").controlBarIcon(tint: .red)
        }
    }

    private var pipButton: some View {
        Button { pipAction?() } label: {
            Image(systemName: "pip.enter").controlBarIcon()
        }
    }

    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gearshape.fill").controlBarIcon()
        }
    }

    // MARK: - Control bar chrome

    private func controlBarBackground<Content: View>(
        edge: Edge,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: edge == .leading ? .leading : .top) {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(
                            width: edge == .leading ? 1 : nil,
                            height: edge == .leading ? nil : 1
                        )
                }
            content()
        }
    }

    // MARK: - Idle layout

    private var idleLayout: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            if !settings.isConfigured {
                Text("Configure your printer to get started")
                    .foregroundColor(.gray)
                Button("Open Settings") { showSettings = true }
                    .buttonStyle(.borderedProminent)
            } else {
                Text(settings.printerIP)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .monospaced()

                Button {
                    withAnimation { startButtonPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation {
                            startButtonPressed = false
                            streamState = .connecting
                        }
                    }
                } label: {
                    Label("Start Stream", systemImage: "play.fill")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.glassProminent)
                .tint(.green)
                .scaleEffect(startButtonPressed ? 0.93 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: startButtonPressed)

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Overlays

    private var connectingOverlay: some View {
        VStack(spacing: 20) {
            PulsingIcon(systemName: "wifi", color: .green)
            VStack(spacing: 6) {
                Text("Connecting")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(settings.printerIP)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospaced()
            }
        }
    }

    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            VStack(spacing: 8) {
                Text("Connection Failed")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button("Try Again") {
                withAnimation { streamState = .connecting }
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
        }
    }
}

// MARK: - Control bar icon style

private extension Image {
    func controlBarIcon(tint: Color = .white) -> some View {
        self
            .font(.title3)
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(.white.opacity(0.1), in: Circle())
            .contentShape(Circle())
    }
}

// MARK: - Pulsing icon

struct PulsingIcon: View {
    let systemName: String
    let color: Color
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 90, height: 90)
                .scaleEffect(pulsing ? 1.35 : 1.0)
                .opacity(pulsing ? 0 : 0.6)
                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulsing)
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 70, height: 70)
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(color)
        }
        .onAppear { pulsing = true }
    }
}

// MARK: - StreamState helpers

extension StreamState {
    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    var phase: Int {
        switch self {
        case .idle: return 0
        case .connecting: return 1
        case .live: return 2
        case .error: return 3
        }
    }
}
