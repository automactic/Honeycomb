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
        .toolbarRole(.browser)
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
    @State private var scrollPosition: String?
    @State private var taskID: UUID?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.photos) { photo in
                    GeometryReader { geometry in
                        NavigationLink(value: photo) {
                            ThumbnailView(
                                url: DataSource.makeImageURL(hash: photo.hash, suffix: .tile500), size: geometry.size
                            )
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .task(priority: .low) {
                        guard photo.id == viewModel.photos.last?.id else { return }
                        await viewModel.loadNext()
                    }
                }
            }.scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .center)
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

struct ThumbnailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var image: UIImage?
    @State private var failed = false
    
    let url: URL?
    let size: CGSize
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else if failed {
                Color(uiColor: .secondarySystemGroupedBackground).overlay {
                    Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
                }
            } else {
                Color.clear.overlay {
                    ProgressView()
                }
            }
        }
        .task(id: size, priority: .medium) {
            guard let url = url else { return }
            do {
                let fetchDescriptor = FetchDescriptor<CachedImage>(predicate: #Predicate { cachedImage in
                    cachedImage.url == url.absoluteString
                })
                let transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                if let cachedImage = try? modelContext.fetch(fetchDescriptor).first {
                    cachedImage.lastUsed = Date()
                    image = await UIImage(data: cachedImage.data)?
                        .byPreparingThumbnail(ofSize: size.applying(transform))
                } else {
                    let data = try await URLSession.shared.data(from: url).0
                    modelContext.insert(CachedImage(url: url.absoluteString, data: data, lastUsed: Date()))
                    image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: size.applying(transform))
                }
            } catch {
                failed = true
            }
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
