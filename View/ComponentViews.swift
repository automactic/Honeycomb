//
//  ComponentViews.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftData
import SwiftUI

struct AttributeRow: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail).foregroundStyle(.secondary)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Loading ...")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding()
        .background(Material.bar)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(radius: 0.5)
    }
}

struct ThumbnailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var image: UIImage?
    @State private var failed = false
    
    let url: URL?
    let size: CGSize
    
    init(hash: String, suffix: ImageURLSuffix, size: CGSize) {
        self.url = DataSource.makeImageURL(hash: hash, suffix: .tile224)
        self.size = size
    }
    
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
