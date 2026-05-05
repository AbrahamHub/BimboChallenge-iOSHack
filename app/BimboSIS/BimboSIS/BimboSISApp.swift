//
//  BimboSISApp.swift
//  BimboSIS
//
//  Created by Abraham Castañeda Quintero on 05/05/26.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct BimboSISApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var connectivity = ConnectivityViewModel()

    init() {
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isSignedIn {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(authVM)
            .environmentObject(connectivity)
        }
        .modelContainer(sharedModelContainer)
    }
}
