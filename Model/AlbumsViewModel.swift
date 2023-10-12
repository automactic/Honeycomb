//
//  AlbumsViewModel.swift
//  Honeycomb
//
//  Created by Chris Li on 10/8/23.
//

import Foundation

@Observable
class AlbumsViewModel: DataSource {
    var searchText = ""
    private(set) var allPagesLoaded = false
    private(set) var isLoading = false
    private(set) var albums = [Album]()
    
    @ObservationIgnored private let tab: Tab
    @ObservationIgnored private let count = 120
    
    init(tab: Tab) {
        self.tab = tab
        super.init()
    }
    
    private func get(offset: Int) async throws -> [Album] {
        defer { isLoading = false }
        isLoading = true
        
        var queryItems = [
            URLQueryItem(name: "count", value: "100"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        if !searchText.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: searchText))
        }
        switch tab {
        case .calendar:
            queryItems += [
                URLQueryItem(name: "type", value: "month"),
                URLQueryItem(name: "order", value: "newest")
            ]
        case .folders:
            queryItems += [
                URLQueryItem(name: "type", value: "folder"),
                URLQueryItem(name: "order", value: "name")
            ]
        default:
            break
        }
        
        return try await super.get(path: "albums", queryItems: queryItems)
    }
    
    func reload() async {
        do {
            allPagesLoaded = false
            albums = try await get(offset: 0)
            allPagesLoaded = albums.isEmpty
        } catch {
            
        }
    }
    
    func loadNext() async {
        guard !allPagesLoaded else { return }
        do {
            let page = try await get(offset: albums.count)
            if page.isEmpty {
                allPagesLoaded = true
            } else {
                albums += page
            }
        } catch {
            
        }
    }
}
