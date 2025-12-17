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
                Text("app.ariamo")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.appGreen)
                    .padding(.bottom, 10)
                
                Text("Welcome! Choose how to access.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
                
                // REGISTRATION BUTTON
                NavigationLink {
                    RegistrationStep1(isLoggedIn: $isLoggedIn)
                } label: {
                    Text("Create Account")
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
                    Text("Login")
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
                .padding(.bottom, 200)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AuthLandingScreen(isLoggedIn: .constant(false))
}
