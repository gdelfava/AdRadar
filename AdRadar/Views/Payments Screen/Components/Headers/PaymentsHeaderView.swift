import SwiftUI

struct PaymentsHeaderView: View {
    let lastUpdateTime: String
    
    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Last updated \(lastUpdateTime)")
                .soraCaption()
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
} 