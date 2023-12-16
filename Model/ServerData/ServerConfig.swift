//
//  ServerConfig.swift
//  Honeycomb
//
//  Created by Chris Li on 12/10/23.
//

import Foundation

/// API response data model for `http://photoprism.app:2342/api/v1/config`
struct ServerConfig: Codable, Equatable {
    static let path = "api/v1/config"
    
    let authMode: AuthMode
    let name: String
    let siteAuthor: String
    let count: Count
    
    enum AuthMode: String, Codable {
        case publicAccess = "public"
        case passwordAccess = "password"
    }

    struct Count: Codable, Equatable {
        let all: Int
        let photos: Int
        let videos: Int
        let archived: Int
        let favorites: Int
        let folders: Int
    }
    
    static func get(server: Server) async throws -> ServerConfig {
        let url = server.url.appending(path: path)
        var request = URLRequest(url: url)
        request.addValue(server.sessionID, forHTTPHeaderField: "X-Session-ID")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try PhotoPrismJSONDecoder().decode(ServerConfig.self, from: data)
    }
}
