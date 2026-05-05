import SwiftUI
import AVFoundation

struct ShelfScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = ShelfCameraModel()
    @State private var tutorialStep = 0
    @State private var showTutorial = true

    let onCaptured: (UIImage) -> Void

    private let tutorialTips: [String] = [
        "Alinea el anaquel dentro del marco",
        "Evita reflejos y sombras fuertes",
        "Toca el botón blanco para capturar"
    ]

    var body: some View {
        ZStack {
            CameraPreviewLayer(session: camera.session)
                .ignoresSafeArea()

            Color.black.opacity(0.34).ignoresSafeArea()

            scannerFrameOverlay
            scannerGridOverlay
            topBar
            centerStatusPill
            bottomControls
            tutorialOverlay

            if camera.permissionDenied {
                permissionView
            }
        }
        .task {
            camera.configureSession()
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Cancelar") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.35))
                    .clipShape(Capsule())

                Spacer()

                Text("Capturar Anaquel")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    // TODO: Mostrar ayuda detallada del escáner.
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Ayuda"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            Spacer()
        }
    }

    private var centerStatusPill: some View {
        VStack {
            Capsule(style: .continuous)
                .fill(camera.capturedImage == nil ? AppPalette.brandRed : AppPalette.lineYellow)
                .frame(width: 140, height: 32)
                .overlay {
                    HStack(spacing: 6) {
                        if camera.capturedImage != nil {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                        }
                        Text(camera.capturedImage == nil ? "Centra el encuadre" : "Anaquel escaneado")
                            .font(.caption.weight(.heavy))
                    }
                    .foregroundStyle(camera.capturedImage == nil ? .white : .black)
                }
                .padding(.top, 98)
            Spacer()
        }
    }

    private var scannerFrameOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.white.opacity(0.14), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            .frame(width: 250, height: 250)
            .overlay(alignment: .topLeading) {
                ScannerCorner(color: cornerColor, rotation: .degrees(0))
            }
            .overlay(alignment: .topTrailing) {
                ScannerCorner(color: cornerColor, rotation: .degrees(90))
            }
            .overlay(alignment: .bottomLeading) {
                ScannerCorner(color: cornerColor, rotation: .degrees(-90))
            }
            .overlay(alignment: .bottomTrailing) {
                ScannerCorner(color: cornerColor, rotation: .degrees(180))
            }
    }

    private var scannerGridOverlay: some View {
        ZStack {
            ForEach(1..<3) { index in
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1)
                    .frame(maxHeight: 300)
                    .offset(x: CGFloat(index - 1) * 84)
            }
            ForEach(1..<3) { index in
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                    .frame(maxWidth: 300)
                    .offset(y: CGFloat(index - 1) * 84)
            }
        }
    }

    private var bottomControls: some View {
        VStack {
            Spacer()

            if let image = camera.capturedImage {
                VStack(spacing: 10) {
                    Button {
                        onCaptured(image)
                        dismiss()
                    } label: {
                        HStack {
                            Text("Finalizar y generar acomodo")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppPalette.brandRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        camera.resetCapture()
                        tutorialStep = 0
                        showTutorial = true
                    } label: {
                        Text("Volver a capturar")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.95), lineWidth: 1.2)
                            )
                    }
                }
                .padding(.horizontal, 24)
            } else {
                HStack {
                    CircleButton(systemName: "photo.on.rectangle.angled")
                    Spacer()
                    Button {
                        camera.capturePhoto()
                    } label: {
                        ZStack {
                            Circle().fill(.white).frame(width: 74, height: 74)
                            Circle().stroke(.black, lineWidth: 2).frame(width: 62, height: 62)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    CircleButton(systemName: "arrow.clockwise")
                }
                .padding(.horizontal, 34)
            }
        }
        .padding(.bottom, 26)
    }

    private var tutorialOverlay: some View {
        VStack {
            Spacer()
            if showTutorial, camera.capturedImage == nil {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppPalette.navy)
                    Text(tutorialTips[tutorialStep])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                    Spacer()
                    Button(tutorialStep == tutorialTips.count - 1 ? "Ok" : "Siguiente") {
                        if tutorialStep < tutorialTips.count - 1 {
                            tutorialStep += 1
                        } else {
                            showTutorial = false
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 26)
                .padding(.bottom, 122)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showTutorial)
        .animation(.easeInOut, value: tutorialStep)
    }

    private var permissionView: some View {
        VStack(spacing: 12) {
            Text("Activa el permiso de cámara para escanear anaqueles.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Button("Abrir configuración") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(Capsule())
        }
        .padding(20)
        .background(.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 30)
    }

    private var cornerColor: Color {
        camera.capturedImage == nil ? AppPalette.brandRed : AppPalette.lineYellow
    }
}

private struct ScannerCorner: View {
    let color: Color
    let rotation: Angle

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 34))
            path.addLine(to: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: 34, y: 2))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: 36, height: 36)
        .rotationEffect(rotation)
        .padding(10)
    }
}

private struct CircleButton: View {
    let systemName: String

    var body: some View {
        Button {
            // TODO: Conectar galería/cambio de cámara según icono.
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.45))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            return AVCaptureVideoPreviewLayer()
        }
        return layer
    }
}

final class ShelfCameraModel: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var permissionDenied = false

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "shelf.camera.queue")
    private var configured = false

    func configureSession() {
        guard !configured else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func setupSession() {
        queue.async { [weak self] in
            guard let self else { return }
            guard !self.configured else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input),
                  self.session.canAddOutput(self.output) else {
                DispatchQueue.main.async { self.permissionDenied = true }
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.output)
            self.session.commitConfiguration()
            self.configured = true
        }
    }

    func startSession() {
        queue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() {
        guard configured else { return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        output.capturePhoto(with: settings, delegate: self)
    }

    func resetCapture() {
        capturedImage = nil
    }
}

extension ShelfCameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
