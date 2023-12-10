//
//  Enums.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation



enum ImageURLSuffix: String, Codable {
    case tile50 = "tile_50"
    case tile100 = "tile_100"
    case tile224 = "tile_224"
    case tile500 = "tile_500"
    case fit720 = "fit_720"
    case fit2048 = "fit_2048"
}

enum Tab: RawRepresentable, CaseIterable, Hashable, Identifiable {
    static var allCases: [Tab] = [.browse, .favorite, .calendar, .folders, .settings]
    
    case album(id: String)
    case browse
    case favorite
    case calendar
    case labels
    case folders
    case settings
    
    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        switch parts.first {
        case "album":
            guard let id = parts.last else { return nil }
            self = .album(id: String(id))
        case "browse":
            self = .browse
        case "favorite":
            self = .favorite
        case "calendar":
            self = .calendar
        case "labels":
            self = .labels
        case "folders":
            self = .folders
        case "settings":
            self = .settings
        default:
            return nil
        }
    }
    
    var id: String {
        rawValue
    }
    
    var rawValue: String {
        switch self {
        case.album(let id):
            "album.\(id)"
        case .browse:
            "browse"
        case .favorite:
            "favorite"
        case .calendar:
            "calendar"
        case .labels:
            "labels"
        case .folders:
            "folders"
        case .settings:
            "settings"
        }
   }
    
    var name: String {
        switch self {
        case .album:
            "Album"
        case .browse:
            "Browse"
        case .favorite:
            "Favorite"
        case .calendar:
            "Calendar"
        case .labels:
            "Labels"
        case .folders:
            "Folders"
        case .settings:
            "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .album:
            "album"
        case .browse:
            "photo.on.rectangle.angled"
        case .favorite:
            "heart"
        case .calendar:
            "calendar"
        case .labels:
            "tag"
        case .folders:
            "folder"
        case .settings:
            "gear"
        }
    }
}

enum PhotosContent {
    case all
}

enum PhotosDisplayMode: String, CaseIterable, Identifiable {
    case largeGrid, mediumGrid, smallGrid
    
    var id: String {
        rawValue
    }
    
    var name: String {
        switch self {
        case .largeGrid:
            "Large"
        case .mediumGrid:
            "Medium"
        case .smallGrid:
            "Small"
        }
    }
    
    var icon: String {
        switch self {
        case .largeGrid:
            "square.inset.filled"
        case .mediumGrid:
            "square.grid.2x2.fill"
        case .smallGrid:
            "square.grid.3x3.fill"
        }
    }
}

enum PhotoType: String, Codable {
    case image, video, live, vector, animated, raw
}
