import Combine
import SwiftUI

/// Controla la barra principal de pestañas durante el recorrido: se oculta al iniciar la ruta
/// y solo vuelve al confirmar la compra en **Confirmar orden** (carrito / ERP).
final class RouteSessionController: ObservableObject {
    @Published private(set) var hidesMainTabBar: Bool = false

    /// Lo asigna `MainRouteView`: recibe el nombre de tienda para marcar **atendida** y cerrar el detalle de parada.
    var onExitFlowToMainMenu: ((String?) -> Void)?

    func beginDeliveryFlow() {
        guard !hidesMainTabBar else { return }
        hidesMainTabBar = true
    }

    /// Tras confirmar en el modal ERP del **Carrito**: restaura tabs, marca la tienda y vuelve a **Mi Ruta** en un solo paso.
    func completePurchaseAndReturnToMainMenu(storeName: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hidesMainTabBar = false
            self.onExitFlowToMainMenu?(storeName)
        }
    }
}
