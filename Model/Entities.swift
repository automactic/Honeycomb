//
//  Entities.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation
import SwiftData

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

@Model
class CachedImage {
    @Attribute(.unique) let url: String
    let data: Data
    let size: Int
    var lastUsed: Date
    
    init(url: String, data: Data, lastUsed: Date) {
        self.url = url
        self.data = data
        self.size = data.count
        self.lastUsed = lastUsed
    }
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

struct ServerConfig: Codable {
    let authMode: AuthMode
    let name: String
    let siteAuthor: String
}

struct SessionData: Codable {
    let id: String
    let config: SessionConfig
    
    struct SessionConfig: Codable {
        let previewToken: String
    }
}
