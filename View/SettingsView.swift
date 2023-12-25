//
//  SettingsView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftData
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]
    @State private var isAddingNewServer = false
    
    var body: some View {
        List {
            Section("Servers") {
                ForEach(servers) { server in
                    NavigationLink(value: server) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(server.name)
                                Text(server.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if server.isActive {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                }
                Button("Add New Server") {
                    isAddingNewServer = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationDestination(for: Server.self) { server in
            ServerDetailView(server: server)
        }
        .sheet(isPresented: $isAddingNewServer) {
            NavigationStack {
                AddServerView().toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isAddingNewServer = false
                        }
                    }
                }
            }
        }
    }
}

private struct ServerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    
    let server: Server
    
    var body: some View {
        Form {
            Section {
                Text("Server").badge(server.url.absoluteString)
                Text("Name").badge(server.name)
                Text("Username").badge(server.username)
            }
            Section {
                if server.isActive {
                    HStack {
                        Text("Active Server")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                } else {
                    Button("Set As Active") {
                        try? modelContext.fetch(FetchDescriptor<Server>()).forEach { server in
                            server.isActive = false
                        }
                        server.isActive = true
                        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.itemCount.rawValue)
                    }
                }
            }
            Section {
                Button("Sign Out", role: .destructive) {
                    modelContext.delete(server)
                }
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: Server.self, configurations: config)
        return NavigationStack {
            SettingsView()
        }.modelContainer(container)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
