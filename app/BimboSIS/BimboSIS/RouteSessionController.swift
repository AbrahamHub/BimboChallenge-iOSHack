import Combine
import SwiftUI

/// Controla la barra principal de pestañas durante el recorrido: se oculta al iniciar la ruta
/// y solo vuelve al confirmar la compra en **Carrito / ERP**.
final class RouteSessionController: ObservableObject {
    @Published private(set) var hidesMainTabBar: Bool = false

    /// Nombre de tienda pendiente de cerrar ciclo (visita atendida + volver a **Mi Ruta**). Lo observa `MainRouteView`.
    @Published private(set) var pendingFinalizeVisitStoreName: String?

    func beginDeliveryFlow() {
        guard !hidesMainTabBar else { return }
        hidesMainTabBar = true
    }

    /// Tras **Confirmar** en el modal ERP: muestra la barra de pestañas, emite el nombre para marcar la tienda **ATENDIDA** y cerrar el detalle.
    func completePurchaseAndReturnToMainMenu(storeName: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hidesMainTabBar = false
            self.pendingFinalizeVisitStoreName = storeName
        }
    }

    func clearPendingFinalizeVisit() {
        pendingFinalizeVisitStoreName = nil
    }
}
