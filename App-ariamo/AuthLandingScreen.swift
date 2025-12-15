import SwiftUI

struct AuthLandingScreen: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // 1. BACKGROUND
            Image("app_foto")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.white.opacity(0.92))
            
            // 2. CONTENT
            VStack(spacing: 25) {
                Spacer()
                
                // Title
                Text("app-ariamo")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.appGreen)
                    .padding(.bottom, 10)
                
                Text("Welcome! Choose how to access.") // Translated
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
                
                // REGISTRATION BUTTON
                NavigationLink {
                    RegistrationStep1(isLoggedIn: $isLoggedIn)
                } label: {
                    Text("Create Account") // Translated
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appGreen)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                
                // LOGIN BUTTON
                NavigationLink {
                    LoginScreen(isLoggedIn: $isLoggedIn)
                } label: {
                    Text("Login") // Simplified translation (was "Accedi (Login)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.appGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.appGreen, lineWidth: 2)
                        )
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                
                // SOCIAL
                VStack(spacing: 15) {
                    Text("or log in with") // Translated
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        SocialButtonSmall(icon: "applelogo")
                        SocialButtonSmall(icon: "g.circle.fill")
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AuthLandingScreen(isLoggedIn: .constant(false))
}
