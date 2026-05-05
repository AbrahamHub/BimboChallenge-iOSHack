import Combine
import Network

/// Estado de conectividad para modo offline (badge, ocultar anaquel, etc.).
final class ConnectivityViewModel: ObservableObject {
    @Published private(set) var isOffline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bimbosis.network")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
