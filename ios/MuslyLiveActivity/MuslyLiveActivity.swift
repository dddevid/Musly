import WidgetKit
import SwiftUI
import ActivityKit

// ActivityAttributes MUST be named exactly "LiveActivitiesAppAttributes"
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    
    public struct ContentState: Codable, Hashable {
        // Flutter will pass data via UserDefaults, not here directly
    }
    
    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

// Shared UserDefaults - MUST match the appGroupId used in Flutter
let sharedDefault = UserDefaults(suiteName: "group.com.dddevid.musly")!

@main
struct MuslyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // Lock screen / banner UI
            let currentLine = sharedDefault.string(forKey: context.attributes.prefixedKey("currentLine")) ?? ""
            let songTitle = sharedDefault.string(forKey: context.attributes.prefixedKey("songTitle")) ?? ""
            let artist = sharedDefault.string(forKey: context.attributes.prefixedKey("artist")) ?? ""
            
            VStack(alignment: .leading, spacing: 8) {
                if !songTitle.isEmpty {
                    Text(songTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !currentLine.isEmpty {
                    Text(currentLine)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if !artist.isEmpty {
                    Text(artist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            // Dynamic Island UI
            let currentLine = sharedDefault.string(forKey: context.attributes.prefixedKey("currentLine")) ?? ""
            let songTitle = sharedDefault.string(forKey: context.attributes.prefixedKey("songTitle")) ?? ""
            let artist = sharedDefault.string(forKey: context.attributes.prefixedKey("artist")) ?? ""
            
            DynamicIsland {
                // Expanded view
                VStack(alignment: .leading, spacing: 8) {
                    if !songTitle.isEmpty {
                        Text(songTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !currentLine.isEmpty {
                        Text(currentLine)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)
                    }
                    
                    if !artist.isEmpty {
                        Text(artist)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } compactLeading: {
                // Leading compact view
                Image(systemName: "music.note")
                    .foregroundColor(.pink)
            } compactTrailing: {
                // Trailing compact view
                Text(currentLine.isEmpty ? "..." : String(currentLine.prefix(10)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } minimal: {
                // Minimal view
                Image(systemName: "music.note")
                    .foregroundColor(.pink)
            }
        }
    }
}
