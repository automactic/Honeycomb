//
//  Entities.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

// MARK: - API Objects

struct APIError: Codable {
    let error: String
}

struct Album: Codable, Hashable, Identifiable {
    let uid: String
    let thumb: String
    let title: String
    let location: String
    let path: String
    let createdAt: Date
    
    var id: String { uid }
}

struct File: Codable, Hashable, Identifiable {
    let uid: String
    let root: String
    let hash: String
    let size: Int64
    let primary: Bool
    let codec: String?
    let mediaType: String
    let duration: Int64?
    let width: Int?
    let height: Int?
    
    var id: String { uid }
}

struct Photo: Codable, Hashable, Identifiable {
    let uid: String
    let type: PhotoType?
    let hash: String
    let title: String
    let description: String
    let takenAt: Date
    var files: [File]
    
    var id: String { uid }
}

/// API response data model for `http://photoprism.app:2342/api/v1/config`
struct ServerConfig: Codable, Equatable {
    static let path = "api/v1/config"
    
    let authMode: AuthMode
    let name: String
    let siteAuthor: String
}

/// API response data model for `http://photoprism.app:2342/api/v1/session`
struct SessionData: Codable, Equatable {
    static let path = "api/v1/session"
    
    let id: String
    let config: SessionConfig
    let user: SessionUser
    
    struct SessionConfig: Codable, Equatable {
        let previewToken: String
    }
    
    struct SessionUser: Codable, Equatable {
        let name: String
    }
}
