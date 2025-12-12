import SwiftUI

// AppRootView è il punto d'ingresso che decide se mostrare la Home o l'Autenticazione.
struct AppRootView: View {
    
    // Lo stato che traccia l'autenticazione dell'utente.
    // In un'app reale, questo verrebbe letto da un servizio di autenticazione.
    @State private var isUserLoggedIn: Bool = false
    
    var body: some View {
        Group {
            if isUserLoggedIn {
                // UTENTE LOGGATO: Mostra la Home (ContentView)
                ContentView()
                    .transition(.move(edge: .trailing)) // Aggiunge una transizione visiva
            } else {
                // UTENTE NON LOGGATO: Mostra la schermata di scelta (Login o Registrazione)
                NavigationView {
                    AuthLandingScreen(isLoggedIn: $isUserLoggedIn)
                }
                .accentColor(.black)
            }
        }
    }
}

// Preview
#Preview {
    AppRootView()
}
