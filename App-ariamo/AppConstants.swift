import SwiftUI
import Foundation
import Combine

// --- 1. COLOR CONFIGURATION ---
extension Color {
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

// Global Manager for Joined Activities (Singleton)
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    @Published var joinedActivities: [Activity] = []
    
    // Funzione per partecipare
    func join(activity: Activity) {
        if !joinedActivities.contains(where: { $0.id == activity.id }) {
            joinedActivities.append(activity)
        }
    }
    
    // NUOVA FUNZIONE: Per cancellare la partecipazione
    func leave(activity: Activity) {
        joinedActivities.removeAll { $0.id == activity.id }
    }
    
    // Helper per controllare lo stato
    func isJoined(activity: Activity) -> Bool {
        return joinedActivities.contains(where: { $0.id == activity.id })
    }
}

// --- 4. VALIDATION UTILS ---
struct Validator {
    static func isValidEmail(_ email: String) -> Bool {
        // Controllo semplice: deve avere @ e .
        // Esempio regex più robusta:
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        // Regole: Min 8 caratteri, almeno 1 numero, almeno 1 carattere speciale (punteggiatura)
        // (?=.*[0-9]) -> almeno un numero
        // (?=.*[^A-Za-z0-9]) -> almeno un carattere speciale
        // .{8,} -> lunghezza minima 8
        let passwordRegEx = "^(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
}

struct Activity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
    var description: String = "Activity description..."
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DatiEvento {
    var tipo: String = ""
    var data: Date = Date()
    var luogo: String = ""
}

struct UserProfile {
    var name: String
    var surname: String
    var age: Int
    var gender: String
    var bio: String
    var motto: String
    var image: String
    var profileImageData: Data? = nil
    var email: String
    var password: String
    var interests: Set<String>
    var shareLocation: Bool
    var notifications: Bool
    var maxDistance: Double
}
