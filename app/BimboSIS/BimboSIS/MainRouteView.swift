import SwiftUI
import MapKit

struct Client: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let pieces: Int
    let status: ClientStatus
    let isSuggestedRotation: Bool
}

enum ClientStatus: String {
    case next = "SIGUIENTE"
    case pending = "PENDIENTE"
    case complete = "COMPLETADA"
}

struct MainRouteView: View {
    let clients: [Client] = [
        Client(name: "Tienda La Esquina", address: "Calle 5 de Mayo 89", pieces: 32, status: .next, isSuggestedRotation: true),
        Client(name: "Abarrotes Don Chuy", address: "Av. Reforma 234, Col. Centro", pieces: 48, status: .pending, isSuggestedRotation: false),
        Client(name: "Mini Súper Lupita", address: "Insurgentes Sur 1102", pieces: 76, status: .pending, isSuggestedRotation: false)
    ]

    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        RoutePreviewCard(coordinates: simulatedCoordinates)
                        clientsSection
                    }
                }
                .background(RoutePalette.background.ignoresSafeArea())

                continueButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    var header: some View {
        ZStack(alignment: .bottom) {
            RoutePalette.navy
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi Ruta")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Martes, 5 mayo · 1 atendida · 5 pendientes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    Button {
                        authVM.signOut()
                    } label: {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text("B")
                                    .font(.title3.weight(.heavy))
                                    .foregroundStyle(RoutePalette.brandRed)
                            }
                    }
                    .buttonStyle(.plain)
                }

                RoutePreviewCard(coordinates: simulatedCoordinates)
                    .padding(.bottom, -52)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
    }

    var clientsSection: some View {
        VStack(spacing: 12) {
            ForEach(clients) { client in
                NavigationLink {
                    StopDetailView(client: client)
                } label: {
                    ClientStopRow(client: client)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 68)
        .padding(.bottom, 120)
    }

    var simulatedCoordinates: [CLLocationCoordinate2D] {
        [
            CLLocationCoordinate2D(latitude: 19.432608, longitude: -99.133209),
            CLLocationCoordinate2D(latitude: 19.427500, longitude: -99.162000),
            CLLocationCoordinate2D(latitude: 19.418700, longitude: -99.162000)
        ]
    }

    var continueButton: some View {
        Button {} label: {
            Text("Continuar Recorrido")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(RoutePalette.brandRed)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }
}

private enum RoutePalette {
    static let navy = Color(red: 3.0 / 255.0, green: 24.0 / 255.0, blue: 80.0 / 255.0)
    static let brandRed = Color(red: 226.0 / 255.0, green: 27.0 / 255.0, blue: 26.0 / 255.0)
    static let background = Color(red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 252.0 / 255.0)
    static let lineYellow = Color(red: 255.0 / 255.0, green: 199.0 / 255.0, blue: 44.0 / 255.0)
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
                        .foregroundStyle(RoutePalette.navy)
                        .font(.caption.weight(.bold))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("RUTA DEL DÍA")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(RoutePalette.lineYellow)

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

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                icon

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(client.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if client.status == .next {
                            statusBadge
                        }
                    }

                    Text(client.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(client.pieces)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(RoutePalette.brandRed)
                    Text("PZS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
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
                .foregroundStyle(RoutePalette.navy)
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
                .stroke(client.status == .next ? RoutePalette.brandRed.opacity(0.35) : Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var icon: some View {
        Circle()
            .fill(Color(red: 242.0 / 255.0, green: 245.0 / 255.0, blue: 252.0 / 255.0))
            .frame(width: 38, height: 38)
            .overlay {
                Image(systemName: "storefront")
                    .foregroundStyle(RoutePalette.navy)
                    .font(.callout.weight(.bold))
            }
    }

    private var statusBadge: some View {
        Text(client.status.rawValue)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(RoutePalette.brandRed)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(RoutePalette.brandRed.opacity(0.12))
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

        updateAnnotationsAndOverlay(on: map)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
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

        init(_ parent: RouteMapView) {
            self.parent = parent
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
    }
}
