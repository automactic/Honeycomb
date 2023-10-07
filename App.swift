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
    @SceneStorage(StorageKeys.selectedTab) private var selectedTab: Tab = .browse
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var isSignInPresented = false
    
    var body: some View {
        Group {
            if sessionID == nil {
                EmptyView()
            } else if horizontalSizeClass == .regular {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    List(Tab.allCases, id: \.self, selection: selectedSidebarItem) { libraryItem in
                        Label(libraryItem.name, systemImage: libraryItem.icon)
                    }
                } detail: {
                    NavigationStack {
                        NavigationContent(tab: selectedTab)
                    }
                }.navigationSplitViewStyle(.prominentDetail)
            } else {
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        NavigationStack {
                            NavigationContent(tab: tab)
                        }
                        .tabItem { Label(tab.name, systemImage: tab.icon) }
                        .tag(tab)
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
    
    private var selectedSidebarItem: Binding<Tab?> {
        Binding {
            selectedTab
        } set: { newValue in
            selectedTab = newValue ?? .browse
        }
    }
}

private struct NavigationContent: View {
    let tab: Tab
    
    var body: some View {
        switch tab {
        case .browse, .favorite:
            PhotosView(tab: tab).navigationTitle(tab.name)
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    RootView()
}
