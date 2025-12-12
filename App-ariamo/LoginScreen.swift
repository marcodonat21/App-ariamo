import SwiftUI

// --- LOGIN SCREEN ---
struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Hello, we are happy\nto see you again!")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.top, 50)
            
            // I campi di testo riutilizzabili
            CustomTextField(placeholder: "Email", text: $email)
            CustomTextField(placeholder: "Password", text: $password, isSecure: true)
            
            HStack {
                Spacer()
                Button("Forgot Password?") { }
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Azione di Login
            Button(action: {
                // SIMULAZIONE LOGIN RIUSCITO
                withAnimation { isLoggedIn = true }
            }) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 100)
                    .background(Color.appMint.opacity(0.3))
                    .cornerRadius(25)
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
}

// --- PREVIEW ---
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(isLoggedIn: .constant(false))
    }
}
