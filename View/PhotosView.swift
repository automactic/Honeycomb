//
//  PhotosView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI
import SwiftData

struct PhotosView: View {
    @SceneStorage(StorageKeys.photosDisplayMode) private var displayMode: PhotosDisplayMode = .mediumGrid
    @State private var viewModel: PhotosViewModel
    
    init(tab: Tab) {
        _viewModel = State(initialValue: PhotosViewModel(tab: tab))
    }
    
    var body: some View {
        Group {
            if viewModel.photos.isEmpty, viewModel.allPagesLoaded {
                ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle.angled")
            } else {
                PhotosGridView()
            }
        }
        .autocorrectionDisabled()
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(viewModel)
        .navigationDestination(for: Photo.self) { GalleryView(photo: $0).environment(viewModel) }
        .searchable(text: $viewModel.searchText)
        .textInputAutocapitalization(.never)
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                LoadingView().padding()
            }
        }
        .toolbar {
            Picker("Display Mode", selection: $displayMode) {
                ForEach(PhotosDisplayMode.allCases) { displayMode in
                    Label(displayMode.name, systemImage: displayMode.icon).tag(displayMode)
                }
            }
        }
    }
}

struct PhotosGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isSearching) private var isSearching
    @Environment(PhotosViewModel.self) private var viewModel
    @SceneStorage(StorageKeys.photosDisplayMode) private var displayMode: PhotosDisplayMode = .mediumGrid
    @State private var taskID: UUID?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.photos) { photo in
                    GeometryReader { geometry in
                        NavigationLink(value: photo) {
                            ThumbnailView(hash: photo.hash, suffix: .tile500, size: geometry.size)
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .task(priority: .low) {
                        guard photo.id == viewModel.photos.last?.id else { return }
                        await viewModel.loadNext()
                    }
                }
            }
        }
        .refreshable {
            Task { await viewModel.reload() }
        }
        .task(id: viewModel.searchText) {
            guard isSearching || viewModel.photos.isEmpty else { return }
            await viewModel.reload()
        }
    }
    
    var columns: [GridItem] {
        switch (displayMode, horizontalSizeClass) {
        case (.largeGrid, .regular):
            [GridItem(.adaptive(minimum: 250, maximum: 325), spacing: 2)]
        case (.mediumGrid, .regular):
            [GridItem(.adaptive(minimum: 175, maximum: 250), spacing: 2)]
        case (.smallGrid, .regular):
            [GridItem(.adaptive(minimum: 125, maximum: 200), spacing: 2)]
        case (.largeGrid, .compact):
            Array(repeating: GridItem(.flexible(minimum: 150, maximum: 225), spacing: 2), count: 2)
        case (.mediumGrid, .compact):
            Array(repeating: GridItem(.flexible(minimum: 100, maximum: 150), spacing: 2), count: 3)
        case (.smallGrid, .compact):
            Array(repeating: GridItem(.flexible(minimum: 75, maximum: 125), spacing: 2), count: 4)
        default:
            []
        }
    }
}

#Preview {
    TabView {
        NavigationStack {
            PhotosView(tab: .browse)
        }
    }
}
