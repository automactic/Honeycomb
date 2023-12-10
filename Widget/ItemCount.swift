//
//  Widget.swift
//  Widget
//
//  Created by Chris Li on 12/10/23.
//

import WidgetKit
import SwiftUI

struct ItemCountWidget: Widget {
    let kind: String = "Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ItemCountTimelineProvider()) { entry in
            VStack(alignment: .trailing) {
                HStack(alignment: .center) {
                    Image(systemName: "photo.circle").imageScale(.large).foregroundStyle(Color.blue)
                    Spacer()
                    Text("Photos").font(.headline)
                }
                Text("PhotoPrism").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(entry.count.formatted())
                    .font(.system(.title, design: .rounded)).fontWeight(.semibold)
            }.containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Item Count")
        .description("Display item count in your PhotoPrism instance, such as photos, videos or favorites.")
    }
}

struct ItemCountTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ItemCountEntry {
        ItemCountEntry(date: Date(), count: 1024)
    }

    func getSnapshot(in context: Context, completion: @escaping (ItemCountEntry) -> Void) {
        let entry = ItemCountEntry(date: Date(), count: 1024)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [ItemCountEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ItemCountEntry(date: Date(), count: 1024)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ItemCountEntry: TimelineEntry {
    let date: Date
    let count: Int
}

#Preview(as: .systemSmall) {
    ItemCountWidget()
} timeline: {
    ItemCountEntry(date: Date(), count: 1024)
    ItemCountEntry(date: Date(), count: 10468)
}
