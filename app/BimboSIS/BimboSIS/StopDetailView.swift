import SwiftUI
import UIKit

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let qty: Int
}

struct StopDetailView: View {
    let client: Client

    let products: [Product] = [
        Product(name: "Pan Blanco Grande", qty: 12),
        Product(name: "Pan Integral", qty: 8),
        Product(name: "Bimbolos", qty: 6)
    ]

    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil
    @State private var showImagePreview = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(products) { p in
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 56, height: 56)
                                .overlay(Text("ÍCONO").font(.caption))

                            VStack(alignment: .leading) {
                                Text(p.name)
                                    .fontWeight(.semibold)
                                Text("A entregar")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("\(p.qty)")
                                .font(.headline)
                                .padding(10)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }

                    VStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.2.circlepath")
                                Text("Productos a Rotar")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 3/255, green: 24/255, blue: 80/255))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        Button(action: {}) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Confirmar de Entregado")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        Button(action: {
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Escanear anaquel")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        .sheet(isPresented: $showCamera) {
                            ImagePicker(sourceType: .camera) { image in
                                if let img = image {
                                    capturedImage = img
                                    showImagePreview = true
                                }
                                showCamera = false
                            }
                        }

                        if showImagePreview, let img = capturedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.top, 18)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    var header: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 3.0/255.0, green: 24.0/255.0, blue: 80.0/255.0)
                .frame(height: 200)

            VStack(alignment: .leading, spacing: 8) {
                Text("PRÓXIMA PARADA · 2 DE 6")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.85))

                Text(client.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.9))
                    Text(client.address)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .font(.subheadline)
            }
            .padding(.leading, 20)
            .padding(.top, 44)

            Circle()
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .overlay(Text("B").fontWeight(.bold).foregroundColor(Color(red: 226/255, green: 27/255, blue: 26/255)))
                .padding(.trailing, 20)
        }
    }
}

// Simple ImagePicker using UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    enum PickerSourceType {
        case camera, photoLibrary
    }

    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = info[.originalImage] as? UIImage
            parent.completion(img)
        }
    }
}
