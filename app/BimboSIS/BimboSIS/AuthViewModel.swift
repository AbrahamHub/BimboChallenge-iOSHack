import Foundation
import Combine
import FirebaseAuth

final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var isLoading: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        isSignedIn = Auth.auth().currentUser != nil
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isSignedIn = (user != nil)
            }
        }
    }

    deinit {
        if let h = handle { Auth.auth().removeStateDidChangeListener(h) }
    }

    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Ingresa correo y contraseña"
            successMessage = nil
            return
        }
        isLoading = true
        AuthService.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.errorMessage = nil
                    self?.successMessage = "Inicio de sesión exitoso"
                case .failure(let err):
                    self?.successMessage = nil
                    self?.errorMessage = err.localizedDescription
                }
            }
        }
    }

    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Ingresa correo y contraseña"
            successMessage = nil
            return
        }
        isLoading = true
        AuthService.shared.signUp(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.errorMessage = nil
                    self?.successMessage = "Cuenta creada correctamente"
                case .failure(let err):
                    self?.successMessage = nil
                    self?.errorMessage = err.localizedDescription
                }
            }
        }
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
            successMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty else { errorMessage = "Ingresa tu correo"; completion(false); return }
        AuthService.shared.sendPasswordReset(email: email) { [weak self] error in
            DispatchQueue.main.async {
                if let err = error { self?.errorMessage = err.localizedDescription; completion(false) } else { completion(true) }
            }
        }
    }
}
