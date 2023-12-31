//
//  CountableItem.swift
//  CountableItem
//
//  Created by Chris Li on 12/10/23.
//

import AppIntents
import WidgetKit
import SwiftData
import SwiftUI

enum CountableItem: String, AppEnum, CaseIterable, Identifiable {
    case all, photos, videos, archived, favorites, folders, labels
    
    var id: String { rawValue }
    var name: String {
        switch self {
        case .all:
            "All"
        case .photos:
            "Photos"
        case .videos:
            "Videos"
        case .archived:
            "Archived"
        case .favorites:
            "Favorites"
        case .folders:
            "Folders"
        case .labels:
            "Labels"
        }
    }
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countable Item")
    static var caseDisplayRepresentations: [CountableItem: DisplayRepresentation] = [
        .all: DisplayRepresentation(title: "All", image: .init(systemName: "infinity")),
        .photos: DisplayRepresentation(title: "Photos", image: .init(systemName: "photo")),
        .videos: DisplayRepresentation(title: "Videos", image: .init(systemName: "film")),
        .archived: DisplayRepresentation(title: "Archived", image: .init(systemName: "archivebox")),
        .favorites: DisplayRepresentation(title: "Favorites", image: .init(systemName: "star")),
        .folders: DisplayRepresentation(title: "Folders", image: .init(systemName: "folder")),
        .labels: DisplayRepresentation(title: "Labels", image: .init(systemName: "tag"))
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
        all: 14769, photos: 11308, videos: 3453, archived: 12, favorites: 16, folders: 66, labels: 72
    )
    
    func placeholder(in context: Context) -> CounterEntry {
        CounterEntry(date: Date(), itemCounts: CounterTimelineProvider.placeholderItemCounts)
    }
    
    func snapshot(for configuration: CounterConfig, in context: Context) async -> CounterEntry {
        var fetchDescriptor = FetchDescriptor<Server>()
        fetchDescriptor.predicate = #Predicate<Server> { $0.isActive == true }
        do {
            let container = try ModelContainer(for: Server.self)
            guard let server = try ModelContext(container).fetch(fetchDescriptor).first else {
                return CounterEntry(date: Date(), item: configuration.item)
            }
            let serverConfig = try await ServerConfig.get(server: server)
            return CounterEntry(
                date: Date(), serverName: server.name, item: configuration.item, itemCounts: serverConfig.count
            )
        } catch {
            print(error)
            return CounterEntry(date: Date(), item: configuration.item)
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
    let serverName: String
    let item: CountableItem
    let itemCounts: ServerConfig.Count?
    
    init(date: Date, serverName: String? = nil, item: CountableItem? = nil, itemCounts: ServerConfig.Count? = nil) {
        self.date = date
        self.serverName = serverName ?? "PhotoPrism"
        self.item = item ?? .photos
        self.itemCounts = itemCounts
    }
}

// MARK: - Views

struct CountableItemIcon: View {
    let item: CountableItem
    let isProminent: Bool
    
    var body: some View {
        switch item {
        case .all:
            Image(systemName: isProminent ? "infinity.circle" : "infinity").foregroundStyle(Color.purple)
        case .photos:
            Image(systemName: isProminent ? "photo.circle" : "photo").foregroundStyle(Color.blue)
        case .videos:
            Image(systemName: isProminent ? "film.circle" : "film").foregroundStyle(Color.green)
        case .archived:
            Image(systemName: isProminent ? "archivebox.circle" : "archivebox").foregroundStyle(Color.red)
        case .favorites:
            Image(systemName: isProminent ? "star.circle" : "star").symbolRenderingMode(.multicolor)
        case .folders:
            Image(systemName: isProminent ? "folder.circle" : "folder").foregroundStyle(Color.orange)
        case .labels:
            Image(systemName: isProminent ? "tag.circle" : "tag").foregroundStyle(Color.teal)
        }
    }
}

struct CounterValue: View {
    let item: CountableItem
    let itemCounts: ServerConfig.Count
    
    var body: some View {
        ViewThatFits {
            Text(count.formatted())
            Text(count.formatted(.number.notation(.compactName)))
        }
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
        case .labels:
            return itemCounts.labels
        }
    }
}

struct ItemCounterView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var margins
    
    let serverName: String
    let item: CountableItem
    let itemCounts: ServerConfig.Count
    
    var body: some View {
        switch family {
        case .systemSmall:
            prominent
        case .systemMedium:
            HStack(spacing: 0) {
                prominent.frame(maxWidth: .infinity)
                Divider()
                details.frame(maxWidth: .infinity)
            }
        case .accessoryInline:
            Label {
                CounterValue(item: item, itemCounts: itemCounts)
            } icon: {
                CountableItemIcon(item: item, isProminent: false)
            }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    CountableItemIcon(item: item, isProminent: false).font(.caption)
                    CounterValue(item: item, itemCounts: itemCounts)
                }
            }
        case .accessoryRectangular:
            Text(serverName)
            Label {
                CounterValue(item: item, itemCounts: itemCounts)
            } icon: {
                CountableItemIcon(item: item, isProminent: false)
            }
        default:
            EmptyView()
        }
    }
    
    private var prominent: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .top) {
                CountableItemIcon(item: item, isProminent: true).imageScale(.large)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(item.name).font(.headline)
                    Text(serverName).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            CounterValue(item: item, itemCounts: itemCounts)
                .font(.system(.title, design: .rounded)).fontWeight(.semibold)
        }.padding(margins)
    }
    
    private var details: some View {
        VStack(alignment: .trailing) {
            ForEach(CountableItem.allCases.filter({ $0 != item })) { item in
                HStack {
                    Label {
                        Text(item.name)
                    } icon: {
                        CountableItemIcon(item: item, isProminent: false)
                    }
                    Spacer()
                    CounterValue(item: item, itemCounts: itemCounts).foregroundStyle(.secondary)
                }.font(.caption).frame(maxHeight: .infinity)
            }
        }.padding(margins).background(.bar)
    }
}

// MARK: - Widgets

struct ItemCounterWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WidgetIdentifier.itemCount.rawValue,
            intent: CounterConfig.self,
            provider: CounterTimelineProvider()
        ) { entry in
            if let itemCounts = entry.itemCounts {
                ItemCounterView(serverName: entry.serverName, item: entry.item, itemCounts: itemCounts)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                Text("Error").containerBackground(.fill.tertiary, for: .widget)
            }
        }
        .configurationDisplayName("Counter")
        .description("Counter of items in your PhotoPrism instance, such as photos, videos or favorites.")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    ItemCounterWidget()
} timeline: {
    CounterEntry(date: Date(), item: .all, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    CounterEntry(date: Date(), item: .videos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    CounterEntry(date: Date(), item: .archived, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    CounterEntry(date: Date(), item: .favorites, itemCounts: CounterTimelineProvider.placeholderItemCounts)
    CounterEntry(date: Date(), item: .folders, itemCounts: CounterTimelineProvider.placeholderItemCounts)
}

#Preview(as: .systemMedium) {
    ItemCounterWidget()
} timeline: {
    CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
}

#Preview(as: .accessoryInline) {
    ItemCounterWidget()
} timeline: {
    CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
}

#Preview(as: .accessoryCircular) {
    ItemCounterWidget()
} timeline: {
    CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
}

#Preview(as: .accessoryRectangular) {
    ItemCounterWidget()
} timeline: {
    CounterEntry(date: Date(), item: .photos, itemCounts: CounterTimelineProvider.placeholderItemCounts)
}
