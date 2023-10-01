//
//  PhotosView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct PhotosView: View {
    @SceneStorage(StorageKeys.photosDisplayMode) private var displayMode: PhotosDisplayMode = .mediumGrid
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: PhotosViewModel
    
    init(content: PhotosContent) {
        _viewModel = State(initialValue: PhotosViewModel(content: content))
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.photos) { photo in
                    Button {
                        
                    } label: {
                        LazyImage(url: DataSource.makeImageURL(hash: photo.hash, suffix: .tile500))
                            .aspectRatio(1, contentMode: .fill)
                    }.task {
                        guard photo.id == viewModel.photos.last?.id else { return }
                        await viewModel.loadNext()
                    }
                }
            }
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                    Text("Loading ...")
                } else {
                    Label("\(viewModel.photos.count.formatted()) photos", systemImage: "photo.stack")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
            .background { Color(uiColor: .secondarySystemBackground) }
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
        .animation(.default, value: displayMode)
        .searchable(text: $viewModel.searchText)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .toolbarRole(.browser)
        .toolbar {
            Picker("Display Mode", selection: $displayMode) {
                ForEach(PhotosDisplayMode.allCases) { displayMode in
                    Label(displayMode.name, systemImage: displayMode.icon).tag(displayMode)
                }
            }
        }
        .onChange(of: viewModel.searchText) {
            Task { await viewModel.reload() }
        }
        .refreshable {
            await viewModel.reload()
        }
        .task {
            guard viewModel.photos.isEmpty else { return }
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

struct LazyImage: View {
    @State private var data: Data?
    @State private var failed = false
    
    let url: URL?
    
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable()
            } else {
                VStack {
                    Spacer()
                    if failed {
                        Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
                    } else {
                        ProgressView()
                    }
                    Spacer()
                }
            }
        }.task {
            guard let url = url else { return }
            do {
                data = try await URLSession.shared.data(from: url).0
            } catch {
                failed = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotosView(content: .all)
    }
}
