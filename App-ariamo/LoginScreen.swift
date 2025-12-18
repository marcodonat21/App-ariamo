import SwiftUI

struct LoginScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false; @State private var alertMessage = ""
    @State private var isLoading = false
    
    // Stato per il foglio Forgot Password
    @State private var showForgotPassword = false
    
    @FocusState private var focusedField: Field?
    enum Field { case email, password }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto")
                    .resizable().scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea(.all)
               
                Color.white.opacity(0.92).ignoresSafeArea(.all)
               
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // TASTO INDIETRO
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            Spacer()
                        }.padding(.horizontal).padding(.top, 60)
                       
                        Text("Hello, we are happy\nto see you again!")
                            .font(.system(.title2, design: .rounded)).fontWeight(.bold).foregroundColor(.appGreen).multilineTextAlignment(.center)
                       
                        VStack(spacing: 20) {
                            TextField("Email *", text: $email)
                                .focused($focusedField, equals: .email)
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal, 40)

                            SecureField("Password *", text: $password)
                                .focused($focusedField, equals: .password)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .onSubmit { performLogin() }
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal, 40)
                        }
                       
                        // BUTTON FORGOT PASSWORD
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        }.padding(.horizontal, 50)
                       
                        if isLoading {
                            ProgressView().tint(.appGreen)
                        } else {
                            Button(action: performLogin) {
                                Text("Go!")
                                    .font(.system(.headline, design: .rounded).bold()).foregroundColor(.white).padding().frame(width: 120).background(Color.appGreen).cornerRadius(30).shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
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
        .alert(isPresented: $showAlert) { Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
        
        // --- SHEET FORGOT PASSWORD ---
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(prefilledEmail: email)
        }
    }
    
    func performLogin() {
        focusedField = nil
        if email.isEmpty || password.isEmpty { alertMessage = "Please fill in all fields."; showAlert = true; return }
        
        isLoading = true
        Task(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 100_000_000)
            do {
                try await UserManager.shared.login(email: email, password: password)
            } catch {
                alertMessage = "Login failed: \(error.localizedDescription)"
                showAlert = true
            }
            isLoading = false
        }
    }
}

// --- NUOVA VIEW STILOSA PER RESET PASSWORD ---
struct ForgotPasswordSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State var prefilledEmail: String
    @State private var emailInput: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header con barra di chiusura
                Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                
                Spacer()
                
                Image(systemName: "lock.rotation").font(.system(size: 60)).foregroundColor(.appGreen)
                
                Text("Forgot Password?")
                    .font(.title).bold().foregroundColor(.black)
                
                Text("Don't worry! It happens. Please enter the email address associated with your account.")
                    .font(.body).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30)
                
                TextField("Enter your email", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .onAppear { if !prefilledEmail.isEmpty { emailInput = prefilledEmail } }
                
                if isLoading {
                    ProgressView().tint(.appGreen)
                } else {
                    Button(action: sendLink) {
                        Text("Send Reset Link")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appGreen)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                }

                Spacer()
                Spacer()
            }
            .padding()
            
            // Success Overlay
            if showSuccess {
                Color.white.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "envelope.fill").font(.system(size: 70)).foregroundColor(.appGreen)
                    Text("Check your email").font(.title2).bold()
                    Text("We have sent a password recover instructions to your email.").font(.body).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                    Button("Back to Login") { presentationMode.wrappedValue.dismiss() }.padding().foregroundColor(.appGreen).bold()
                }
                .transition(.opacity)
            }
            
            // Error Overlay (Semplice Toast)
            if showError {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.white)
                        Text(errorMessage).foregroundColor(.white).font(.caption).bold()
                    }
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(20)
                    .padding(.bottom, 50)
                }.zIndex(100).transition(.move(edge: .bottom))
            }
        }
    }
    
    func sendLink() {
        guard !emailInput.isEmpty else { return }
        isLoading = true
        Task {
            do {
                try await UserManager.shared.sendPasswordReset(email: emailInput)
                withAnimation { showSuccess = true }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
                withAnimation { showError = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showError = false } }
            }
            isLoading = false
        }
    }
}
