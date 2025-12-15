import SwiftUI

struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // SFONDO
            Image("app_foto")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.white.opacity(0.92))
            
            VStack(spacing: 30) {
                // TITOLO PERSONALIZZATO (Verde)
                Text("Hello, we are happy\nto see you again!")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.appGreen)
                    .multilineTextAlignment(.center)
                    .padding(.top, 80) // Spazio dall'alto
                
                // CAMPI
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Email", text: $email)
                    CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                }
                
                // PASSWORD DIMENTICATA
                HStack {
                    Spacer()
                    Button("Forgot Password?") { }
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 50)
                
                // BOTTONE "Go!" (Ora subito sotto, non in fondo)
                Button(action: {
                    withAnimation { isLoggedIn = true }
                }) {
                    Text("Go!")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 120)
                        .background(Color.appGreen)
                        .cornerRadius(30)
                        .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10) // Un po' di aria sopra il bottone
                
                Spacer() // Spinge tutto il blocco verso l'alto/centro
            }
            .padding()
        }
        // NASCONDE IL TITOLO STANDARD "LOGIN"
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        LoginScreen(isLoggedIn: .constant(false))
    }
}
