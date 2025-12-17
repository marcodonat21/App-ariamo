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
                
                // SOCIAL LOGIN SECTION
                /*VStack(spacing: 15) {
                    Text("or log in with")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        // APPLE LOGIN BUTTON
                        Button(action: {
                            performSocialLogin(provider: "Apple")
                        }) {
                            SocialButtonSmall(icon: "applelogo")
                        }
                        
                        // GOOGLE LOGIN BUTTON
                        Button(action: {
                            performSocialLogin(provider: "Google")
                        }) {
                            SocialButtonSmall(icon: "g.circle.fill")
                        }
                    }
                }*/
                //.padding(.top, 200)
                .padding(.bottom, 300)
            }
        }
        .navigationBarHidden(true)
    }
    
    /*// --- FUNZIONE PER SIMULARE IL LOGIN SOCIAL ---
    func performSocialLogin(provider: String) {
        // 1. Simuliamo un ritardo di rete (opzionale, per realismo)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 2. Creiamo un utente fittizio basato sul provider
        var socialUser = UserProfile.testUser
        
        if provider == "Apple" {
            socialUser.name = "Apple"
            socialUser.surname = "User"
            socialUser.email = "user@icloud.com"
            socialUser.bio = "Logged in via Apple ID"
        } else {
            socialUser.name = "Google"
            socialUser.surname = "User"
            socialUser.email = "user@gmail.com"
            socialUser.bio = "Logged in via Google"
        }
        
        // 3. Salviamo l'utente nel database locale
        UserManager.shared.saveUser(socialUser)
        
        // 4. Entriamo nell'app
        withAnimation {
            isLoggedIn = true
        }
    }*/
}
     

#Preview {
    AuthLandingScreen(isLoggedIn: .constant(false))
}
