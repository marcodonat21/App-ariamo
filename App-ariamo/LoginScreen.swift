import SwiftUI
import LocalAuthentication

struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false; @State private var alertMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // SFONDO
                Image("app_foto")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea(.all)
               
                Color.white.opacity(0.92).ignoresSafeArea(.all)
               
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                       
                        // TASTO INDIETRO (MODIFICATO CON STILE TONDINO BIANCO)
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appGreen)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            Spacer()
                        }.padding(.horizontal).padding(.top, 60)
                       
                        // TITOLO
                        Text("Hello, we are happy\nto see you again!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.appGreen)
                            .multilineTextAlignment(.center)
                       
                        // CAMPI DI TESTO
                        VStack(spacing: 20) {
                            CustomTextField(placeholder: "Email *", text: $email)
                            CustomTextField(placeholder: "Password *", text: $password, isSecure: true)
                        }
                       
                        HStack { Spacer(); Button("Forgot Password?") { }.font(.system(.caption, design: .rounded)).foregroundColor(.gray) }.padding(.horizontal, 50)
                       
                        // BOTTONE GO
                        Button(action: {
                            endEditing()
                            if email.isEmpty || password.isEmpty { alertMessage = "Please fill in all required fields."; showAlert = true }
                            else if !Validator.isValidEmail(email) { alertMessage = "Please enter a valid email address."; showAlert = true }
                            else {
                                var currentUser = UserManager.shared.currentUser
                                currentUser.email = email
                                UserManager.shared.saveUser(currentUser)
                                withAnimation { isLoggedIn = true }
                            }
                        }) {
                            Text("Go!")
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 120)
                                .background(Color.appGreen)
                                .cornerRadius(30)
                                .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.top, 10)
                       
                        // BOTTONE FACE ID
                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: "faceid").font(.title2)
                                Text("Login with Face ID").fontWeight(.semibold)
                            }
                            .foregroundColor(.appGreen)
                            .padding(.top, 10)
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // --- FUNZIONE PER FACE ID / TOUCH ID ---
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself to enter App Ariamoci."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation { isLoggedIn = true }
                    } else {
                        if let laError = authenticationError as? LAError {
                             print("Face ID error: \(laError.localizedDescription)")
                        }
                        alertMessage = "Face ID authentication failed."
                        showAlert = true
                    }
                }
            }
        } else {
            alertMessage = "Face ID/Touch ID not available or not set up."
            showAlert = true
        }
    }
}
