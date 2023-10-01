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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SceneStorage(StorageKeys.selectedLibraryItem) private var selectedLibraryItem: LibraryItem = .browse
    @State private var isSignInPresented = false
    
    var body: some View {
        Group {
            if sessionID == nil {
                EmptyView()
            } else if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(LibraryItem.allCases, id: \.self, selection: selectedSidebarItem) { libraryItem in
                        Label(libraryItem.name, systemImage: libraryItem.icon)
                    }
                } detail: {
                    NavigationStack {
                        NavigationContent(libraryItem: selectedLibraryItem)
                    }
                }
            } else {
                TabView(selection: $selectedLibraryItem) {
                    ForEach(LibraryItem.allCases) { libraryItem in
                        NavigationStack {
                            NavigationContent(libraryItem: libraryItem)
                        }
                        .tabItem { Label(libraryItem.name, systemImage: libraryItem.icon) }
                        .tag(libraryItem)
                    }
                }
            }
        }
        .onAppear {
            isSignInPresented = sessionID == nil
        }
        .onChange(of: sessionID) { _, newValue in
            isSignInPresented = newValue == nil
        }
        .sheet(isPresented: $isSignInPresented) {
            SignInView(isPresented: $isSignInPresented).interactiveDismissDisabled()
        }
    }
    
    private var selectedSidebarItem: Binding<LibraryItem?> {
        Binding {
            selectedLibraryItem
        } set: { newValue in
            selectedLibraryItem = newValue ?? .browse
        }
    }
}

private struct NavigationContent: View {
    let libraryItem: LibraryItem
    
    var body: some View {
        switch libraryItem {
        case .browse:
            PhotosView(content: .all).navigationTitle(libraryItem.name)
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    RootView()
}
