//
//  AlbumsView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/8/23.
//

import SwiftData
import SwiftUI

struct AlbumsView: View {
    @State private var viewModel: AlbumsViewModel
    
    let tab: Tab
    
    init(tab: Tab) {
        self.tab = tab
        _viewModel = State(initialValue: AlbumsViewModel(tab: tab))
    }
    
    var body: some View {
        Group {
            if viewModel.albums.isEmpty, viewModel.allPagesLoaded {
                ContentUnavailableView("No Folders", systemImage: tab.icon)
            } else {
                AlbumGridView(tab: tab)
            }
        }
        .autocorrectionDisabled()
        .environment(viewModel)
        .navigationDestination(for: Album.self) { PhotosView(tab: Tab.album(id: $0.id)).navigationTitle($0.title) }
        .navigationTitle(tab.name)
        .searchable(text: $viewModel.searchText)
        .textInputAutocapitalization(.never)
        .toolbarRole(.browser)
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                LoadingView().padding()
            }
        }
        .onChange(of: viewModel.searchText) {
            Task {
                await viewModel.reload()
            }
        }
        .refreshable {
            Task { await viewModel.reload() }
        }
        .task {
            guard viewModel.albums.isEmpty else { return }
            await viewModel.reload()
        }
    }
}

private struct AlbumGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AlbumsViewModel.self) private var viewModel
    
    let tab: Tab
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(viewModel.albums) { album in
                        NavigationLink(value: album) {
                            AlbumCell(album: album, tab: tab)
                        }
                        .buttonStyle(.plain)
                        .task(priority: .low) {
                            guard album.id == viewModel.albums.last?.id else { return }
                            await viewModel.loadNext()
                        }
                    }
                }
            }.contentMargins(.horizontal, geometry.size.width > 400 ? 20 : 16, for: .scrollContent)
        }
    }
    
    private var columns: [GridItem] {
        switch horizontalSizeClass {
        case .regular:
            [GridItem(.adaptive(minimum: 175, maximum: 225), spacing: spacing)]
        case .compact:
            [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: spacing)]
        default:
            []
        }
    }
    
    private var spacing: CGFloat {
        horizontalSizeClass == .regular ? 15 : 10
    }
}

private struct AlbumCell: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let album: Album
    let tab: Tab
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ThumbnailView(hash: album.thumb, suffix: .tile224, size: geometry.size)
            }.aspectRatio(1, contentMode: .fill)
            HStack(spacing: 0) {
                if case .folders = tab, horizontalSizeClass == .regular {
                    VStack(alignment: .leading) {
                        Text(album.title).fontWeight(.medium)
                        Text(album.path)
                    }
                    Spacer()
                } else {
                    Text(album.title).fontWeight(.medium)
                }
            }.font(.caption).lineLimit(1).padding(8)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: CachedImage.self, configurations: config)
        return NavigationStack {
            AlbumsView(tab: .folders)
        }.modelContainer(container)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
