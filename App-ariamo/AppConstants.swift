import SwiftUI
import Foundation

// --- 1. CONFIGURAZIONE COLORI ---
extension Color {
    static let inputGray = Color(UIColor.systemGray6)
    
    // Colori Glassmorphism
    static let neonPurple = Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.6)
    static let neonBlue = Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.6)
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.5).opacity(0.6)
    static let neonOrange = Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.6)
    static let glassPurple = Color.purple.opacity(0.4)
    static let glassOrange = Color.orange.opacity(0.4)
}

// --- 2. ENUM TAB ---
enum Tab {
    case home
    case activities
    case profile
    case search
}

// --- 3. MODELLI DATI ---

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    var description: String = "Descrizione dell'attività..."
}

struct DatiEvento {
    var tipo: String = ""
    var data: Date = Date()
    var luogo: String = ""
}

struct UserProfile {
    // Info Base
    var name: String
    var surname: String
    var age: Int
    var gender: String
    var bio: String
    var motto: String
    
    // FOTO PROFILO
    var image: String // Fallback (avatar default)
    var profileImageData: Data? = nil // NUOVO: Qui salviamo la foto reale
    
    // Account
    var email: String
    var password: String
    
    // Interessi e Preferenze
    var interests: Set<String>
    var shareLocation: Bool
    var notifications: Bool
    var maxDistance: Double
}
