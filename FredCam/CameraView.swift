import SwiftUI
import KSPlayer

struct CameraView: UIViewRepresentable {
    let url: URL
    @Binding var streamState: StreamState
    var onPipReady: ((@escaping () -> Void) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(streamState: $streamState)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black

        let options = KSOptions()
        options.avOptions["rtsp_transport"] = "tcp"
        options.avOptions["tls_verify"] = "0"
        options.nobuffer = true
        options.codecLowDelay = true
        options.maxAnalyzeDuration = 1_000_000
        options.probesize = 500_000
        options.registerRemoteControll = false
        options.canStartPictureInPictureAutomaticallyFromInline = true

        let layer = KSPlayerLayer(url: url, options: options, delegate: context.coordinator)
        context.coordinator.playerLayer = layer
        layer.play()

        DispatchQueue.main.async {
            self.onPipReady?({
                layer.isPipActive.toggle()
            })
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = context.coordinator.playerLayer,
           let playerView = playerLayer.player.view,
           playerView.superview == nil {
            playerView.frame = uiView.bounds
            playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            uiView.addSubview(playerView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.playerLayer?.stop()
        coordinator.playerLayer = nil
    }

    class Coordinator: NSObject, KSPlayerLayerDelegate {
        var playerLayer: KSPlayerLayer?
        var streamState: Binding<StreamState>

        init(streamState: Binding<StreamState>) {
            self.streamState = streamState
        }

        func player(layer: KSPlayerLayer, state: KSPlayerState) {
            DispatchQueue.main.async {
                switch state {
                case .preparing, .readyToPlay, .buffering:
                    if case .connecting = self.streamState.wrappedValue { } // stay in connecting
                    else { self.streamState.wrappedValue = .connecting }
                case .bufferFinished:
                    withAnimation(.easeIn(duration: 0.5)) {
                        self.streamState.wrappedValue = .live
                    }
                case .error:
                    withAnimation {
                        self.streamState.wrappedValue = .error("Could not connect to printer camera.")
                    }
                default:
                    break
                }
            }
        }

        func player(layer: KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {}

        func player(layer: KSPlayerLayer, finish error: Error?) {
            guard let error = error else { return }
            DispatchQueue.main.async {
                withAnimation {
                    self.streamState.wrappedValue = .error(error.localizedDescription)
                }
            }
        }

        func player(layer: KSPlayerLayer, bufferedCount: Int, consumeTime: TimeInterval) {}
    }
}
