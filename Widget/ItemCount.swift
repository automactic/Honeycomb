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

struct SingleCounterWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "dev.chrisli.honeycomb.single-counter",
            intent: Configuration.self,
            provider: TimelineProvider()
        ) { entry in
            VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                    switch entry.item {
                    case .photos:
                        Image(systemName: "photo.circle").imageScale(.large).foregroundStyle(Color.blue)
                    case .videos:
                        Image(systemName: "film.circle").imageScale(.large).foregroundStyle(Color.green)
                    case .favorites:
                        Image(systemName: "star.circle").imageScale(.large).symbolRenderingMode(.multicolor)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(CountableItem.caseDisplayRepresentations[entry.item]?.title ?? "").font(.headline)
                        Text("PhotoPrism").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(entry.count.formatted()).font(.system(.title, design: .rounded)).fontWeight(.semibold)
            }.containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Counter")
        .description("A single counter of items in your PhotoPrism instance, such as photos, videos or favorites.")
        .supportedFamilies([.systemSmall])
    }
    
    // MARK: Config
    
    struct Configuration: WidgetConfigurationIntent {
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
            Entry(date: Date(), item: .photos, count: 1024)
        }
        
        func snapshot(for configuration: Configuration, in context: Context) async -> Entry {
            let fetchDescriptor = FetchDescriptor<Server>()
//            fetchDescriptor.predicate = #Predicate<Server> { configuration.server.id == $0.id }
            do {
                let container = try ModelContainer(for: Server.self)
                guard let server = try ModelContext(container).fetch(fetchDescriptor).first else {
                    return Entry(date: Date(), item: configuration.item, count: -2)
                }
                let serverConfig = try await ServerConfig.get(server: server)
                let count: Int = {
                    switch configuration.item {
                    case .photos:
                        return serverConfig.count.photos
                    case .videos:
                        return serverConfig.count.videos
                    case .favorites:
                        return serverConfig.count.favorites
                    }
                }()
                return Entry(date: Date(), item: configuration.item, count: count)
            } catch {
                print(error)
                return Entry(date: Date(), item: configuration.item, count: -1)
            }
        }
        
        func timeline(for configuration: Configuration, in context: Context) async -> Timeline<Entry> {
            let entries = [await snapshot(for: configuration, in: context)]
            guard let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) else {
                return Timeline(entries: entries, policy: .never)
            }
            return Timeline(entries: entries, policy: .after(oneHourLater))
        }
    }

    struct Entry: TimelineEntry {
        let date: Date
        let item: CountableItem
        let count: Int
    }
}

#Preview(as: .systemSmall) {
    SingleCounterWidget()
} timeline: {
    SingleCounterWidget.Entry(date: Date(), item: .photos, count: 10468)
    SingleCounterWidget.Entry(date: Date(), item: .videos, count: 37)
    SingleCounterWidget.Entry(date: Date(), item: .favorites, count: 64)
}
