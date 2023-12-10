//
//  DataModels.swift
//  Honeycomb
//
//  Created by Chris Li on 12/10/23.
//

import Foundation
import SwiftData

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

@Model
class Server {
    @Attribute(.unique) let name: String
    let url: URL
    let username: String
    let sessionID: String
    let previewToken: String
    
    init(name: String, url: URL, username: String, sessionID: String, previewToken: String) {
        self.name = name
        self.url = url
        self.username = username
        self.sessionID = sessionID
        self.previewToken = previewToken
    }
}
