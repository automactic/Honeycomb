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

enum CountableItem: String, AppEnum {
    case all, photos, videos, archived, favorites, folders
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countable Item")
    static var caseDisplayRepresentations: [CountableItem: DisplayRepresentation] = [
        .all: DisplayRepresentation(title: "All"),
        .photos: DisplayRepresentation(title: "Photos"),
        .videos: DisplayRepresentation(title: "Videos"),
        .archived: DisplayRepresentation(title: "Archived"),
        .favorites: DisplayRepresentation(title: "Favorites"),
        .folders: DisplayRepresentation(title: "Folders")
    ]
}

// MARK: - Model

struct CounterConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Customize Widget"
    
    @Parameter(title: "Counter", default: .photos)
    var item: CountableItem
}

struct CounterTimelineProvider: AppIntentTimelineProvider {
    static let placeholderItemCounts = ServerConfig.Count(
        all: 14769, photos: 11308, videos: 3453, archived: 12, favorites: 16, folders: 66
    )
    
    func placeholder(in context: Context) -> CounterEntry {
        CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    }
    
    func snapshot(for configuration: CounterConfig, in context: Context) async -> CounterEntry {
        let fetchDescriptor = FetchDescriptor<Server>()
//            fetchDescriptor.predicate = #Predicate<Server> { configuration.server.id == $0.id }
        do {
            let container = try ModelContainer(for: Server.self)
            guard let server = try ModelContext(container).fetch(fetchDescriptor).first else {
                return CounterEntry(date: Date(), item: configuration.item, itemCounts: nil)
            }
            let serverConfig = try await ServerConfig.get(server: server)
            return CounterEntry(date: Date(), item: configuration.item, itemCounts: serverConfig.count)
        } catch {
            print(error)
            return CounterEntry(date: Date(), item: configuration.item, itemCounts: nil)
        }
    }
    
    func timeline(for configuration: CounterConfig, in context: Context) async -> Timeline<CounterEntry> {
        let entries = [await snapshot(for: configuration, in: context)]
        guard let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) else {
            return Timeline(entries: entries, policy: .never)
        }
        return Timeline(entries: entries, policy: .after(oneHourLater))
    }
}

struct CounterEntry: TimelineEntry {
    let date: Date
    let item: CountableItem
    let itemCounts: ServerConfig.Count?
}

// MARK: - View

struct CountableItemIcon: View {
    let item: CountableItem
    
    var body: some View {
        switch item {
        case .all:
            Image(systemName: "infinity.circle").foregroundStyle(Color.purple)
        case .photos:
            Image(systemName: "photo.circle").foregroundStyle(Color.blue)
        case .videos:
            Image(systemName: "film.circle").foregroundStyle(Color.green)
        case .archived:
            Image(systemName: "archivebox.circle").foregroundStyle(Color.red)
        case .favorites:
            Image(systemName: "star.circle").symbolRenderingMode(.multicolor)
        case .folders:
            Image(systemName: "folder.circle").foregroundStyle(Color.orange)
        }
    }
}

struct CounterValue: View {
    let item: CountableItem
    let itemCounts: ServerConfig.Count
    
    var body: some View {
        Text(count.formatted())
    }
    
    private var count: Int {
        switch item {
        case .all:
            return itemCounts.all
        case .photos:
            return itemCounts.photos
        case .videos:
            return itemCounts.videos
        case .archived:
            return itemCounts.archived
        case .favorites:
            return itemCounts.favorites
        case .folders:
            return itemCounts.folders
        }
    }
}

struct SingleCounterWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "dev.chrisli.honeycomb.single-counter",
            intent: Configuration.self,
            provider: TimelineProvider()
        ) { entry in
            VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                    CountableItemIcon(item: entry.item).imageScale(.large)
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
        
        @Parameter(title: "Counter", default: .photos)
        var item: CountableItem
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
                    case .all:
                        return serverConfig.count.all
                    case .photos:
                        return serverConfig.count.photos
                    case .videos:
                        return serverConfig.count.videos
                    case .archived:
                        return serverConfig.count.archived
                    case .favorites:
                        return serverConfig.count.favorites
                    case .folders:
                        return serverConfig.count.folders
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
    SingleCounterWidget.Entry(date: Date(), item: .all, count: 14623)
    SingleCounterWidget.Entry(date: Date(), item: .photos, count: 10468)
    SingleCounterWidget.Entry(date: Date(), item: .videos, count: 37)
    SingleCounterWidget.Entry(date: Date(), item: .archived, count: 12)
    SingleCounterWidget.Entry(date: Date(), item: .favorites, count: 16)
    SingleCounterWidget.Entry(date: Date(), item: .folders, count: 66)
}
