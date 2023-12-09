//
//  SettingsView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]
    @State private var isAddingNewServer = false
    
    var body: some View {
        List {
            Section("Servers") {
                ForEach(servers) { server in
                    NavigationLink(value: server) {
                        Text(server.description)
                    }
                }
                Button("Add New Server") {
                    isAddingNewServer = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationDestination(for: Server.self) { server in
            Form {
                Section {
                    Text("Server").badge(server.url.absoluteString)
                }
                Section {
                    Button("Sign Out", role: .destructive) {
                        modelContext.delete(server)
                    }
                }
            }
            .navigationTitle(server.description)
            .navigationBarTitleDisplayMode(.inline)
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
