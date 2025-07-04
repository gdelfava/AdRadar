import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let symbol: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.red)
                .padding(.top, 2)
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemRed).opacity(0.12))
        .cornerRadius(16)
        .shadow(color: Color.red.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#if DEBUG
struct ErrorBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorBannerView(message: "The Internet connection appears to be offline.", symbol: "wifi.slash")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 
