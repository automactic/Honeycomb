//
//  App.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI
import SwiftData

@main
struct Honeycomb: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    @AppStorage(StorageKeys.sessionID) private var sessionID: String?
    @State private var isPresentingSignIn = false
    
    var body: some View {
        ContentView()
            .onAppear {
                isPresentingSignIn = sessionID == nil
            }
            .sheet(isPresented: $isPresentingSignIn) {
                SignInView().interactiveDismissDisabled()
            }
    }
}
