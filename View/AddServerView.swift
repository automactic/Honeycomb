//
//  AddServerView.swift
//  Honeycomb
//
//  Created by Chris Li on 11/23/23.
//

import Combine
import SwiftData
import SwiftUI
import WidgetKit

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddServerViewModel()
    
    var body: some View {
        Form {
            server
            if viewModel.serverConfig?.authMode == .passwordAccess {
                credential
            }
        }
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .animation(.default, value: viewModel.serverConfig)
        .navigationTitle("Add Server")
        .safeAreaInset(edge: .bottom) { signIn }
        .onChange(of: viewModel.sessionData) {
            saveSessionData()
            dismiss()
        }
    }
    
    private var server: some View {
        Section {
            TextField("http://example.com:2342", text: $viewModel.serverURL)
                .textContentType(.URL)
        } header: {
            Text("Server URL")
        } footer: {
            if viewModel.serverURL.isEmpty {
                Text("Enter the URL of your PhotoPrism instance.")
            } else if let serverConfig = viewModel.serverConfig {
                Text("Server Name: \(serverConfig.appName)")
            } else {
                Text("Invalid PhotoPrism instance URL.")
            }
        }
    }
    
    private var credential: some View {
        Section {
            TextField("username", text: $viewModel.username)
                .textContentType(.username)
            SecureField("password", text: $viewModel.password)
                .textContentType(.password)
        } header: {
            Text("Credential")
        }
    }
    
    private var signIn: some View {
        Button {
            Task { await viewModel.signIn() }
        } label: {
            HStack {
                Spacer()
                Text("Sign In").font(.title2)
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled({
            guard let serverConfig = viewModel.serverConfig else { return true }
            if serverConfig.authMode == .publicAccess {
                return false
            } else {
                return viewModel.username.isEmpty || viewModel.password.isEmpty
            }
        }())
        .padding()
        .overlay(alignment: .top) { Divider() }
        .background()
    }
    
    private func saveSessionData() {
        guard let url = URL(string: viewModel.serverURL),
              let serverConfig = viewModel.serverConfig,
              let sessionData = viewModel.sessionData else { return }
        try? modelContext.fetch(FetchDescriptor<Server>()).forEach { server in
            server.isActive = false
        }
        let server = Server(
            name: serverConfig.appName,
            url: url,
            username: sessionData.user.name,
            isActive: true,
            sessionID: sessionData.id,
            previewToken: sessionData.config.previewToken
        )
        modelContext.insert(server)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.itemCount.rawValue)
    }
}

@MainActor
private class AddServerViewModel: ObservableObject {
    @Published var serverURL: String = ""
    @Published var serverConfig: ServerConfig?
    @Published var serverConnectionError: ServerConnectionError?
    
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var sessionData: SessionData?
    @Published var signInError: SignInError?
    
    private var serverURLObserver: AnyCancellable?
    
    init() {
        serverURLObserver = $serverURL.debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink { [unowned self] serverURL in
                Task {
                    await self.getServerConfig(serverURL: serverURL)
                }
            }
    }
    
    /// Get server config from the given url string.
    /// - Parameter serverURL: the PhotoPrism instance url string user provided
    private func getServerConfig(serverURL: String) async {
        guard var url = URL(string: serverURL) else { return }
        url.append(path: ServerConfig.path)
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                serverConfig = nil
                serverConnectionError = .statusCode(response.statusCode)
            } else {
                do {
                    serverConfig = try JSONDecoder().decode(ServerConfig.self, from: data)
                    serverConnectionError = nil
                } catch {
                    serverConfig = nil
                    serverConnectionError = .invalidJSON
                }
            }
        } catch {
            serverConfig = nil
            serverConnectionError = .transport(error.localizedDescription)
        }
    }
    
    /// Attempt to sign in to the PhotoPrism instance
    func signIn() async {
        guard var url = URL(string: serverURL), let serverConfig else { return }
        url.append(path: SessionData.path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        switch serverConfig.authMode {
        case .publicAccess:
            request.httpBody = try? JSONSerialization.data(withJSONObject: [:])
        case .passwordAccess:
            let payload = ["username": username, "password": password]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                let responseData = try? JSONDecoder().decode(APIError.self, from: data)
                signInError = .unauthorized(responseData?.error ?? "Unauthorized")
            } else {
                do {
                    self.sessionData = try PhotoPrismJSONDecoder().decode(SessionData.self, from: data)
                } catch {
                    self.signInError = .invalidJSON
                }
            }
        } catch {
            signInError = .transport(error.localizedDescription)
        }
    }
}

private enum ServerConnectionError: Error {
    case transport(String)
    case statusCode(Int)
    case invalidJSON
}

private enum SignInError: Error {
    case transport(String)
    case unauthorized(String)
    case invalidJSON
}

#Preview {
    NavigationStack {
        AddServerView()
    }
}
