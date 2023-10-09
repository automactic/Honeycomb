//
//  Enums.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

enum AuthMode: String, Codable {
    case publicAccess = "public"
    case passwordAccess = "password"
}

enum ImageURLSuffix: String, Codable {
    case tile50 = "tile_50"
    case tile100 = "tile_100"
    case tile224 = "tile_224"
    case tile500 = "tile_500"
    case fit720 = "fit_720"
    case fit2048 = "fit_2048"
}

enum Tab: String, CaseIterable, Identifiable {
    case browse
    case favorite
    case folders
    case settings
    
    var id: String {
        rawValue
    }
    
    var name: String {
        switch self {
        case .browse:
            "Browse"
        case .favorite:
            "Favorite"
        case .folders:
            "Folders"
        case .settings:
            "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .browse:
            "photo.on.rectangle.angled"
        case .favorite:
            "heart"
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
