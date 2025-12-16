import SwiftUI
import Foundation
import Combine
import CoreLocation
import UserNotifications
import Supabase // <--- Assicurati che il pacchetto sia aggiunto

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

// GESTORE NOTIFICHE
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
        
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
        
        func addRequest(id: String, title: String, body: String, date: Date) {
            if date > Date() {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                content.userInfo = ["activityId": activity.id.uuidString]
                
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
        
        addRequest(id: ids[0], title: "Reminder: \(activity.title)", body: "Your activity is tomorrow!", date: activity.date.addingTimeInterval(-86400))
        addRequest(id: ids[1], title: "Get Ready: \(activity.title)", body: "Starts in 1 hour!", date: activity.date.addingTimeInterval(-3600))
    }
    
    static func cancelNotification(for activity: Activity) {
        let ids = ["\(activity.id)_24", "\(activity.id)_1"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }
    
    // GESTIONE CLICK NOTIFICA
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let activityIDString = userInfo["activityId"] as? String,
           let uuid = UUID(uuidString: activityIDString) {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                ActivityManager.shared.openDetailFor(activityID: uuid)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

// --- ACTIVITY MANAGER (SUPABASE COMPLETO: CREATE, UPDATE, DELETE) ---
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    // *** I TUOI DATI SUPABASE (GIA' INSERITI) ***
    let supabaseURL = URL(string: "https://ywuvltphmcvtlswanmyj.supabase.co")!
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3dXZsdHBobWN2dGxzd2FubXlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk5MjEsImV4cCI6MjA4MTQ2NTkyMX0.mKW1vNu5EMKlxByD7HFLMcKcMr5G8vUiMc9dnfM5-2o"
    
    private var client: SupabaseClient
    
    @Published var joinedActivities: [Activity] = []
    @Published var createdActivities: [Activity] = []
    @Published var favoriteActivities: [UUID] = []
    
    // Deep Linking
    @Published var selectedActivityFromNotification: Activity? = nil
    @Published var showDetailFromNotification: Bool = false
    
    static let userLocation = CLLocation(latitude: 40.8518, longitude: 14.2681)
    
    // DEFAULT FALLBACK
    static let defaultActivities: [Activity] = [
        Activity(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, title: "Da Michele Pizzeria", category: "Food", imageName: "fork.knife", imageData: UIImage(named: "pizza")?.jpegData(compressionQuality: 0.8), color: .orange, description: "La pizza più famosa di Napoli.", date: Date().addingTimeInterval(3600*24), locationName: "Via Cesare Sersale, 1", lat: 40.8498, lon: 14.2633),
        Activity(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Stadio Maradona", category: "Sports", imageName: "figure.soccer", imageData: UIImage(named: "stadium")?.jpegData(compressionQuality: 0.8), color: .blue, description: "Il tempio del calcio.", date: Date().addingTimeInterval(3600*48), locationName: "Piazzale Tecchio", lat: 40.8279, lon: 14.1930),
        Activity(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Passeggiata Lungomare", category: "Travel & Adventure", imageName: "sun.max.fill", imageData: UIImage(named: "sea")?.jpegData(compressionQuality: 0.8), color: .yellow, description: "Vista sul Vesuvio.", date: Date().addingTimeInterval(3600*5), locationName: "Via Caracciolo", lat: 40.8322, lon: 14.2426)
    ]
    
    init() {
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        loadLocalData()
        _ = NotificationHelper.shared
        Task { await fetchActivities() }
    }
    
    // --- 1. FETCH (SCARICA) ---
    func fetchActivities() async {
        do {
            let activities: [ActivityDTO] = try await client.from("activities").select().execute().value
            DispatchQueue.main.async {
                self.createdActivities = activities.map { $0.toActivity() }
                print("📡 Scaricati \(self.createdActivities.count) eventi da Supabase")
            }
        } catch {
            print("❌ Errore Supabase Fetch: \(error)")
        }
    }
    
    // --- 2. CREATE (CREA) ---
    func create(activity: Activity) {
        // UI Immediata
        DispatchQueue.main.async {
            self.createdActivities.append(activity)
            self.join(activity: activity)
        }
        
        Task {
            var finalActivity = activity
            // Upload Foto se presente
            if let data = activity.imageData, let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "\(activity.id.uuidString).jpg"
                do {
                    try await client.storage.from("images").upload(path: fileName, file: compressed, options: FileOptions(contentType: "image/jpeg"))
                    let publicURL = try client.storage.from("images").getPublicURL(path: fileName)
                    finalActivity.imageURL = publicURL.absoluteString
                    finalActivity.imageData = nil
                } catch { print("⚠️ Errore upload foto: \(error)") }
            }
            // Salva nel DB
            do {
                let dto = ActivityDTO(from: finalActivity)
                try await client.from("activities").insert(dto).execute()
                print("✅ CREATE SUCCESSO: Attività salvata online!")
            } catch { print("❌ ERRORE CREATE DB: \(error)") }
        }
    }
    
    // --- 3. DELETE (CANCELLA) ---
    func delete(activity: Activity) {
        // 1. Rimuovi subito dalla UI locale (Ottimistico)
        DispatchQueue.main.async {
            self.createdActivities.removeAll { $0.id == activity.id }
            self.joinedActivities.removeAll { $0.id == activity.id }
            self.saveCreated()
            self.saveJoined()
        }
        
        // 2. Cancella da Supabase
        Task {
            do {
                // Cancella la riga dove id == activity.id
                try await client.from("activities").delete().eq("id", value: activity.id.uuidString).execute()
                print("🗑️ DELETE SUCCESSO: Attività eliminata online!")
                
                // Opzionale: Prova a cancellare anche la foto dallo storage (se esiste)
                // Non è critico se fallisce, quindi ignoriamo errori qui
                let fileName = "\(activity.id.uuidString).jpg"
                let _ = try? await client.storage.from("images").remove(paths: [fileName])
                
            } catch {
                print("❌ ERRORE DELETE DB: \(error)")
                // Se fallisce, in teoria dovremmo rimetterla nella UI, ma per ora lasciamo così
            }
        }
    }
    
    // --- 4. UPDATE (MODIFICA SENZA DUPLICATI) ---
        func updateActivity(_ updatedActivity: Activity) {
            // 1. Aggiorna subito la UI locale
            DispatchQueue.main.async {
                if let index = self.createdActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
                    self.createdActivities[index] = updatedActivity
                }
                if let index = self.joinedActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
                    self.joinedActivities[index] = updatedActivity
                }
                self.objectWillChange.send()
            }
            
            // 2. Aggiorna su Supabase
            Task {
                var finalActivity = updatedActivity
                
                // Gestione Foto con Sovrascrittura (Upsert)
                if let data = finalActivity.imageData, let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                    let fileName = "\(finalActivity.id.uuidString).jpg"
                    do {
                        // 'upsert: true' dice a Supabase di sovrascrivere la vecchia foto
                        try await client.storage.from("images").upload(path: fileName, file: compressed, options: FileOptions(contentType: "image/jpeg", upsert: true))
                        
                        let publicURL = try client.storage.from("images").getPublicURL(path: fileName)
                        finalActivity.imageURL = publicURL.absoluteString
                        finalActivity.imageData = nil
                    } catch { print("⚠️ Errore foto: \(error)") }
                }
                
                // Salva le modifiche nel Database
                do {
                    let dto = ActivityDTO(from: finalActivity)
                    // .update() modifica la riga, .eq() trova quella con l'ID giusto
                    try await client.from("activities")
                        .update(dto)
                        .eq("id", value: finalActivity.id.uuidString)
                        .execute()
                    print("✏️ UPDATE SUCCESSO: Nessun duplicato creato!")
                } catch {
                    print("❌ ERRORE UPDATE DB: \(error)")
                }
            }
        }
    
    // --- Funzioni Locali (Join/Preferiti) ---
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: "joinedActivities"), let decoded = try? JSONDecoder().decode([Activity].self, from: data) { self.joinedActivities = decoded }
        if let data = UserDefaults.standard.data(forKey: "favorites"), let decoded = try? JSONDecoder().decode([UUID].self, from: data) { self.favoriteActivities = decoded }
    }
    
    func openDetailFor(activityID: UUID) {
        let found = createdActivities.first { $0.id == activityID }
            ?? joinedActivities.first { $0.id == activityID }
            ?? ActivityManager.defaultActivities.first { $0.id == activityID }
        if let act = found { self.selectedActivityFromNotification = act; self.showDetailFromNotification = true }
    }
    
    func join(activity: Activity) { if !joinedActivities.contains(where: { $0.id == activity.id }) { joinedActivities.append(activity); saveJoined(); NotificationHelper.scheduleNotification(for: activity) } }
    func leave(activity: Activity) { joinedActivities.removeAll { $0.id == activity.id }; saveJoined(); NotificationHelper.cancelNotification(for: activity) }
    
    func toggleFavorite(activity: Activity) { if favoriteActivities.contains(activity.id) { favoriteActivities.removeAll { $0 == activity.id } } else { favoriteActivities.append(activity.id) }; saveFavorites() }
    func isFavorite(activity: Activity) -> Bool { return favoriteActivities.contains(activity.id) }
    func isJoined(activity: Activity) -> Bool { return joinedActivities.contains(where: { $0.id == activity.id }) }
    func isCreator(activity: Activity) -> Bool {
        // Verifica se l'ID esiste tra quelle create
        // (Nota: in un'app reale controlleremmo l'User ID, ma per ora va bene così)
        return createdActivities.contains(where: { $0.id == activity.id })
    }
    
    private func saveJoined() { if let encoded = try? JSONEncoder().encode(joinedActivities) { UserDefaults.standard.set(encoded, forKey: "joinedActivities") } }
    private func saveCreated() { if let encoded = try? JSONEncoder().encode(createdActivities) { UserDefaults.standard.set(encoded, forKey: "createdActivities") } }
    private func saveFavorites() { if let encoded = try? JSONEncoder().encode(favoriteActivities) { UserDefaults.standard.set(encoded, forKey: "favorites") } }
}

// --- DTO: Struttura per Supabase (Mappa le colonne del DB snake_case) ---
struct ActivityDTO: Codable {
    let id: UUID
    let title: String
    let category: String
    let image_url: String?      // snake_case per DB
    let image_name: String      // snake_case per DB
    let description: String
    let date: Double            // Timestamp
    let location_name: String
    let latitude: Double
    let longitude: Double
    let color_hex: String
    
    init(from activity: Activity) {
        self.id = activity.id
        self.title = activity.title
        self.category = activity.category
        self.image_url = activity.imageURL
        self.image_name = activity.imageName
        self.description = activity.description
        self.date = activity.date.timeIntervalSince1970
        self.location_name = activity.locationName
        self.latitude = activity.latitude
        self.longitude = activity.longitude
        self.color_hex = activity.color.description
    }
    
    func toActivity() -> Activity {
        // Scarica immagine sincrona se presente URL (per semplicità in visualizzazione mappa)
        var imgData: Data? = nil
        if let urlStr = image_url, let url = URL(string: urlStr) {
             imgData = try? Data(contentsOf: url)
        }
        
        return Activity(
            id: id,
            title: title,
            category: category,
            imageName: image_name,
            imageData: imgData,
            imageURL: image_url,
            color: .green,
            description: description,
            date: Date(timeIntervalSince1970: date),
            location_name: location_name,
            lat: latitude,
            lon: longitude
        )
    }
}

// --- ACTIVITY STRUCT ---
struct CodableColor: Codable { let red, green, blue, opacity: Double }
struct Activity: Identifiable, Hashable, Codable {
    let id: UUID; let title: String; let category: String; let imageName: String;
    var imageData: Data?; var imageURL: String?
    let latitude: Double; let longitude: Double; private let codableColor: CodableColor; var description: String; var date: Date; var locationName: String
    
    // INIT MODIFICATO PER GESTIRE location_name
    init(id: UUID = UUID(), title: String, category: String = "Sports", imageName: String, imageData: Data? = nil, imageURL: String? = nil, color: Color, description: String = "Activity description...", date: Date = Date(), locationName: String = "Naples, IT", location_name: String? = nil, lat: Double = 40.8518, lon: Double = 14.2681) {
        self.id = id; self.title = title; self.category = category; self.imageName = imageName; self.imageData = imageData; self.imageURL = imageURL; self.description = description; self.date = date;
        // Priorità al parametro locationName, altrimenti usa location_name (dal DB), altrimenti default
        self.locationName = locationName != "Naples, IT" ? locationName : (location_name ?? "Naples, IT")
        self.latitude = lat; self.longitude = lon
        if color == .red { self.codableColor = CodableColor(red: 1, green: 0, blue: 0, opacity: 1) } else if color == .orange { self.codableColor = CodableColor(red: 1, green: 0.5, blue: 0, opacity: 1) } else if color == .yellow { self.codableColor = CodableColor(red: 1, green: 1, blue: 0, opacity: 1) } else { self.codableColor = CodableColor(red: 0, green: 1, blue: 0, opacity: 1) }
    }
    
    var color: Color { Color(.sRGB, red: codableColor.red, green: codableColor.green, blue: codableColor.blue, opacity: codableColor.opacity) }
    static func == (lhs: Activity, rhs: Activity) -> Bool { return lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// ... (UserProfile, Validator, CustomBackButton, DatiEvento, UserManager rimangono invariati)
struct UserProfile: Identifiable, Codable { var id = UUID(); var name: String; var surname: String; var age: Int; var gender: String; var bio: String; var motto: String; var image: String; var profileImageData: Data? = nil; var email: String; var password: String; var interests: Set<String>; var shareLocation: Bool; var notifications: Bool }
extension UserProfile { static let testUser = UserProfile(name: "App", surname: "Ariamoci", age: 25, gender: "Non-binary", bio: "Welcome!", motto: "Let's connect!", image: "person.crop.circle.fill", profileImageData: nil, email: "test@email.com", password: "Appariamoci2025!", interests: [], shareLocation: true, notifications: true) }
struct Validator { static func isValidEmail(_ e: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: e) }; static func isValidPassword(_ p: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "^(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$").evaluate(with: p) } }
struct CustomBackButton: View { @Environment(\.presentationMode) var presentationMode; var body: some View { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) } } }
struct DatiEvento { var titolo: String = ""; var tipo: String = ""; var descrizione: String = ""; var data: Date = Date(); var luogo: String = ""; var imageData: Data? = nil; var lat: Double? = nil; var lon: Double? = nil }
class UserManager: ObservableObject { static let shared = UserManager(); @Published var currentUser: UserProfile; init() { if let data = UserDefaults.standard.data(forKey: "savedUser"), let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) { self.currentUser = decoded } else { self.currentUser = UserProfile.testUser } }; func saveUser(_ user: UserProfile) { self.currentUser = user; if let encoded = try? JSONEncoder().encode(user) { UserDefaults.standard.set(encoded, forKey: "savedUser") } }; func deleteUser() { UserDefaults.standard.removeObject(forKey: "savedUser"); self.currentUser = UserProfile.testUser } }
