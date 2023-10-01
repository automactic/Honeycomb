//
//  Entities.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

struct APIError: Codable {
    let error: String
}

struct ServerConfig: Codable {
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
