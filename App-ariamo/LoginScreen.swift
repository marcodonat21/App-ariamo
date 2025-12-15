import SwiftUI

struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    // Alert State
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // SFONDO FISSO
                Image("app_foto")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea(.all)
                
                Color.white.opacity(0.92)
                    .ignoresSafeArea(.all)
                
                // CONTENUTO SCORREVOLE
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Header Indietro
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appGreen)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 60)
                        
                        // TITOLO
                        Text("Hello, we are happy\nto see you again!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appGreen)
                            .multilineTextAlignment(.center)
                        
                        // CAMPI
                        VStack(spacing: 20) {
                            CustomTextField(placeholder: "Email *", text: $email)
                            CustomTextField(placeholder: "Password *", text: $password, isSecure: true)
                        }
                        
                        // PASSWORD DIMENTICATA
                        HStack {
                            Spacer()
                            Button("Forgot Password?") { }
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 50)
                        
                        // BOTTONE GO
                        Button(action: {
                            endEditing()
                            
                            // VALIDAZIONE
                            if email.isEmpty || password.isEmpty {
                                alertMessage = "Please fill in all required fields."
                                showAlert = true
                            } else if !Validator.isValidEmail(email) {
                                alertMessage = "Please enter a valid email address (e.g., user@mail.com)."
                                showAlert = true
                            } else {
                                withAnimation { isLoggedIn = true }
                            }
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
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onTapGesture { endEditing() }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarHidden(true)
    }
}

#Preview {
    LoginScreen(isLoggedIn: .constant(false))
}
