import SwiftUI

/// A header component for the hero section that displays the last update time.
struct HeroSectionHeader: View {
    let lastUpdateTime: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let lastUpdate = lastUpdateTime {
                Text("Last updated: \(lastUpdate.formatted(.relative(presentation: .named))) on \(lastUpdate.formatted(.dateTime.weekday(.wide)))")
                    .soraCaption()
                    .foregroundColor(.secondary)
            } else {
                Text("Fetching latest data...")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        HeroSectionHeader(lastUpdateTime: Date())
        HeroSectionHeader(lastUpdateTime: nil)
    }
    .padding()
    .background(Color(.systemBackground))
} 