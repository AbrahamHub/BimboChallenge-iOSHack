import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        BottomTabView()
            .overlay(alignment: .top) {
                if let message = auth.successMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)

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
    var body: some View {
        TabView {
            MainRouteView()
                .tabItem {
                    Label("Ruta", systemImage: "mappin")
                }

            StockView()
                .tabItem {
                    Label("Stock", systemImage: "cube.box")
                }

            HistorialView()
                .tabItem {
                    Label("Historial", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
        }
        .tint(Color(red: 226/255, green: 27/255, blue: 26/255))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AuthViewModel())
    }
}
