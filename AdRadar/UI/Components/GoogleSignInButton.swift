// Reusable Google Sign-In button component
//
//  GoogleSignInButton.swift
//  Adsense Tracker
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI

struct GoogleSignInButtonView: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image("GoogleSigninButtonLight", bundle: nil)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibilityLabel("Sign in with Google")
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 50)
        .shadow(radius: 2)
    }
}

#if DEBUG
struct GoogleSignInButtonView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInButtonView(action: {})
            .padding()
            .background(Color("LoginScreenBackground"))
            .previewLayout(.sizeThatFits)
    }
}
#endif
