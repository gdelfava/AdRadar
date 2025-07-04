import SwiftUI

struct NetworkErrorModalView: View {
    let message: String
    let onClose: () -> Void
    let onSettings: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.red)
                .padding(.top, 32)
            Text("No Internet Connection")
                .font(.title2).bold()
                .foregroundColor(.primary)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            HStack(spacing: 16) {
                Button(action: onClose) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(12)
                }
                Button(action: onSettings) {
                    Text("Go to Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 400)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 24)
        .padding()
    }
}

#if DEBUG
struct NetworkErrorModalView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkErrorModalView(
            message: "The Internet connection appears to be offline. Please check your Wi-Fi or Cellular settings.",
            onClose: {},
            onSettings: {}
        )
    }
}
#endif 