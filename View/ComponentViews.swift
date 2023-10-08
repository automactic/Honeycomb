//
//  ComponentViews.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

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
