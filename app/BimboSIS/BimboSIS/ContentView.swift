import SwiftUI

private enum MainTab: Hashable, CaseIterable {
    case route
    case stock
    case historial

    var title: String {
        switch self {
        case .route: return "Ruta"
        case .stock: return "Stock"
        case .historial: return "Historial"
        }
    }

    /// SF Symbols recomendados por Apple para inventario, mapa y historial.
    var systemImage: String {
        switch self {
        case .route: return "map.fill"
        case .stock: return "shippingbox.fill"
        case .historial: return "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        BottomTabView()
            .overlay(alignment: .top) {
                if let message = auth.successMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)

                        Text(message)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: auth.successMessage)
            .task(id: auth.successMessage) {
                guard let message = auth.successMessage else { return }

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if auth.successMessage == message {
                    auth.successMessage = nil
                }
            }
    }
}

struct BottomTabView: View {
    @EnvironmentObject private var routeSession: RouteSessionController
    @State private var tab: MainTab = .route

    var body: some View {
        Group {
            switch tab {
            case .route:
                MainRouteView()
            case .stock:
                StockView()
            case .historial:
                HistorialView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !routeSession.hidesMainTabBar {
                MainTabBar(selection: $tab)
            }
        }
        .tint(AppPalette.brandRed)
    }
}

private struct MainTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.18))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 26, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(selection == tab ? AppPalette.brandRed : Color.secondary)

                            Text(tab.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selection == tab ? AppPalette.brandRed : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(tab.title))
                }
            }
            .background(Color.white)
        }
        .accessibilityElement(children: .contain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(ConnectivityViewModel())
            .environmentObject(RouteSessionController())
    }
}
