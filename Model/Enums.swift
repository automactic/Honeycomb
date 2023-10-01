//
//  Enums.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

enum ImageURLSuffix: String {
    case tile50 = "tile_50"
    case tile100 = "tile_100"
    case tile224 = "tile_224"
    case tile500 = "tile_500"
    case fit720 = "fit_720"
    case fit2048 = "fit_2048"
}

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

enum PhotosContent {
    case all
}

enum PhotoType: String, Codable {
    case image, video, live
}
