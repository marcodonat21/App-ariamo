import SwiftUI

struct AuthLandingScreen: View {
    
    // Binding per modificare lo stato di login in AppRootView (per tornare alla Home)
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            
            Spacer()
            
            // Titolo App (Stile dal flusso AuthFlow precedente)
            Text("app-ariamo")
                .font(.system(size: 40, weight: .heavy))
                .foregroundColor(.orange)
                .padding(.bottom, 10)
            
            Text("Benvenuto! Scegli come accedere.")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)

            Spacer()
            
            // --- BOTTONE 1: REGISTRAZIONE ---
            NavigationLink {
                CreateAccountStep1(isLoggedIn: $isLoggedIn) // In RegistrationFlow.swift
            } label: {
                Text("Crea un Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            // --- BOTTONE 2: LOGIN ---
            NavigationLink {
                LoginScreen(isLoggedIn: $isLoggedIn) // In LoginScreen.swift
            } label: {
                Text("Accedi (Login)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .padding(.horizontal, 40)
            
            // --- Bottoni Social (Ora usa la definizione GLOBALE da ReusableComponents.swift) ---
            VStack(spacing: 15) {
                Text("oppure accedi con")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    // Questa chiamata ora punta al componente nel file ReusableComponents.swift
                    SocialButtonSmall(icon: "applelogo")
                    SocialButtonSmall(icon: "g.circle.fill")
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
        }
        .padding(.vertical, 30)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// *** ATTENZIONE: La definizione di SocialButtonSmall DEVE ESSERE QUI RIMOSSA *** // *** (È stata spostata in ReusableComponents.swift) ***

// Preview
#Preview {
    AuthLandingScreen(isLoggedIn: .constant(false))
}
