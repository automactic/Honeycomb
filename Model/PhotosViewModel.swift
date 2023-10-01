//
//  PhotosViewModel.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

@Observable
class PhotosViewModel: DataSource {
    let content: PhotosContent
    var searchText = ""
    
    private(set) var allPagesLoaded = false
    private(set) var isLoading = false
    private(set) var photos = [Photo]()
    
    private let count = 120
    private var offset: Int = 0
    private var allPagesRetrieved = false
    
    init(content: PhotosContent) {
        self.content = content
        super.init()
    }
    
    private func get(offset: Int) async throws -> [Photo] {
        defer { isLoading = false }
        isLoading = true
        
        var queryItems = [
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "order", value: "newest"),
            URLQueryItem(name: "merged", value: "true")
        ]
        if !searchText.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: searchText))
        }
        
        return try await super.get(path: "photos", queryItems: queryItems)
    }
    
    func reload() async {
        do {
            allPagesLoaded = false
            photos = try await get(offset: 0)
            offset = count
        } catch {
            
        }
    }
    
    func loadNext() async {
        guard !allPagesLoaded else { return }
        do {
            var page = try await get(offset: offset)
            if page.isEmpty {
                allPagesLoaded = true
            } else {
                if photos.last?.uid == page.first?.uid {
                    let firstPhoto = page.removeFirst()
                    var lastPhoto = photos.removeLast()
                    lastPhoto.files.append(contentsOf: firstPhoto.files)
                    photos.append(lastPhoto)
                }
                photos.append(contentsOf: page)
                offset += count
            }
        } catch {
            
        }
    }
}
