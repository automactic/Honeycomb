//
//  Widget.swift
//  Widget
//
//  Created by Chris Li on 12/10/23.
//

import AppIntents
import WidgetKit
import SwiftData
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
        
        @Parameter(title: "Item", default: .photos)
        var item: CountableItem
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
            var fetchDescriptor = FetchDescriptor<Server>()
//            fetchDescriptor.predicate = #Predicate<Server> { configuration.server.id == $0.id }
            do {
                let container = try ModelContainer(for: Server.self)
                guard let server = try ModelContext(container).fetch(fetchDescriptor).first else {
                    return Entry(date: Date(), count: -2)
                }
                let config = try await ServerConfig.get(server: server)
                switch configuration.item {
                case .photos:
                    return Entry(date: Date(), count: config.count.photos)
                case .videos:
                    return Entry(date: Date(), count: config.count.videos)
                case .favorites:
                    return Entry(date: Date(), count: config.count.favorites)
                }
            } catch {
                print(error)
                return Entry(date: Date(), count: -1)
            }
        }
        
        func timeline(for configuration: ConfigIntent, in context: Context) async -> Timeline<Entry> {
            let entries = [await snapshot(for: configuration, in: context)]
            guard let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) else {
                return Timeline(entries: entries, policy: .never)
            }
            return Timeline(entries: entries, policy: .after(oneHourLater))
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
