import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var paymentThreshold: String = ""
    @State private var showThresholdAlert = false
    @Binding var showOnboarding: Bool
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    private let onboardingData = [
        OnboardingPage(
            title: "Track Your AdSense & AdMob Earnings with Ease",
            subtitle: "See daily, monthly & lifetime reports in one clean dashboard.",
            imageName: "chart.bar.fill",
            backgroundColor: Color.blue,
            pageType: .info
        ),
        OnboardingPage(
            title: "Detailed Analytics & Insights",
            subtitle: "Dive deep into your performance with breakdowns by country, platform, and ad sizes.",
            imageName: "chart.pie.fill",
            backgroundColor: Color.green,
            pageType: .info
        ),
        OnboardingPage(
            title: "Set Your Payment Threshold",
            subtitle: "Configure your Adsense account payment threshold. This helps you track progress toward your next payment in real time.",
            imageName: "target",
            backgroundColor: Color.orange,
            pageType: .paymentThreshold
        ),
        OnboardingPage(
            title: "Get Started in Seconds",
            subtitle: "Simply sign in with Google to connect your AdSense account and start tracking.",
            imageName: "person.circle.fill",
            backgroundColor: Color.purple,
            pageType: .info
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main content area
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingData[index],
                            animateContent: animateContent,
                            paymentThreshold: $paymentThreshold,
                            showThresholdAlert: $showThresholdAlert,
                            settingsViewModel: settingsViewModel
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.6), value: currentPage)
                
                // Bottom section with controls
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if currentPage < onboardingData.count - 1 {
                            Button(action: {
                                if currentPage == 2 { // Payment threshold page
                                    handlePaymentThresholdNext()
                                } else {
                                    nextPage()
                                }
                            }) {
                                HStack {
                                    Text("Next")
                                        .soraButtonTitle()
                                    Image(systemName: "arrow.right")
                                        .font(.sora(.medium, size: 17))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(onboardingData[currentPage].backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(OnboardingButtonStyle())
                            
                            Button(action: skipOnboarding) {
                                Text("Skip")
                                    .soraFont(.medium, size: 17)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: skipOnboarding) {
                                HStack {
                                    Text("Get Started")
                                        .soraButtonTitle()
                                    Image(systemName: "arrow.right")
                                        .font(.sora(.medium, size: 17))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(onboardingData[currentPage].backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(OnboardingButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24))
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
            // Initialize payment threshold with default value
            paymentThreshold = String(settingsViewModel.paymentThreshold)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 && currentPage < onboardingData.count - 1 {
                        if currentPage == 2 { // Payment threshold page
                            handlePaymentThresholdNext()
                        } else {
                            nextPage()
                        }
                    } else if value.translation.width > 50 && currentPage > 0 {
                        previousPage()
                    }
                }
        )
        .alert("Invalid Amount", isPresented: $showThresholdAlert) {
            Button("OK") { }
        } message: {
            Text("Please enter a valid amount greater than 0.")
                .soraBody()
        }
    }
    
    private func handlePaymentThresholdNext() {
        if validateAndSavePaymentThreshold() {
            nextPage()
        } else {
            showThresholdAlert = true
        }
    }
    
    private func validateAndSavePaymentThreshold() -> Bool {
        guard let threshold = Double(paymentThreshold), threshold > 0 else {
            return false
        }
        
        settingsViewModel.updatePaymentThreshold(threshold)
        return true
    }
    
    private func nextPage() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage += 1
        }
    }
    
    private func previousPage() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage -= 1
        }
    }
    
    private func skipOnboarding() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Save payment threshold if user is on that page
        if currentPage == 2 && !paymentThreshold.isEmpty {
            _ = validateAndSavePaymentThreshold()
        }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            showOnboarding = false
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let animateContent: Bool
    @Binding var paymentThreshold: String
    @Binding var showThresholdAlert: Bool
    let settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Illustration area
            VStack(spacing: 32) {
                // Icon illustration
                ZStack {
                    Circle()
                        .fill(page.backgroundColor.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Circle()
                        .fill(page.backgroundColor.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateContent ? 1.0 : 0.6)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Image(systemName: page.imageName)
                        .font(.sora(.medium, size: 60))
                        .foregroundColor(page.backgroundColor)
                        .scaleEffect(animateContent ? 1.0 : 0.4)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                
                // Text content
                VStack(spacing: 16) {
                    Text(page.title)
                        .soraLargeTitle()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
                    
                    Text(page.subtitle)
                        .soraBody()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                    
                    // Payment threshold input field
                    if page.pageType == .paymentThreshold {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Text("Threshold Amount:")
                                    .soraSubheadline()
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter amount", text: $paymentThreshold)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 120)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.8).delay(1.0), value: animateContent)
                            
                            VStack(spacing: 8) {
                                Text("Common thresholds:")
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    PaymentThresholdButton(amount: 100, currency: "USD", paymentThreshold: $paymentThreshold)
                                    PaymentThresholdButton(amount: 1000, currency: "ZAR", paymentThreshold: $paymentThreshold)
                                    PaymentThresholdButton(amount: 8000, currency: "INR", paymentThreshold: $paymentThreshold)
                                }
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.8).delay(1.2), value: animateContent)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaymentThresholdButton: View {
    let amount: Double
    let currency: String
    @Binding var paymentThreshold: String
    
    var body: some View {
        Button(action: {
            paymentThreshold = String(amount)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Text(formatCurrency(amount))
                    .soraCaption()
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(currency)
                    .soraCaption2()
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(paymentThreshold == String(amount) ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

enum OnboardingPageType {
    case info
    case paymentThreshold
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
    let pageType: OnboardingPageType
}

struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
} 
