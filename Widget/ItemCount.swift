//
//  Widget.swift
//  Widget
//
//  Created by Chris Li on 12/10/23.
//

import AppIntents
import WidgetKit
import SwiftUI

struct ItemCountWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "dev.chrisli.honeycomb.item-count",
            intent: ConfigIntent.self,
            provider: TimelineProvider()
        ) { entry in
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
        .supportedFamilies([.systemSmall])
    }
    
    // MARK: Config
    
    struct ConfigIntent: WidgetConfigurationIntent {
        static var title: LocalizedStringResource = "Customize Widget"

        @Parameter(title: "Server", optionsProvider: ServerOptionsProvider())
        var name: String
        
        @Parameter(title: "Item", default: .photos)
        var item: CountableItem
    }
    
    struct ServerOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            ["demo", "diskstation"]
        }
    }
    
    enum CountableItem: String, AppEnum {
        case photos, videos, favorites
        
        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countable Item")
        static var caseDisplayRepresentations: [CountableItem: DisplayRepresentation] = [
            .photos: DisplayRepresentation(title: "Photos"),
            .videos: DisplayRepresentation(title: "Videos"),
            .favorites: DisplayRepresentation(title: "Favorites")
        ]
    }
    
    // MARK: Timeline
    
    struct TimelineProvider: AppIntentTimelineProvider {
        func placeholder(in context: Context) -> Entry {
            Entry(date: Date(), count: 1024)
        }
        
        func snapshot(for configuration: ConfigIntent, in context: Context) async -> Entry {
            Entry(date: Date(), count: 1024)
        }
        
        func timeline(for configuration: ConfigIntent, in context: Context) async -> Timeline<Entry> {
            var entries: [Entry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = Entry(date: Date(), count: 1024)
                entries.append(entry)
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            return timeline
        }
    }

    struct Entry: TimelineEntry {
        let date: Date
        let count: Int
    }
}

#Preview(as: .systemSmall) {
    ItemCountWidget()
} timeline: {
    ItemCountWidget.Entry(date: Date(), count: 1024)
    ItemCountWidget.Entry(date: Date(), count: 10468)
}
