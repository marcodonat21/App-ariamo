import SwiftUI

struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // BACKGROUND
            Image("app_foto")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.white.opacity(0.92))
            
            // CONTENUTO RESO SCORREVOLE PER PREVENIRE IL SALTO
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // CUSTOM TITLE (Green)
                    Text("Hello, we are happy\nto see you again!")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.appGreen)
                        .multilineTextAlignment(.center)
                        .padding(.top, 80)
                    
                    // FIELDS
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Email", text: $email)
                        CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                    }
                    
                    // FORGOT PASSWORD
                    HStack {
                        Spacer()
                        Button("Forgot Password?") { }
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 50)
                    
                    // "Go!" BUTTON
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
                    .padding(.top, 10)
                    
                    Spacer() // Pushes the content up (but contained in ScrollView)
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height) // Forziamo l'altezza minima
            }
        }
        // MODIFICATORE FONDAMENTALE: Ignora il movimento della tastiera
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        LoginScreen(isLoggedIn: .constant(false))
    }
}
