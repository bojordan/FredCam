import SwiftUI
import KSPlayer

struct CameraView: UIViewRepresentable {
    let url: URL
    @Binding var statusText: String
    var onPipReady: ((@escaping () -> Void) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(statusText: $statusText)
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
            self.statusText = "Connecting..."
            self.onPipReady?({
                layer.isPipActive.toggle()
            })
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Attach the player's view to our container if not already done
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
        var statusText: Binding<String>

        init(statusText: Binding<String>) {
            self.statusText = statusText
        }

        func player(layer: KSPlayerLayer, state: KSPlayerState) {
            DispatchQueue.main.async {
                switch state {
                case .preparing:
                    self.statusText.wrappedValue = "Preparing..."
                    print("[FredCam] Preparing")
                case .readyToPlay:
                    self.statusText.wrappedValue = "Buffering..."
                    print("[FredCam] Ready to play")
                case .buffering:
                    self.statusText.wrappedValue = "Buffering..."
                    print("[FredCam] Buffering")
                case .bufferFinished:
                    self.statusText.wrappedValue = ""
                    print("[FredCam] Playing")
                case .paused:
                    self.statusText.wrappedValue = "Paused"
                case .playedToTheEnd:
                    self.statusText.wrappedValue = "Stream ended"
                case .error:
                    self.statusText.wrappedValue = "Connection error"
                    print("[FredCam] Error")
                default:
                    break
                }
            }
        }

        func player(layer: KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {}

        func player(layer: KSPlayerLayer, finish error: Error?) {
            if let error = error {
                print("[FredCam] Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.statusText.wrappedValue = "Error: \(error.localizedDescription)"
                }
            }
        }

        func player(layer: KSPlayerLayer, bufferedCount: Int, consumeTime: TimeInterval) {}
    }
}
