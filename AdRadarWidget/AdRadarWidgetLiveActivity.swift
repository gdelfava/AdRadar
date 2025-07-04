//
//  AdRadarWidgetLiveActivity.swift
//  AdRadarWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AdRadarWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AdRadarWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdRadarWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension AdRadarWidgetAttributes {
    fileprivate static var preview: AdRadarWidgetAttributes {
        AdRadarWidgetAttributes(name: "World")
    }
}

extension AdRadarWidgetAttributes.ContentState {
    fileprivate static var smiley: AdRadarWidgetAttributes.ContentState {
        AdRadarWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AdRadarWidgetAttributes.ContentState {
         AdRadarWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AdRadarWidgetAttributes.preview) {
   AdRadarWidgetLiveActivity()
} contentStates: {
    AdRadarWidgetAttributes.ContentState.smiley
    AdRadarWidgetAttributes.ContentState.starEyes
}
