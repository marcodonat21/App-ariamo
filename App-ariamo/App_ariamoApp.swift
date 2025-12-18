import SwiftUI

@main
struct App_ariamo: App {
    
    // *** FIX NOTIFICHE: INIZIALIZZA IL GESTORE APPENA L'APP PARTE ***
    init() {
        let _ = NotificationHelper.shared
    }
    
    var body: some Scene {
        WindowGroup {
            // Qui chiamiamo la tua vista radice che decide se mostrare Login o Home
            AppRootView()
                .preferredColorScheme(.light)
        }
    }
}
