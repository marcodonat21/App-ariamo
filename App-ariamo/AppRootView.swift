import SwiftUI

struct AppRootView: View {
    // USIAMO APPSTORAGE PER MANTENERE IL LOGIN SALVATO
    @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
    
    var body: some View {
        Group {
            if isUserLoggedIn {
                // Passiamo il binding a ContentView per gestire il Logout
                ContentView(isLoggedIn: $isUserLoggedIn)
                    .transition(.move(edge: .trailing))
            } else {
                NavigationView {
                    AuthLandingScreen(isLoggedIn: $isUserLoggedIn)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .accentColor(.black)
            }
        }
    }
}

#Preview {
    AppRootView()
}
