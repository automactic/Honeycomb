//
//  GalleryView.swift
//  Honeycomb
//
//  Created by Chris Li on 10/2/23.
//

import SwiftUI
import UIKit

struct GalleryView: View {
    @Environment(PhotosViewModel.self) private var viewModel
    @State private var photo: Photo
        
    init(photo: Photo) {
        _photo = State(initialValue: photo)
    }
    
    var body: some View {
        TabView(selection: $photo) {
            ForEach(viewModel.photos, id: \.self) { photo in
                ImageViewer(photo: photo)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                PhotoDescription(photo: photo)
                CarouselView(photo: $photo)
            }
        }
    }
}

struct PhotoDescription: View {
    let photo: Photo
    
    var body: some View {
        Group {
            if photo.description.isEmpty {
                Text("No Description")
            } else {
                Text(photo.description)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .padding(2)
    }
}

struct CarouselView: View {
    @Binding var photo: Photo
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PhotosViewModel.self) private var viewModel
    
    private let cornerRadius = 4.0
    private let highlightLineWidth = 3.0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(viewModel.photos) { photo in
                        Button {
                            withAnimation {
                                self.photo = photo
                            }
                        } label: {
                            AsyncImage(url: DataSource.makeImageURL(hash: photo.hash, suffix: .tile224)) { image in
                                image.resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: thumbImageDimension, height: thumbImageDimension)
                            .overlay {
                                if self.photo.id == photo.id {
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                                        .stroke(Color.blue, lineWidth: highlightLineWidth)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .frame(height: thumbImageDimension + highlightLineWidth * 2)
            }
            .scrollIndicators(.never)
            .onChange(of: photo, initial: true) {
                withAnimation {
                    proxy.scrollTo(photo.id, anchor: .center)
                }
            }
        }
    }
    
    var thumbImageDimension: CGFloat {
        horizontalSizeClass == .regular ? 112 : 56
    }
}

struct ImageViewer: UIViewControllerRepresentable {
    let photo: Photo
    
    func makeUIViewController(context: Context) -> some UIViewController {
        ImageViewerController(photo: photo)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class ImageViewerController: UIViewController, UIScrollViewDelegate {
    let photo: Photo
    let scrollView = UIScrollView()
    let imageView = UIImageView()
    
    lazy var topConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
    lazy var bottomConstraint = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
    lazy var leftConstraint = imageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor)
    lazy var rightConstraint = scrollView.rightAnchor.constraint(equalTo: imageView.rightAnchor)
    
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = scrollView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
        
        guard let url = DataSource.makeImageURL(hash: photo.hash, suffix: .fit2048) else { return }
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data else { return }
            DispatchQueue.main.async {
                guard let image = UIImage(data: data) else { return }
                self.imageView.image = image
                self.updateMinZoomScale(size: self.scrollView.frame.size, imageSize: image.size)
                self.updateConstraints(size: self.scrollView.frame.size)
            }
        }.resume()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let image = imageView.image else { return }
        updateMinZoomScale(size: size, imageSize: image.size)
        updateConstraints(size: size)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints(size: scrollView.frame.size)
    }
    
    /// Update min zoom scale of the scrollView
    /// - Parameters:
    ///   - size: size of scroll view's frame
    ///   - imageSize: resolution of the image
    private func updateMinZoomScale(size: CGSize, imageSize: CGSize) {
        let minimumZoomScale = min(
            (size.width - scrollView.adjustedContentInset.left
             - scrollView.adjustedContentInset.right) / imageSize.width,
            (size.height - scrollView.adjustedContentInset.top
             - scrollView.adjustedContentInset.bottom) / imageSize.height,
            1
        )
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.zoomScale = minimumZoomScale
    }
    
    /// Update imageView constraints, so that the image view is centered
    /// - Parameter size: size of scroll view's frame
    private func updateConstraints(size: CGSize) {
        guard let image = imageView.image else { return }
        
        let yOffset = max(
            (size.height - image.size.height * scrollView.zoomScale
             - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom) / 2,
            0
        )
        let xOffset = max(
            (size.width - image.size.width * scrollView.zoomScale
             - scrollView.adjustedContentInset.left - scrollView.adjustedContentInset.right) / 2,
            0
        )
        
        topConstraint.constant = yOffset
        bottomConstraint.constant = yOffset
        leftConstraint.constant = xOffset
        rightConstraint.constant = xOffset
        view.layoutIfNeeded()
    }
}
