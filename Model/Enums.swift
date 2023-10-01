//
//  Enums.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

enum LibraryItem: String, CaseIterable, Identifiable {
    case browse
    case settings
    
    var id: String {
        rawValue
    }
    
    var name: String {
        switch self {
        case .browse:
            "Browse"
        case .settings:
            "Settings"
        }
    }
    
    var imageName: String {
        switch self {
        case .browse:
            "photo.on.rectangle.angled"
        case .settings:
            "gear"
        }
    }
}
