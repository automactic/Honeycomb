//
//  SignInView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct SignInView: View {
    @AppStorage(StorageKeys.serverURL) private var serverURL = ""
    
    @State private var serverConfig: ServerConfig?
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                server
                if serverConfig != nil {
                    credential
                    signIn
                }
            }
            .autocorrectionDisabled()
            .navigationTitle("Sign In")
            .textInputAutocapitalization(.never)
        }
    }
    
    var server: some View {
        Section {
            TextField("http://example.com:2342", text: $serverURL)
                .textContentType(.URL)
            if let serverConfig {
                Attribute(title: "Name", detail: serverConfig.name)
                Attribute(title: "Site Author", detail: serverConfig.siteAuthor)
            }
        } header: {
            Text("Server")
        } footer: {
            if serverURL.isEmpty {
                Text("Enter the URL of your PhotoPrism instance.")
            } else if serverConfig == nil {
                Label(
                    "Unable to connect to the server or the URL is invalid.",
                    systemImage: "exclamationmark.triangle.fill"
                ).symbolRenderingMode(.multicolor)
            } else {
                Label("Server URL is valid", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }.task(id: serverURL) {
            guard var url = URL(string: serverURL) else { return }
            url.append(path: "api/v1/config")
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                serverConfig = try decoder.decode(ServerConfig.self, from: data)
            } catch {
                serverConfig = nil
            }
        }
    }
    
    var credential: some View {
        Section("Credential") {
            TextField("Username", text: $username).textContentType(.username)
            SecureField("Password", text: $password).textContentType(.password)
        }
    }
    
    var signIn: some View {
        Section {
            HStack {
                Spacer()
                Button("SIGN IN") {
//                    Task { try await signIn() }
                }.buttonStyle(.borderedProminent)
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    SignInView()
}
