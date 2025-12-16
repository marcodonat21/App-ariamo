import SwiftUI
import Foundation
import Combine
import CoreLocation
import UserNotifications

// --- 1. COLOR CONFIGURATION ---
extension Color {
    static let themeBackground = Color(UIColor.systemGroupedBackground)
    static let themeCard = Color(UIColor.secondarySystemGroupedBackground)
    static let themeInput = Color(UIColor.tertiarySystemGroupedBackground)
    static let themeText = Color.primary
    static let themeSecondaryText = Color.secondary
}

enum AppTab { case home, activities, profile, search }

// --- 2. FILTRI ---
enum SortOption: String, CaseIterable { case name = "Name"; case date = "Date" }
enum ParticipationFilter: String, CaseIterable { case all = "All"; case joined = "Joined"; case favorites = "Favorites"; case notJoined = "Not Joined" }

class FilterSettings: ObservableObject {
    @Published var sortOption: SortOption = .date
    @Published var isAscending: Bool = true
    @Published var enableDateFilter: Bool = false
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date().addingTimeInterval(3600 * 24 * 30)
    @Published var enableTimeFilter: Bool = false
    @Published var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @Published var endTime: Date = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()
    @Published var participationStatus: ParticipationFilter = .all
    @Published var enableDistanceFilter: Bool = false
    @Published var maxDistanceKm: Double = 10.0
    
    func apply(to activities: [Activity]) -> [Activity] {
        var result = activities
        let manager = ActivityManager.shared
        let userLoc = ActivityManager.userLocation
        
        if enableDateFilter { result = result.filter { $0.date >= startDate && $0.date <= endDate } }
        if enableTimeFilter {
            let calendar = Calendar.current
            let startM = calendar.component(.hour, from: startTime) * 60 + calendar.component(.minute, from: startTime)
            let endM = calendar.component(.hour, from: endTime) * 60 + calendar.component(.minute, from: endTime)
            result = result.filter { act in
                let actM = calendar.component(.hour, from: act.date) * 60 + calendar.component(.minute, from: act.date)
                return actM >= startM && actM <= endM
            }
        }
        switch participationStatus {
        case .joined: result = result.filter { manager.isJoined(activity: $0) }
        case .favorites: result = result.filter { manager.isFavorite(activity: $0) }
        case .notJoined: result = result.filter { !manager.isJoined(activity: $0) }
        case .all: break
        }
        if enableDistanceFilter {
            result = result.filter { act in
                let actLoc = CLLocation(latitude: act.latitude, longitude: act.longitude)
                return (actLoc.distance(from: userLoc) / 1000.0) <= maxDistanceKm
            }
        }
        result.sort { a, b in
            switch sortOption {
            case .name: return isAscending ? a.title < b.title : a.title > b.title
            case .date: return isAscending ? a.date < b.date : a.date > b.date
            }
        }
        return result
    }
}

// --- 3. MANAGERS ---

class NotificationHelper: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHelper()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    static func scheduleNotification(for activity: Activity) {
        let center = UNUserNotificationCenter.current()
        let ids = ["\(activity.id)_24", "\(activity.id)_1"]
        
        // 1. PULIZIA AGGRESSIVA (Rimuove sia le future che quelle già arrivate nel centro notifiche)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
        
        // Funzione helper interna per creare la richiesta
        func addRequest(id: String, title: String, body: String, date: Date) {
            if date > Date() {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                content.userInfo = ["activityId": activity.id.uuidString] // ID per Deep Link
                
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error { print("Errore notifica: \(error.localizedDescription)") }
                }
            }
        }
        
        // Notifica 24 ore prima
        addRequest(id: ids[0], title: "Reminder: \(activity.title)", body: "Your activity is tomorrow!", date: activity.date.addingTimeInterval(-86400))
        
        // Notifica 1 ora prima
        addRequest(id: ids[1], title: "Get Ready: \(activity.title)", body: "Starts in 1 hour!", date: activity.date.addingTimeInterval(-3600))
    }
    
    static func cancelNotification(for activity: Activity) {
        let ids = ["\(activity.id)_24", "\(activity.id)_1"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }
    
    // GESTIONE CLICK NOTIFICA (Deep Link)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let activityIDString = userInfo["activityId"] as? String,
           let uuid = UUID(uuidString: activityIDString) {
            
            print("Notifica cliccata per ID: \(uuid)")
            
            // *** FIX CRUCIALE: RITARDO DI 0.8 SECONDI ***
            // Diamo tempo all'app di caricare la Home/Mappa completamente prima di aprire il dettaglio
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                ActivityManager.shared.openDetailFor(activityID: uuid)
            }
        }
        completionHandler()
    }
    
    // MOSTRA NOTIFICA ANCHE A APP APERTA
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    @Published var joinedActivities: [Activity] = []
    @Published var createdActivities: [Activity] = []
    @Published var favoriteActivities: [UUID] = []
    
    // DEEP LINKING VARIABLES
    @Published var selectedActivityFromNotification: Activity? = nil
    @Published var showDetailFromNotification: Bool = false
    
    static let userLocation = CLLocation(latitude: 40.8518, longitude: 14.2681)
    
    static let defaultActivities: [Activity] = [
        Activity(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, title: "Da Michele Pizzeria", category: "Food", imageName: "fork.knife", imageData: UIImage(named: "pizza")?.jpegData(compressionQuality: 0.8), color: .orange, description: "Naples' most famous pizza.", date: Date().addingTimeInterval(3600*24), locationName: "Via Cesare Sersale, 1", lat: 40.8498, lon: 14.2633),
        Activity(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Maradona Stadium", category: "Sports", imageName: "figure.soccer", imageData: UIImage(named: "stadium")?.jpegData(compressionQuality: 0.8), color: .blue, description: "The temple of football.", date: Date().addingTimeInterval(3600*48), locationName: "Piazzale Tecchio", lat: 40.8279, lon: 14.1930),
        Activity(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Waterfront Walk", category: "Travel & Adventure", imageName: "sun.max.fill", imageData: UIImage(named: "sea")?.jpegData(compressionQuality: 0.8), color: .yellow, description: "Walk with a view of Vesuvius.", date: Date().addingTimeInterval(3600*5), locationName: "Via Caracciolo", lat: 40.8322, lon: 14.2426)
    ]
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "joinedActivities"), let decoded = try? JSONDecoder().decode([Activity].self, from: data) { self.joinedActivities = decoded }
        if let data = UserDefaults.standard.data(forKey: "createdActivities"), let decoded = try? JSONDecoder().decode([Activity].self, from: data) { self.createdActivities = decoded }
        if let data = UserDefaults.standard.data(forKey: "favorites"), let decoded = try? JSONDecoder().decode([UUID].self, from: data) { self.favoriteActivities = decoded }
        
        // Attiva il delegate delle notifiche
        _ = NotificationHelper.shared
    }
    
    func openDetailFor(activityID: UUID) {
        // Cerca l'attività tra tutte quelle disponibili
        let found = joinedActivities.first { $0.id == activityID }
            ?? createdActivities.first { $0.id == activityID }
            ?? ActivityManager.defaultActivities.first { $0.id == activityID }
        
        if let act = found {
            print("Apro dettaglio per: \(act.title)")
            self.selectedActivityFromNotification = act
            self.showDetailFromNotification = true
        } else {
            print("Attività non trovata per ID: \(activityID)")
        }
    }
    
    func join(activity: Activity) { if !joinedActivities.contains(where: { $0.id == activity.id }) { joinedActivities.append(activity); saveJoined(); NotificationHelper.scheduleNotification(for: activity) } }
    func leave(activity: Activity) { joinedActivities.removeAll { $0.id == activity.id }; saveJoined(); NotificationHelper.cancelNotification(for: activity) }
    func delete(activity: Activity) { createdActivities.removeAll { $0.id == activity.id }; joinedActivities.removeAll { $0.id == activity.id }; saveCreated(); saveJoined() }
    func updateActivity(_ updatedActivity: Activity) { if let index = createdActivities.firstIndex(where: { $0.id == updatedActivity.id }) { createdActivities[index] = updatedActivity; saveCreated() }; if let index = joinedActivities.firstIndex(where: { $0.id == updatedActivity.id }) { joinedActivities[index] = updatedActivity; saveJoined() }; objectWillChange.send() }
    func toggleFavorite(activity: Activity) { if favoriteActivities.contains(activity.id) { favoriteActivities.removeAll { $0 == activity.id } } else { favoriteActivities.append(activity.id) }; saveFavorites() }
    func isFavorite(activity: Activity) -> Bool { return favoriteActivities.contains(activity.id) }
    func isJoined(activity: Activity) -> Bool { return joinedActivities.contains(where: { $0.id == activity.id }) }
    func isCreator(activity: Activity) -> Bool { return createdActivities.contains(where: { $0.id == activity.id }) }
    func create(activity: Activity) { createdActivities.append(activity); saveCreated(); join(activity: activity) }
    
    private func saveJoined() { if let encoded = try? JSONEncoder().encode(joinedActivities) { UserDefaults.standard.set(encoded, forKey: "joinedActivities") } }
    private func saveCreated() { if let encoded = try? JSONEncoder().encode(createdActivities) { UserDefaults.standard.set(encoded, forKey: "createdActivities") } }
    private func saveFavorites() { if let encoded = try? JSONEncoder().encode(favoriteActivities) { UserDefaults.standard.set(encoded, forKey: "favorites") } }
}

struct CodableColor: Codable { let red, green, blue, opacity: Double }
struct Activity: Identifiable, Hashable, Codable {
    let id: UUID; let title: String; let category: String; let imageName: String; let imageData: Data?; let latitude: Double; let longitude: Double; private let codableColor: CodableColor; var description: String; var date: Date; var locationName: String
    init(id: UUID = UUID(), title: String, category: String = "Sports", imageName: String, imageData: Data? = nil, color: Color, description: String = "Activity description...", date: Date = Date(), locationName: String = "Naples, IT", lat: Double = 40.8518, lon: Double = 14.2681) {
        self.id = id; self.title = title; self.category = category; self.imageName = imageName; self.imageData = imageData; self.description = description; self.date = date; self.locationName = locationName; self.latitude = lat; self.longitude = lon
        if color == .red { self.codableColor = CodableColor(red: 1, green: 0, blue: 0, opacity: 1) } else if color == .orange { self.codableColor = CodableColor(red: 1, green: 0.5, blue: 0, opacity: 1) } else if color == .yellow { self.codableColor = CodableColor(red: 1, green: 1, blue: 0, opacity: 1) } else { self.codableColor = CodableColor(red: 0, green: 1, blue: 0, opacity: 1) }
    }
    var color: Color { Color(.sRGB, red: codableColor.red, green: codableColor.green, blue: codableColor.blue, opacity: codableColor.opacity) }
    static func == (lhs: Activity, rhs: Activity) -> Bool { return lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
struct UserProfile: Identifiable, Codable { var id = UUID(); var name: String; var surname: String; var age: Int; var gender: String; var bio: String; var motto: String; var image: String; var profileImageData: Data? = nil; var email: String; var password: String; var interests: Set<String>; var shareLocation: Bool; var notifications: Bool }
extension UserProfile { static let testUser = UserProfile(name: "App", surname: "Ariamoci", age: 25, gender: "Non-binary", bio: "Welcome!", motto: "Let's connect!", image: "person.crop.circle.fill", profileImageData: nil, email: "test@email.com", password: "Appariamoci2025!", interests: [], shareLocation: true, notifications: true) }
struct Validator { static func isValidEmail(_ e: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: e) }; static func isValidPassword(_ p: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "^(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$").evaluate(with: p) } }
struct CustomBackButton: View { @Environment(\.presentationMode) var presentationMode; var body: some View { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) } } }
struct DatiEvento { var titolo: String = ""; var tipo: String = ""; var descrizione: String = ""; var data: Date = Date(); var luogo: String = ""; var imageData: Data? = nil; var lat: Double? = nil; var lon: Double? = nil }
class UserManager: ObservableObject { static let shared = UserManager(); @Published var currentUser: UserProfile; init() { if let data = UserDefaults.standard.data(forKey: "savedUser"), let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) { self.currentUser = decoded } else { self.currentUser = UserProfile.testUser } }; func saveUser(_ user: UserProfile) { self.currentUser = user; if let encoded = try? JSONEncoder().encode(user) { UserDefaults.standard.set(encoded, forKey: "savedUser") } }; func deleteUser() { UserDefaults.standard.removeObject(forKey: "savedUser"); self.currentUser = UserProfile.testUser } }
