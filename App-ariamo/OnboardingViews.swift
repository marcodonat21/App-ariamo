//
//  OnboardingViews.swift
//  App-ariamo
//
//  Created by AFP FED 59 on 09/12/25.
//

import SwiftUI

// --- CONFIGURAZIONE GLOBALE ---
// Estensione colori per matchare lo screenshot (Verde acqua/menta)
extension Color {
    static let appMint = Color(red: 0.2, green: 0.8, blue: 0.7)
    static let appDarkText = Color(red: 0.1, green: 0.2, blue: 0.2)
    static let inputGray = Color(UIColor.systemGray6)
}

// --- ROOT VIEW (IL CERVELLO) ---
// Questa vista decide se mostrare il login o l'app vera e propria
struct AppRootView: View {
    @State private var isUserLoggedIn = false

    var body: some View {
        if isUserLoggedIn {
            // Qui richiamiamo la ContentView fatta nel passaggio precedente
            ContentView()
                .transition(.move(edge: .trailing))
        } else {
            NavigationView {
                WelcomeScreen(isLoggedIn: $isUserLoggedIn)
            }
            .accentColor(.black) // Colore frecce navigazione
        }
    }
}

// --- 1. SCHERMATA BENVENUTO (Splash) ---
struct WelcomeScreen: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            Color.appMint.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Logo Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange, lineWidth: 3)
                        .frame(width: 120, height: 120)
                    Image(systemName: "hands.sparkles.fill") // Simbolo mani
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                
                Text("app-ariamo")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("New friends, stories,\npassions.\nFrom online to real life.\nTogether")
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Spacer()
                    NavigationLink(destination: AuthLandingScreen(isLoggedIn: $isLoggedIn)) {
                        Image(systemName: "arrow.right")
                            .font(.title)
                            .foregroundColor(.appMint)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// --- 2. AUTH LANDING (Scegli Login o Sign up) ---
struct AuthLandingScreen: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // Immagine di sfondo simulata
            Image(systemName: "person.3.sequence.fill") // Placeholder folla
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.1)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                Text("app-ariamo")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                    .padding(.bottom, 40)
                
                // Bottone Crea Account
                NavigationLink(destination: CreateAccountStep1(isLoggedIn: $isLoggedIn)) {
                    Text("Create an account")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                
                // Bottoni Social
                SocialButton(text: "Connect with Apple", icon: "applelogo", color: .black)
                SocialButton(text: "Connect with Google", icon: "g.circle.fill", color: .red)
                
                HStack {
                    Text("Do you already have an account?")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    NavigationLink(destination: LoginScreen(isLoggedIn: $isLoggedIn)) {
                        Text("Login")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 50)
            }
        }
    }
}

// --- 3. LOGIN SCREEN ---
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

// --- 4. CREATE ACCOUNT - STEP 1 (Dati base) ---
struct CreateAccountStep1: View {
    @Binding var isLoggedIn: Bool
    @State private var name = ""
    @State private var surname = ""
    @State private var age = 18
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create an account")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                CustomTextField(placeholder: "Name", text: $name)
                CustomTextField(placeholder: "Surname", text: $surname)
                
                // Selettore Età
                HStack {
                    Text("Age (years)")
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $age) {
                        ForEach(18...100, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(5)
                    .background(Color.inputGray)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                CustomTextField(placeholder: "Enter your email", text: $email)
                CustomTextField(placeholder: "Create a Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Repeat Password", text: $password, isSecure: true)
                
                Spacer(minLength: 50)
                
                NavigationLink(destination: CreateAccountStep2(isLoggedIn: $isLoggedIn)) {
                    Text("Go!")
                        .bold()
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 100)
                        .background(Color.appMint.opacity(0.3))
                        .cornerRadius(25)
                }
            }
            .padding()
        }
    }
}

// --- 5. CREATE ACCOUNT - STEP 2 (Profilo) ---
struct CreateAccountStep2: View {
    @Binding var isLoggedIn: Bool
    @State private var bio = ""
    @State private var motto = ""
    @State private var gender = "Man"
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Complete your account")
                .font(.title2)
                .bold()
            
            Text("Upload a profile picture")
                .font(.caption)
                .foregroundColor(.gray)
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            // Gender Picker Custom
            HStack(spacing: 20) {
                GenderButton(title: "Man", isSelected: gender == "Man") { gender = "Man" }
                GenderButton(title: "Woman", isSelected: gender == "Woman") { gender = "Woman" }
            }
            
            CustomTextField(placeholder: "Tell us about yourself (Bio)", text: $bio)
            CustomTextField(placeholder: "Insert your motto here", text: $motto)
            
            Spacer()
            
            // Passiamo alla schermata degli Interessi (Sport)
            NavigationLink(destination: InterestsScreen(isLoggedIn: $isLoggedIn)) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 100)
                    .background(Color.appMint.opacity(0.3))
                    .cornerRadius(25)
            }
            .padding(.bottom, 30)
        }
    }
}

// --- 6. SELEZIONE INTERESSI (Griglia Sport) ---
struct InterestsScreen: View {
    @Binding var isLoggedIn: Bool
    
    let sports = [
        ("Swimming", "figure.pool.swim"),
        ("Hiking", "figure.hiking"),
        ("Gym", "dumbbell.fill"),
        ("Cycle", "bicycle"),
        ("Tennis", "tennis.racket"),
        ("Volleyball", "figure.volleyball")
    ]
    
    @State private var selectedSports: Set<String> = []
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack {
            Text("Selected a sport")
                .font(.title2)
                .bold()
                .padding()
            
            Text("Select your favorite hobby")
                .font(.caption)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(sports, id: \.0) { sport in
                    Button(action: {
                        if selectedSports.contains(sport.0) {
                            selectedSports.remove(sport.0)
                        } else {
                            selectedSports.insert(sport.0)
                        }
                    }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(selectedSports.contains(sport.0) ? Color.appMint : Color.gray.opacity(0.3))
                                .frame(height: 100)
                                .cornerRadius(15)
                            
                            VStack(alignment: .leading) {
                                Image(systemName: sport.1)
                                    .font(.title)
                                    .padding(5)
                                Text(sport.0)
                                    .font(.headline)
                                    .padding(5)
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            NavigationLink(destination: PreferencesScreen(isLoggedIn: $isLoggedIn)) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 100)
                    .background(Color.appMint.opacity(0.3))
                    .cornerRadius(25)
            }
            .padding(.bottom, 30)
        }
    }
}

// --- 7. PREFERENZE (Running toggle e slider) ---
struct PreferencesScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var locationToggle = true
    @State private var notificationToggle = true
    @State private var distance: Double = 5.0
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Text("Running")
                .font(.title)
                .bold()
            
            Text("Pick your running preferences")
                .foregroundColor(.gray)
            
            VStack(spacing: 20) {
                Toggle("Share your live location", isOn: $locationToggle)
                    .padding()
                    .background(Color.inputGray)
                    .cornerRadius(15)
                
                Toggle("Do you want to receive notification?", isOn: $notificationToggle)
                    .padding()
                    .background(Color.inputGray)
                    .cornerRadius(15)
                
                VStack(alignment: .leading) {
                    Text("Max. distance for events")
                    Slider(value: $distance, in: 0...50, step: 1)
                    Text("\(Int(distance)) km")
                        .font(.headline)
                        .foregroundColor(.appMint)
                }
                .padding()
                .background(Color.inputGray)
                .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // FINE DEL FLUSSO: Impostiamo isLoggedIn a TRUE
            Button(action: {
                withAnimation {
                    isLoggedIn = true
                }
            }) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.white) // Testo bianco per contrasto finale
                    .padding()
                    .frame(width: 150)
                    .background(Color.black)
                    .cornerRadius(25)
            }
            .padding(.bottom, 50)
        }
    }
}

// --- COMPONENTI UI RIUTILIZZABILI ---

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .padding()
                .background(Color.inputGray)
                .cornerRadius(30)
                .padding(.horizontal, 40)
        } else {
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.inputGray)
                .cornerRadius(30)
                .padding(.horizontal, 40)
        }
    }
}

struct SocialButton: View {
    var text: String
    var icon: String
    var color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(30)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .padding(.horizontal, 40)
    }
}

struct GenderButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .gray)
                .padding()
                .frame(width: 100)
                .background(isSelected ? Color.appMint : Color.inputGray)
                .cornerRadius(20)
        }
    }
}

// Preview per testare SOLO questo flusso
struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
