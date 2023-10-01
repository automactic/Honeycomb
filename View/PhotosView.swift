//
//  PhotosView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct PhotosView: View {
    init(content: PhotosContent) {
//        _viewModel = State(initialValue: PhotosViewModel(contentMode: contentMode))
    }
    
    var body: some View {
        ScrollView {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    PhotosView(content: .all)
}
