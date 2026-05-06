import Combine
import SwiftUI

/// Controla la barra principal de pestañas durante el recorrido: se oculta al iniciar la ruta
/// y solo vuelve al confirmar la compra en **Confirmar orden** (carrito / ERP).
final class RouteSessionController: ObservableObject {
    @Published private(set) var hidesMainTabBar: Bool = false

    /// Lo asigna `MainRouteView` para cerrar el `NavigationStack` del recorrido.
    var onExitFlowToMainMenu: (() -> Void)?

    func beginDeliveryFlow() {
        guard !hidesMainTabBar else { return }
        hidesMainTabBar = true
    }

    func completePurchaseAndReturnToMainMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hidesMainTabBar = false
            self.onExitFlowToMainMenu?()
        }
    }
}
