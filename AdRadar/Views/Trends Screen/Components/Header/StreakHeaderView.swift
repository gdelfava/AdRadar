import SwiftUI

struct StreakHeaderView: View {
    let lastUpdateTime: Date?
    
    private var formattedLastUpdate: String {
        guard let lastUpdateTime = lastUpdateTime else {
            return "never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdateTime, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.secondary)
            Text("Last updated \(formattedLastUpdate)")
                .soraFootnote()
                .foregroundColor(.secondary)
            Spacer()
        }
    }
} 