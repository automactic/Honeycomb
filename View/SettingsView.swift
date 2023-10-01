//
//  SettingsView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageKeys.serverURL) private var serverURL = ""
    @AppStorage(StorageKeys.sessionID) private var sessionID: String?
    @AppStorage(StorageKeys.previewToken) private var previewToken: String?
    
    var body: some View {
        Form {
            Section {
                Attribute(title: "Server", detail: serverURL)
            }
            Section {
                Button("Sign Out", role: .destructive) {
                    sessionID = nil
                    previewToken = nil
                }
            }
        }.navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
