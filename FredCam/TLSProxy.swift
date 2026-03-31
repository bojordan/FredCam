import Foundation
import Network

/// A local TCP proxy that accepts plain-text connections on localhost
/// and forwards them to a remote host over TLS, bypassing certificate verification.
/// This lets VLC connect via plain rtsp:// while the printer requires rtsps://.
class TLSProxy {
    let remoteHost: String
    let remotePort: UInt16
    let localPort: UInt16

    private var listener: NWListener?
    private var connections: [ProxiedConnection] = []
    private let queue = DispatchQueue(label: "TLSProxy")

    init(remoteHost: String, remotePort: UInt16 = 322, localPort: UInt16 = 8554) {
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.localPort = localPort
    }

    func start() throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: localPort)!)
        params.acceptLocalOnly = true

        let listener = try NWListener(using: params)
        self.listener = listener

        listener.newConnectionHandler = { [weak self] localConn in
            self?.handleNewConnection(localConn)
        }
        listener.stateUpdateHandler = { state in
            print("[TLSProxy] Listener state: \(state)")
        }
        listener.start(queue: queue)
        print("[TLSProxy] Listening on 127.0.0.1:\(localPort) → \(remoteHost):\(remotePort)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for conn in connections {
            conn.cancel()
        }
        connections.removeAll()
    }

    private func handleNewConnection(_ localConn: NWConnection) {
        // Create TLS connection to the printer, skipping cert verification
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { _, _, completionHandler in
                completionHandler(true) // Accept any certificate
            },
            queue
        )
        let remoteParams = NWParameters(tls: tlsOptions, tcp: .init())
        let remoteConn = NWConnection(
            host: NWEndpoint.Host(remoteHost),
            port: NWEndpoint.Port(rawValue: remotePort)!,
            using: remoteParams
        )

        let proxied = ProxiedConnection(local: localConn, remote: remoteConn)
        connections.append(proxied)
        proxied.start(on: queue) { [weak self] in
            self?.connections.removeAll { $0 === proxied }
        }
    }
}

private class ProxiedConnection {
    let local: NWConnection
    let remote: NWConnection
    private var onDone: (() -> Void)?

    init(local: NWConnection, remote: NWConnection) {
        self.local = local
        self.remote = remote
    }

    func start(on queue: DispatchQueue, onDone: @escaping () -> Void) {
        self.onDone = onDone

        local.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
            if case .cancelled = state { self?.cancel() }
        }
        remote.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
            if case .cancelled = state { self?.cancel() }
            if case .ready = state {
                print("[TLSProxy] TLS connection established")
            }
        }

        local.start(queue: queue)
        remote.start(queue: queue)

        // Bidirectional forwarding
        forward(from: local, to: remote, label: "client→printer")
        forward(from: remote, to: local, label: "printer→client")
    }

    private func forward(from source: NWConnection, to dest: NWConnection, label: String) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                dest.send(content: data, completion: .contentProcessed { _ in })
                self?.forward(from: source, to: dest, label: label)
            }
            if isComplete || error != nil {
                self?.cancel()
            }
        }
    }

    func cancel() {
        local.cancel()
        remote.cancel()
        onDone?()
        onDone = nil
    }
}
