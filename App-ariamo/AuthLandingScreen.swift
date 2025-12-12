import SwiftUI

struct AuthLandingScreen: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // 1. SFONDO
            Image("app_foto")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.white.opacity(0.92))
            
            // 2. CONTENUTO
            VStack(spacing: 25) {
                Spacer()
                
                // Titolo
                Text("app-ariamo")
                    .font(.system(size: 40, weight: .heavy, design: .rounded)) // Peso definito qui
                    .foregroundColor(.appGreen)
                    .padding(.bottom, 10)
                
                Text("Benvenuto! Scegli come accedere.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
                
                // BOTTONE REGISTRAZIONE
                NavigationLink {
                    RegistrationStep1(isLoggedIn: $isLoggedIn) // <--- CAMBIA QUI
                } label: {
                    Text("Crea un Account")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold) // CORRETTO: Fuori dalle parentesi del font
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appGreen)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                
                // BOTTONE LOGIN
                NavigationLink {
                    LoginScreen(isLoggedIn: $isLoggedIn)
                } label: {
                    Text("Accedi (Login)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold) // CORRETTO
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
                    Text("oppure accedi con")
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
