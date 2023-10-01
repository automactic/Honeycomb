//
//  Attribute.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import SwiftUI

struct Attribute: View {
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
