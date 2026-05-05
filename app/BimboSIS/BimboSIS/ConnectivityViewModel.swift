import Combine
import Network

/// Estado de conectividad para modo offline (badge, ocultar anaquel, etc.).
/// Usa `NWPathMonitor`: **offline** = no hay ruta de red satisfecha (sin Wi‑Fi, datos ni ethernet útil).
final class ConnectivityViewModel: ObservableObject {
    @Published private(set) var isOffline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bimbosis.network")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.publishOfflineStatus(for: path)
        }
        monitor.start(queue: queue)

        // Evita un frame inicial incorrecto: `currentPath` ya está disponible tras `start`.
        queue.async { [weak self] in
            guard let self else { return }
            let path = self.monitor.currentPath
            self.publishOfflineStatus(for: path)
        }
    }

    private func publishOfflineStatus(for path: NWPath) {
        let offline = path.status != .satisfied
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.isOffline != offline {
                self.isOffline = offline
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}
