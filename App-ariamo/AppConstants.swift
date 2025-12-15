import SwiftUI
import Foundation

// --- 1. COLOR CONFIGURATION ---
extension Color {
    // Note: Assuming appGreen, appMint, appDarkText are defined elsewhere or implicitly used
    // Default system colors
    static let inputGray = Color(UIColor.systemGray6)
    
    // Glassmorphism Colors
    static let neonPurple = Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.6)
    static let neonBlue = Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.6)
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.5).opacity(0.6)
    static let neonOrange = Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.6)
    static let glassPurple = Color.purple.opacity(0.4)
    static let glassOrange = Color.orange.opacity(0.4)
}

// --- 2. TAB ENUM ---
enum Tab {
    case home
    case activities
    case profile
    case search
}

// --- 3. DATA MODELS ---

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color // PARAMETRO NECESSARIO
    var description: String = "Activity description..." // L'ho spostato in fondo per il default
}

struct DatiEvento { // Event Data
    var tipo: String = "" // Type
    var data: Date = Date() // Date
    var luogo: String = "" // Location
}

struct UserProfile {
    // Basic Info
    var name: String
    var surname: String
    var age: Int
    var gender: String
    var bio: String
    var motto: String
    
    // PROFILE PHOTO
    var image: String // Fallback (default avatar)
    var profileImageData: Data? = nil // NEW: Real photo data saved here
    
    // Account
    var email: String
    var password: String
    
    // Interests and Preferences
    var interests: Set<String>
    var shareLocation: Bool
    var notifications: Bool
    var maxDistance: Double
}
