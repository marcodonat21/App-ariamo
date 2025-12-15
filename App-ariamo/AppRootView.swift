import SwiftUI

// AppRootView is the entry point that decides whether to show the Home or Authentication.
struct AppRootView: View {
    
    // The state that tracks user authentication.
    // In a real app, this would be read from an authentication service.
    @State private var isUserLoggedIn: Bool = false
    
    var body: some View {
        Group {
            if isUserLoggedIn {
                // USER LOGGED IN: Show Home (ContentView)
                ContentView()
                    .transition(.move(edge: .trailing)) // Adds a visual transition
            } else {
                // USER NOT LOGGED IN: Show the choice screen (Login or Registration)
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
