import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel

    private var platformGroupedBackground: Color {
#if canImport(UIKit)
        Color(UIColor.systemGroupedBackground)
#else
        Color.white
#endif
    }

    private var platformInputBackground: Color {
#if canImport(UIKit)
        Color(UIColor.systemGray6)
#else
        Color.gray.opacity(0.1)
#endif
    }

    var body: some View {
        ZStack {
            platformGroupedBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Color(red: 3.0 / 255.0, green: 24.0 / 255.0, blue: 80.0 / 255.0)

                    VStack(spacing: 8) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .padding(.top, 28)

                        Text("BimboSIS")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("Inicia sesión para continuar")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 28)
                }
                .frame(height: 230)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USUARIO")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("", text: $auth.email, prompt: Text("Correo electrónico").foregroundColor(.gray))
#if canImport(UIKit)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
#endif
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(platformInputBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTRASEÑA")
                            .font(.caption)
                            .foregroundColor(.gray)

                        SecureField("", text: $auth.password, prompt: Text("Contraseña").foregroundColor(.gray))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(platformInputBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                            )
                    }

                    Button {
                        auth.signIn()
                    } label: {
                        Text(auth.isLoading ? "Ingresando..." : "Ingresar")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 226 / 255, green: 27 / 255, blue: 26 / 255))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
                    }
                    .disabled(auth.isLoading)

                    Button {
                        auth.resetPassword { _ in }
                    } label: {
                        Text("¿Olvidaste tu contraseña?")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .offset(y: -32)

                Spacer()
            }
        }
        .alert("Error de inicio de sesión", isPresented: Binding(
            get: { auth.errorMessage != nil },
            set: { if !$0 { auth.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                auth.errorMessage = nil
            }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView().environmentObject(AuthViewModel())
    }
}

struct EmailFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
#if canImport(UIKit)
        content.autocapitalization(.none).keyboardType(.emailAddress)
#else
        content
#endif
    }
}

