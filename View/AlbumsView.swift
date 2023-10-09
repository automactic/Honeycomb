//
//  AlbumsView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/8/23.
//

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
                AlbumsGridView()
            }
        }
        .autocorrectionDisabled()
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(viewModel)
        .navigationDestination(for: Album.self) { Text($0.title) }
        .navigationTitle(tab.name)
        .searchable(text: $viewModel.searchText)
        .textInputAutocapitalization(.never)
        .toolbarRole(.browser)
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                LoadingView().padding()
            }
        }
    }
}

struct AlbumsGridView: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(AlbumsViewModel.self) private var viewModel
    @State private var taskID: UUID?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 250), spacing: 10)], spacing: 10) {
                ForEach(viewModel.albums) { album in
                    NavigationLink(value: album) {
                        AlbumView(album: album)
                    }.buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .refreshable {
            Task { await viewModel.reload() }
        }
        .task(id: viewModel.searchText) {
            print(isSearching)
            guard isSearching || viewModel.albums.isEmpty else { return }
            await viewModel.reload()
        }
    }
}

struct AlbumView: View {
    let album: Album
    
    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: DataSource.makeImageURL(hash: album.thumb, suffix: .tile224)) { image in
                image.resizable().aspectRatio(1, contentMode: .fill)
            } placeholder: {
                Color.clear.overlay {
                    ProgressView()
                }
            }.aspectRatio(1, contentMode: .fill)
            Text(album.title).font(.caption).lineLimit(1).padding(4)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        AlbumsView(tab: .folders)
    }
}
