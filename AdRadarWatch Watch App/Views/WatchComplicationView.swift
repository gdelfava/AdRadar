import SwiftUI
import WidgetKit
import ClockKit

// MARK: - Complication Views for different families
struct WatchComplicationView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        switch entry.family {
        case .modularSmall:
            ModularSmallView(entry: entry)
        case .modularLarge:
            ModularLargeView(entry: entry)
        case .utilitarianSmall:
            ModularSmallView(entry: entry) // Reuse modular small for utility small
        case .utilitarianSmallFlat:
            ModularSmallView(entry: entry) // Reuse modular small
        case .utilitarianLarge:
            ModularLargeView(entry: entry) // Reuse modular large
        case .circularSmall:
            CircularSmallView(entry: entry)
        case .extraLarge:
            CircularSmallView(entry: entry) // Reuse circular for extra large
        case .graphicCorner:
            GraphicCornerView(entry: entry)
        case .graphicCircular:
            GraphicCircularView(entry: entry)
        case .graphicRectangular:
            GraphicRectangularView(entry: entry)
        case .graphicBezel:
            GraphicCircularView(entry: entry) // Reuse graphic circular for bezel
        case .graphicExtraLarge:
            GraphicCircularView(entry: entry) // Reuse graphic circular for extra large
        @unknown default:
            ModularSmallView(entry: entry)
        }
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let family: CLKComplicationFamily
    let todayEarnings: String
    let delta: String?
    let deltaPositive: Bool?
    
    init(date: Date = Date(), family: CLKComplicationFamily, todayEarnings: String = "R 0,00", delta: String? = nil, deltaPositive: Bool? = nil) {
        self.date = date
        self.family = family
        self.todayEarnings = todayEarnings
        self.delta = delta
        self.deltaPositive = deltaPositive
    }
}

// MARK: - Individual Complication Views

struct ModularSmallView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        VStack(spacing: 0) {
            Text("AR")
                .font(.custom("Sora-Bold", size: 8))
                .foregroundColor(.accentColor)
            
            Text(formatCurrencyForComplication(entry.todayEarnings))
                .font(.custom("Sora-Medium", size: 10))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(2)
    }
}

struct ModularLargeView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("AdRadar")
                    .font(.custom("Sora-SemiBold", size: 12))
                    .foregroundColor(.accentColor)
                Spacer()
            }
            
            Text("Today")
                .font(.custom("Sora-Regular", size: 10))
                .foregroundColor(.secondary)
            
            Text(entry.todayEarnings)
                .font(.custom("Sora-Bold", size: 16))
                .foregroundColor(.primary)
            
            if let delta = entry.delta {
                HStack(spacing: 2) {
                    Image(systemName: entry.deltaPositive == true ? "arrow.up" : "arrow.down")
                        .font(.custom("Sora-Regular", size: 8))
                        .foregroundColor(entry.deltaPositive == true ? .green : .red)
                    
                    Text(delta)
                        .font(.custom("Sora-Regular", size: 9))
                        .foregroundColor(entry.deltaPositive == true ? .green : .red)
                        .lineLimit(1)
                }
            }
        }
        .padding(4)
    }
}

struct CircularSmallView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
            
            VStack(spacing: 0) {
                Text("AR")
                    .font(.custom("Sora-Bold", size: 6))
                    .foregroundColor(.accentColor)
                
                Text(formatCurrencyForComplication(entry.todayEarnings))
                    .font(.custom("Sora-Medium", size: 8))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
    }
}

struct GraphicCornerView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        VStack {
            Text("AR")
                .font(.custom("Sora-Bold", size: 10))
                .foregroundColor(.accentColor)
            
            Text(formatCurrencyForComplication(entry.todayEarnings))
                .font(.custom("Sora-Medium", size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct GraphicCircularView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
            
            VStack(spacing: 0) {
                Text("AR")
                    .font(.custom("Sora-Bold", size: 8))
                    .foregroundColor(.accentColor)
                
                Text(formatCurrencyForComplication(entry.todayEarnings))
                    .font(.custom("Sora-Medium", size: 10))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

struct GraphicRectangularView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("AdRadar")
                    .font(.custom("Sora-SemiBold", size: 12))
                    .foregroundColor(.accentColor)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today")
                        .font(.custom("Sora-Regular", size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(entry.todayEarnings)
                        .font(.custom("Sora-Bold", size: 16))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let delta = entry.delta {
                    VStack(alignment: .trailing, spacing: 1) {
                        Image(systemName: entry.deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.custom("Sora-Regular", size: 12))
                            .foregroundColor(entry.deltaPositive == true ? .green : .red)
                        
                        Text(delta.components(separatedBy: " ").first ?? delta)
                            .font(.custom("Sora-Regular", size: 9))
                            .foregroundColor(entry.deltaPositive == true ? .green : .red)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(4)
    }
}

// MARK: - Helper Functions
private func formatCurrencyForComplication(_ value: String) -> String {
    // Remove "R " prefix and shorten for complication display
    let cleaned = value.replacingOccurrences(of: "R ", with: "")
    
    // If the value contains a comma (thousands separator), show abbreviated form
    if cleaned.contains(",") {
        let components = cleaned.components(separatedBy: ",")
        if let firstPart = components.first, let number = Double(firstPart) {
            if number >= 1000 {
                return String(format: "%.0fk", number / 1000)
            } else {
                return String(format: "%.0f", number)
            }
        }
    }
    
    // For smaller values, just return the number without currency symbol
    return cleaned.replacingOccurrences(of: ",", with: ".")
}

#Preview("Modular Small") {
    ModularSmallView(entry: ComplicationEntry(
        family: .modularSmall,
        todayEarnings: "R 15,75",
        delta: "+28%",
        deltaPositive: true
    ))
}

#Preview("Graphic Rectangular") {
    GraphicRectangularView(entry: ComplicationEntry(
        family: .graphicRectangular,
        todayEarnings: "R 15,75",
        delta: "+R 3,45",
        deltaPositive: true
    ))
} 