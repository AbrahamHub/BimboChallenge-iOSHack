import SwiftUI
import MapKit

struct Client: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let pieces: Int
}

struct MainRouteView: View {
    let clients: [Client] = [
        Client(name: "Abarrotes Don Chuy", address: "Av. Reforma 234, Col. Centro", pieces: 48),
        Client(name: "Tienda La Esquina", address: "Calle 5 de Mayo 89", pieces: 32),
        Client(name: "Mini Súper Lupita", address: "Insurgentes Sur 1102", pieces: 76)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                header
                routeCard
                clientList
                Spacer()
                startButton
            }
            .padding(.bottom, 8)
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        }
    }

    @EnvironmentObject var authVM: AuthViewModel

    var header: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 3.0/255.0, green: 24.0/255.0, blue: 80.0/255.0)
                .frame(height: 160)
                .cornerRadius(0)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mi Ruta")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Martes, 5 mayo · 6 clientes · 362 piezas")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .padding(.leading, 20)

                Spacer()

                Button(action: {
                    // Cerrar sesión: solo un botón
                    authVM.signOut()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .overlay(Text("B").fontWeight(.bold).foregroundColor(Color(red: 226/255, green: 27/255, blue: 26/255)))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20)
            }
            .padding(.top, 36)
        }
    }

    var routeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Map with simulated route
            RouteMapView(coordinates: simulatedCoordinates)
                .frame(height: 160)
                .cornerRadius(12)
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RUTA DEL DÍA")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.bottom, 6)

                            Text("Ver recorrido en Apple Maps")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                    .padding()
                    , alignment: .bottomLeading
                )
        }
        .padding(.horizontal, 16)
        .offset(y: -40)
    }

    var simulatedCoordinates: [CLLocationCoordinate2D] {
        [
            CLLocationCoordinate2D(latitude: 19.432608, longitude: -99.133209), // Centro
            CLLocationCoordinate2D(latitude: 19.427500, longitude: -99.162000), // Reforma area
            CLLocationCoordinate2D(latitude: 19.418700, longitude: -99.162000)  // Insurgentes area
        ]
    }
    var clientList: some View {
        VStack(spacing: 12) {
            ForEach(clients) { client in
                NavigationLink(destination: StopDetailView(client: client)) {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .background(Color.white)
                            .frame(height: 64)
                            .overlay(
                                HStack {
                                    Image(systemName: "house")
                                        .foregroundColor(.blue)
                                        .padding(.leading, 12)

                                    VStack(alignment: .leading) {
                                        Text(client.name)
                                            .fontWeight(.semibold)
                                        Text(client.address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Text("\(client.pieces)")
                                        .font(.headline)
                                        .foregroundColor(Color.red)
                                        .padding(.trailing, 16)
                                }
                            )
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .offset(y: -24)
    }

    var startButton: some View {
        Button(action: {
            // start route action
        }) {
            Text("Iniciar Recorrido")
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 226/255, green: 27/255, blue: 26/255))
                .cornerRadius(12)
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }

}

// UIViewRepresentable that shows annotations and a route polyline
struct RouteMapView: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.showsUserLocation = false

        updateAnnotationsAndOverlay(on: map)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // update annotations/overlay when coordinates change
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
                r.lineWidth = 4
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
                view?.canShowCallout = true
                view?.markerTintColor = UIColor(red: 226/255, green: 27/255, blue: 26/255, alpha: 1)
                view?.glyphTintColor = .white
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
    }
}
