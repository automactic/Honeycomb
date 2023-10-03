//
//  GalleryView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/2/23.
//

import SwiftUI

struct GalleryView: UIViewControllerRepresentable {
    let photo: Photo
    
    func makeUIViewController(context: Context) -> GalleryViewController {
        GalleryViewController()
    }
    
    func updateUIViewController(_ controller: GalleryViewController, context: Context) {
        
    }
}

class GalleryViewController: UIViewController {
    let pageViewController = UIPageViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageViewController.view.backgroundColor  = .systemBlue
        
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: pageViewController.view.topAnchor),
            view.leftAnchor.constraint(equalTo: pageViewController.view.leftAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: pageViewController.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: pageViewController.view.rightAnchor)
        ])
        pageViewController.didMove(toParent: self)
    }
}

struct GalleryView2: View {
    @Environment(PhotosViewModel.self) private var viewModel
    @State private var photo: Photo
        
    init(photo: Photo) {
        _photo = State(initialValue: photo)
    }
    
    var body: some View {
        TabView(selection: $photo) {
            ForEach(viewModel.photos, id: \.self) { photo in
                LazyImage(url: DataSource.makeImageURL(hash: photo.hash, suffix: .fit2048)).tag(photo)
            }
        }
        .tabViewStyle(.page)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
