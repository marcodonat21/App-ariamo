import SwiftUI

struct AppRootView: View {
    // *** FIX LOGIN: @AppStorage SALVA LO STATO NELLA MEMORIA DEL TELEFONO ***
    // Se è true, al prossimo avvio sarà ancora true.
    @AppStorage("isUserLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                // SE LOGGATO -> VAI ALL'APP
                ContentView(isLoggedIn: $isLoggedIn)
                    .transition(.opacity)
            } else {
                // SE NON LOGGATO -> VAI ALLA LANDING (LOGIN/REGISTRAZIONE)
                NavigationView {
                    AuthLandingScreen(isLoggedIn: $isLoggedIn)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isLoggedIn) // Transizione fluida
    }
}
