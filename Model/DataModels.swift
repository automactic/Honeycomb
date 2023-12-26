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
class Server: CustomStringConvertible {
    let name: String
    let url: URL
    let username: String
    var isActive: Bool
    let sessionID: String
    let previewToken: String
    
    init(name: String, url: URL, username: String, isActive: Bool, sessionID: String, previewToken: String) {
        self.name = name
        self.url = url
        self.username = username
        self.isActive = isActive
        self.sessionID = sessionID
        self.previewToken = previewToken
    }
    
    var description: String {
        let hostname = url.host() ?? "hostname"
        if let port = url.port {
            return "\(username)@\(hostname):\(port)"
        } else {
            return "\(username)@\(hostname)"
        }
    }
}
