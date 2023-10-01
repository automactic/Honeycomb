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
    @State private var isSignInPresented = false
    
    var body: some View {
        ContentView()
            .onAppear {
                isSignInPresented = sessionID == nil
            }
            .sheet(isPresented: $isSignInPresented) {
                SignInView(isPresented: $isSignInPresented).interactiveDismissDisabled()
            }
    }
}

#Preview {
    RootView()
}
