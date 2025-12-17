import SwiftUI

struct AppRootView: View {
    // Mantieni @AppStorage per sapere se l'utente è loggato o no
    @AppStorage("isUserLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        // Mostriamo sempre la ContentView (con la mappa).
        // Il login verrà richiesto solo quando necessario (join, create, profile)
        ContentView(isLoggedIn: $isLoggedIn)
            .transition(.opacity)
            .animation(.easeInOut, value: isLoggedIn)
    }
}
