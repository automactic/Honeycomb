//
//  SignInView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct SignInView: View {
    @AppStorage(StorageKeys.serverURL) private var serverURL = ""
    @AppStorage(StorageKeys.sessionID) private var sessionID: String?
    @AppStorage(StorageKeys.previewToken) private var previewToken: String?
    
    @Binding var isPresented: Bool
    
    @State private var serverConfig: ServerConfig?
    @State private var isRetrievingServerConfig = false
    @State private var retrieveServerConfigError: Error?
    
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var signInError: String?

    var body: some View {
        NavigationStack {
            Form {
                server
                if let serverConfig {
                    if serverConfig.authMode == .passwordAccess {
                        credentials
                    }
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
                AttributeRow(title: "Name", detail: serverConfig.name)
                AttributeRow(title: "Site Author", detail: serverConfig.siteAuthor)
            }
        } header: {
            Text("Server")
        } footer: {
            if serverURL.isEmpty {
                Text("Enter the URL of your PhotoPrism instance.")
            } else if isRetrievingServerConfig {
                HStack {
                    ProgressView()
                    Text("Connecting to server...")
                }
            } else if let retrieveServerConfigError {
                Label(
                    retrieveServerConfigError.localizedDescription,
                    systemImage: "exclamationmark.triangle.fill"
                ).symbolRenderingMode(.multicolor)
            } else if serverConfig == nil {
                Label(
                    "Unable to connect to the server or the URL is invalid.",
                    systemImage: "exclamationmark.triangle.fill"
                ).symbolRenderingMode(.multicolor)
            } else {
                Label("Connected to server", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }.task(id: serverURL) {
            defer { isRetrievingServerConfig = false }
            isRetrievingServerConfig = true
            guard var url = URL(string: serverURL) else { return }
            url.append(path: "api/v1/config")
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                serverConfig = try decoder.decode(ServerConfig.self, from: data)
            } catch {
                serverConfig = nil
                retrieveServerConfigError = error
            }
        }
    }
    
    var credentials: some View {
        Section {
            TextField("Username", text: $username).textContentType(.username)
            SecureField("Password", text: $password).textContentType(.password)
        } header: {
            Text("Credentials")
        } footer: {
            if let signInError {
                Label(signInError, systemImage: "exclamationmark.circle.fill").symbolRenderingMode(.multicolor)
            } else {
                Text("")
            }
        }
        .onChange(of: username) {
            signInError = nil
        }
        .onChange(of: password) {
            signInError = nil
        }
        .disabled(isSigningIn)
    }
    
    var signIn: some View {
        Section {
            HStack {
                Spacer()
                Button {
                    Task { await signIn() }
                } label: {
                    if isSigningIn {
                        Label(
                            title: { Text("Signing In...") },
                            icon: { ProgressView() }
                        ).padding(4)
                    } else {
                        Text("SIGN IN").padding(4)
                    }
                }.buttonStyle(.borderedProminent)
                Spacer()
            }.listRowBackground(Color.clear)
        }.disabled(isSignInDisabled)
    }
    
    private var isSignInDisabled: Bool {
        guard !serverURL.isEmpty, let serverConfig else { return true }  // disabled if server is not configured
        switch serverConfig.authMode {
        case .publicAccess:
            return false
        case .passwordAccess:
            return username.isEmpty || password.isEmpty || isSigningIn || signInError != nil
        }
    }
    
    private func signIn() async {
        defer { isSigningIn = false }
        isSigningIn = true
        
        guard var url = URL(string: serverURL) else { return }
        url.append(path: "/api/v1/session")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if serverConfig?.authMode == .passwordAccess {
                let payload = ["username": username, "password": password]
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            } else {
                request.httpBody = try JSONSerialization.data(withJSONObject: [:])
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                let responseData = try JSONDecoder().decode(APIError.self, from: data)
                signInError = responseData.error
            } else {
                let session = try JSONDecoder().decode(SessionData.self, from: data)
                sessionID = session.id
                previewToken = session.config.previewToken
                isPresented = false
            }
        } catch {
            signInError = "Unable connecting to the server"
        }
    }
}

#Preview {
    SignInView(isPresented: .constant(true))
}
