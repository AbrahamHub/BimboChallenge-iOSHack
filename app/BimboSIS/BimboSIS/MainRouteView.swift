import SwiftUI
import MapKit

struct Client: Identifiable, Equatable 
{
    let id = UUID()
    let name: String
    let address: String
    let pieces: Int
    var status: ClientStatus
    let isSuggestedRotation: Bool
}

enum ClientStatus: String, Equatable {
    case next = "SIGUIENTE"
    case pending = "PENDIENTE"
    case complete = "COMPLETADA"
}

struct MainRouteView: View {
    @State private var clients: [Client] = [
        Client(name: "Tienda La Esquina", address: "Calle 5 de Mayo 89", pieces: 32, status: .next, isSuggestedRotation: true),
        Client(name: "Abarrotes El Sol", address: "Calz. de Tlalpan 567", pieces: 54, status: .pending, isSuggestedRotation: false),
        Client(name: "Mini Súper Lupita", address: "Insurgentes Sur 1102", pieces: 76, status: .pending, isSuggestedRotation: false),
        Client(name: "Abarrotes Don Chuy", address: "Av. Reforma 234, Col. Centro", pieces: 48, status: .complete, isSuggestedRotation: false)
    ]

    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var routeSession: RouteSessionController
    @State private var showNextStop = false
    @State private var routeStarted = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        clientsSection
                    }
                }
                .background(AppPalette.background.ignoresSafeArea())

                continueButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showNextStop) {
                StopDetailView(client: nextClient, onComplete: {
                    completeClient(nextClient)
                })
            }
            .onAppear {
                routeSession.onExitFlowToMainMenu = {
                    showNextStop = false
                }
            }
            .onDisappear {
                routeSession.onExitFlowToMainMenu = nil
            }
        }
    }

    var header: some View {
        ZStack(alignment: .bottom) {
            AppPalette.navy
                .frame(height: BimboLayout.routeHeroNavyHeight)
                .clipShape(RoundedRectangle(cornerRadius: BimboLayout.heroCornerRadius, style: .continuous))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: BimboLayout.routeHeroRowToMapSpacing) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: BimboLayout.routeHeroTitleSubtitleSpacing) {
                        Text("Mi Ruta")
                            .font(.system(size: BimboLayout.titleSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(routeStatusSubtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)
                    }

                    Spacer(minLength: 8)

                    BrandLogoToolbarCluster(logoSize: 64) { authVM.signOut() }
                }

                RoutePreviewCard(coordinates: simulatedCoordinates)
                    .padding(.bottom, -52)
            }
            .padding(.horizontal, BimboLayout.heroHorizontalPadding)
            .padding(.top, BimboLayout.routeHeroTopPadding)
            .padding(.bottom, 2)
        }
    }

    var clientsSection: some View {
        VStack(spacing: 12) {
            ForEach(clients) { client in
                Group {
                    if client.status == .next {
                        NavigationLink {
                            StopDetailView(client: client, onComplete: {
                                completeClient(client)
                            })
                        } label: {
                            ClientStopRow(client: client)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            routeSession.beginDeliveryFlow()
                        })
                    } else {
                        ClientStopRow(client: client)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 68)
        .padding(.bottom, routeSession.hidesMainTabBar ? 100 : 168)
    }

    private let simulatedCoordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 19.432608, longitude: -99.133209),
        CLLocationCoordinate2D(latitude: 19.427500, longitude: -99.162000),
        CLLocationCoordinate2D(latitude: 19.418700, longitude: -99.162000)
    ]

    private var routeStatusSubtitle: String {
        let atendidas = clients.filter { $0.status == .complete }.count
        let pendientes = clients.filter { $0.status == .next || $0.status == .pending }.count
        let sufijo = atendidas == 1 ? "" : "s"
        return "Martes, 5 mayo · \(atendidas) atendida\(sufijo) · \(pendientes) pendientes"
    }

    var continueButton: some View {
        VStack(spacing: 10) {
            Button {
                routeSession.beginDeliveryFlow()
                routeStarted = true
                showNextStop = true
            } label: {
                Text("Comenzar Ruta")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppPalette.brandRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                routeSession.beginDeliveryFlow()
                showNextStop = true
            } label: {
                Text("Continuar Recorrido")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppPalette.brandRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: routeStarted ? AppPalette.brandRed.opacity(0.38) : .clear, radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    var nextClient: Client {
        clients.first(where: { $0.status == .next }) ?? clients[0]
    }
    
    private func completeClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index].status = .complete
            
            // Find the next pending client and make it next
            if let nextIndex = clients.firstIndex(where: { $0.status == .pending }) {
                clients[nextIndex].status = .next
            }
        }
    }
}

private struct RoutePreviewCard: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(coordinates: coordinates)
                .frame(height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    RouteCaption()
                }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}

private struct RouteCaption: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.white)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(AppPalette.navy)
                        .font(.caption.weight(.bold))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("RUTA DEL DÍA")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(AppPalette.lineYellow)

                Text("Ver recorrido en Apple Maps")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("6 paradas · 12.4 km · 1h 45min")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial.opacity(0.22))
    }
}

private struct ClientStopRow: View {
    let client: Client

    private var isCompleted: Bool {
        client.status == .complete
    }

    /// Pendientes que aún no son la parada activa (no clicables).
    private var isLockedPending: Bool {
        client.status == .pending
    }

    private var titleForeground: Color {
        if isCompleted || isLockedPending {
            return Color.secondary
        }
        return Color.primary
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                icon

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(client.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(titleForeground)
                            .lineLimit(1)

                        if client.status == .next {
                            statusBadge
                        }
                    }

                    Text(client.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(isCompleted ? 0.85 : 1)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Group {
                    if isCompleted {
                        Text("ATENDIDA")
                            .font(.caption.weight(.heavy))
                            .tracking(0.4)
                            .foregroundStyle(AppPalette.semaphoreGreenText)
                    } else if isLockedPending {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(client.pieces)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.secondary.opacity(0.85))
                            Text("PZS")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(client.pieces)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppPalette.brandRed)
                            Text("PZS")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if client.isSuggestedRotation {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.caption.weight(.bold))
                    Text("ROTACIÓN SUGERIDA")
                        .font(.caption.weight(.heavy))
                    Text("Llevar 4 × pan integral")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(AppPalette.navy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 233.0 / 255.0, green: 239.0 / 255.0, blue: 250.0 / 255.0))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    client.status == .next ? AppPalette.brandRed.opacity(0.35) : Color.gray.opacity(0.15),
                    lineWidth: 1
                )
        )
        .opacity(isCompleted ? 0.92 : (isLockedPending ? 0.78 : 1))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var icon: some View {
        Group {
            if isCompleted {
                Circle()
                    .fill(AppPalette.semaphoreGreenFill)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "checkmark")
                            .foregroundStyle(AppPalette.semaphoreGreenText)
                            .font(.callout.weight(.bold))
                    }
            } else {
                Circle()
                    .fill(Color(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 252.0 / 255.0))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "storefront")
                            .foregroundStyle(AppPalette.navy)
                            .font(.callout.weight(.bold))
                    }
            }
        }
    }

    private var statusBadge: some View {
        Text(client.status.rawValue)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(AppPalette.brandRed)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(AppPalette.brandRed.opacity(0.12))
            )
    }
}

struct RouteMapView: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.showsUserLocation = false
        map.isUserInteractionEnabled = false

        context.coordinator.parent = self
        updateAnnotationsAndOverlay(on: map)
        context.coordinator.cacheCoordinates(coordinates)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        guard !context.coordinator.coordinatesMatch(coordinates) else { return }
        context.coordinator.cacheCoordinates(coordinates)
        updateAnnotationsAndOverlay(on: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func updateAnnotationsAndOverlay(on map: MKMapView) {
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)

        var annotations: [MKPointAnnotation] = []
        for (i, coord) in coordinates.enumerated() {
            let a = MKPointAnnotation()
            a.coordinate = coord
            a.title = "Parada \(i+1)"
            annotations.append(a)
        }
        map.addAnnotations(annotations)

        if coordinates.count > 1 {
            let poly = MKPolyline(coordinates: coordinates, count: coordinates.count)
            map.addOverlay(poly)
            map.setVisibleMapRect(poly.boundingMapRect.insetBy(dx: -5000, dy: -5000), edgePadding: .init(top: 16, left: 16, bottom: 16, right: 16), animated: false)
        } else if let first = coordinates.first {
            let region = MKCoordinateRegion(center: first, latitudinalMeters: 2000, longitudinalMeters: 2000)
            map.setRegion(region, animated: false)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        private var cachedCoordinates: [CLLocationCoordinate2D]?

        init(_ parent: RouteMapView) {
            self.parent = parent
        }

        func coordinatesMatch(_ new: [CLLocationCoordinate2D]) -> Bool {
            guard let cached = cachedCoordinates, cached.count == new.count else { return false }
            return zip(cached, new).allSatisfy { a, b in
                a.latitude == b.latitude && a.longitude == b.longitude
            }
        }

        func cacheCoordinates(_ coords: [CLLocationCoordinate2D]) {
            cachedCoordinates = coords
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor(red: 255/255, green: 199/255, blue: 44/255, alpha: 1)
                r.lineWidth = 3
                r.lineDashPattern = [6, 8]
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let id = "pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = false
                view?.markerTintColor = UIColor(red: 226/255, green: 27/255, blue: 26/255, alpha: 1)
                view?.glyphTintColor = .white
                view?.displayPriority = .required
            } else {
                view?.annotation = annotation
            }
            return view
        }
    }
}
struct MainRouteView_Previews: PreviewProvider {
    static var previews: some View {
        MainRouteView()
            .environmentObject(AuthViewModel())
            .environmentObject(ConnectivityViewModel())
            .environmentObject(RouteSessionController())
    }
}
