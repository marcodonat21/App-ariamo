import SwiftUI
import Foundation
import Combine
import CoreLocation
import UserNotifications
import Supabase

// --- 1. CONFIGURAZIONE COLORI ---
extension Color {
    static let themeBackground = Color(UIColor.systemGroupedBackground)
    static let themeCard = Color(UIColor.secondarySystemGroupedBackground)
    static let themeInput = Color(UIColor.tertiarySystemGroupedBackground)
    static let themeText = Color.primary
    static let themeSecondaryText = Color.secondary
}

enum AppTab { case home, activities, profile, search }

// --- 2. FILTRI E IMPOSTAZIONI ---
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
    override init() { super.init(); UNUserNotificationCenter.current().delegate = self }
    func requestPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } }
    
    static func scheduleNotification(for activity: Activity) {
        let center = UNUserNotificationCenter.current()
        let ids = ["\(activity.id)_24", "\(activity.id)_1"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        func addRequest(id: String, title: String, body: String, date: Date) {
            if date > Date() {
                let content = UNMutableNotificationContent()
                content.title = title; content.body = body; content.sound = .default; content.userInfo = ["activityId": activity.id.uuidString]
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
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let idStr = userInfo["activityId"] as? String, let uuid = UUID(uuidString: idStr) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { ActivityManager.shared.openDetailFor(activityID: uuid) }
        }
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner, .sound]) }
}

// --- DTO PARTECIPANTI ---
struct ParticipantDTO: Codable, Identifiable {
    var id: Int?
    let activity_id: UUID
    let user_id: UUID
    let user_name: String
    let user_image: String?
    let user_age: Int?
    let user_bio: String?
    let user_country: String?
}

// STRUCT PER AGGIORNAMENTO
struct ParticipantUpdatePayload: Codable {
    let user_name: String
    let user_image: String? // Aggiunto per aggiornare foto
    let user_bio: String
    let user_age: Int
    let user_country: String
}

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    let supabaseURL = URL(string: "https://ywuvltphmcvtlswanmyj.supabase.co")!
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3dXZsdHBobWN2dGxzd2FubXlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk5MjEsImV4cCI6MjA4MTQ2NTkyMX0.mKW1vNu5EMKlxByD7HFLMcKcMr5G8vUiMc9dnfM5-2o"
    
    private var client: SupabaseClient
    
    @Published var allActivities: [Activity] = []
    @Published var joinedActivities: [Activity] = []
    @Published var createdActivities: [Activity] = []
    @Published var favoriteActivities: [UUID] = []
    @Published var participantsCache: [UUID: [ParticipantDTO]] = [:]
    
    @Published var showDetailFromNotification: Bool = false
    @Published var selectedActivityFromNotification: Activity? = nil
    
    private var isSaving = false
    
    static let userLocation = CLLocation(latitude: 40.8518, longitude: 14.2681)
    
    // TROVA QUESTA PARTE E SOSTITUISCILA COSÌ:
    static let defaultActivities: [Activity] = []
    // (Prima c'erano Maradona, Pizzeria ecc, ora li abbiamo cancellati)
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
        )
        
        loadLocalData()
        Task {
            await fetchActivities()
            await fetchMyJoinedActivities()
        }
    }
    
    // --- SUPABASE ACTIONS ---
    
    func fetchActivities() async {
        do {
            let dtos: [ActivityDTO] = try await client.from("activities").select().execute().value
            let activities = dtos.map { $0.toActivity() }
            DispatchQueue.main.async {
                self.allActivities = activities
                let myId = UserManager.shared.currentUser.id
                self.createdActivities = activities.filter { $0.creatorId == myId }
            }
        } catch { print("❌ Fetch error: \(error)") }
    }
    
    func fetchMyJoinedActivities() async {
        let myId = UserManager.shared.currentUser.id
        do {
            let myParticipations: [ParticipantDTO] = try await client.from("participants").select().eq("user_id", value: myId.uuidString).execute().value
            let activityIDs = myParticipations.map { $0.activity_id }
            DispatchQueue.main.async {
                self.joinedActivities = self.allActivities.filter { activityIDs.contains($0.id) }
            }
        } catch { print("❌ Error fetching my joined activities: \(error)") }
    }
    
    func create(activity: Activity) {
        guard !isSaving else { return }
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.isSaving = false }
        
        DispatchQueue.main.async {
            self.createdActivities.append(activity)
            self.allActivities.append(activity)
        }
        
        Task {
            var finalAct = activity
            let creatorId = UserManager.shared.currentUser.id
            if let data = activity.imageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "\(activity.id.uuidString).jpg"
                try? await client.storage.from("images").upload(path: fileName, file: comp, options: FileOptions(contentType: "image/jpeg"))
                let url = try? client.storage.from("images").getPublicURL(path: fileName)
                finalAct.imageURL = url?.absoluteString; finalAct.imageData = nil
            }
            let dto = ActivityDTO(from: finalAct, creatorIdOverride: creatorId)
            do {
                try await client.from("activities").insert(dto).execute()
                print("✅ Attività creata")
                joinActivityOnline(activity: finalAct)
            } catch {
                print("❌ DB error: \(error)")
                DispatchQueue.main.async {
                    self.createdActivities.removeAll { $0.id == activity.id }
                    self.allActivities.removeAll { $0.id == activity.id }
                }
            }
        }
    }
    
    func delete(activity: Activity) {
        DispatchQueue.main.async {
            self.createdActivities.removeAll { $0.id == activity.id }
            self.joinedActivities.removeAll { $0.id == activity.id }
            self.allActivities.removeAll { $0.id == activity.id }
            self.saveCreated(); self.saveJoined()
        }
        Task { try? await client.from("activities").delete().eq("id", value: activity.id.uuidString).execute() }
    }
    
    func updateActivity(_ updatedActivity: Activity) {
        DispatchQueue.main.async {
            if let i = self.createdActivities.firstIndex(where: { $0.id == updatedActivity.id }) { self.createdActivities[i] = updatedActivity }
            if let i = self.joinedActivities.firstIndex(where: { $0.id == updatedActivity.id }) { self.joinedActivities[i] = updatedActivity }
            if let i = self.allActivities.firstIndex(where: { $0.id == updatedActivity.id }) { self.allActivities[i] = updatedActivity }
            self.saveCreated(); self.saveJoined(); self.objectWillChange.send()
        }
        Task {
            var finalAct = updatedActivity
            if let data = finalAct.imageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "\(finalAct.id.uuidString).jpg"
                try? await client.storage.from("images").upload(path: fileName, file: comp, options: FileOptions(contentType: "image/jpeg", upsert: true))
                let url = try? client.storage.from("images").getPublicURL(path: fileName)
                finalAct.imageURL = url?.absoluteString; finalAct.imageData = nil
            }
            let dto = ActivityDTO(from: finalAct, creatorIdOverride: finalAct.creatorId)
            try? await client.from("activities").update(dto).eq("id", value: finalAct.id.uuidString).execute()
        }
    }

    // Sostituisci la vecchia joinActivityOnline con questa:
        func joinActivityOnline(activity: Activity) {
            // Se è un'attività di default (finta), unisciti solo localmente
            if ActivityManager.defaultActivities.contains(where: { $0.id == activity.id }) {
                DispatchQueue.main.async { self.join(activity: activity) }
                return
            }
            
            let user = UserManager.shared.currentUser
            
            Task {
                // 1. Determina quale immagine usare (URL o Icona)
                var finalUserImageString = user.image // Parte con il valore attuale (es. "person.fill" o un vecchio URL)
                
                // Se l'utente ha una foto in memoria (scelta in registrazione/profilo), CARICALA ORA
                if let data = user.profileImageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                    let fileName = "avatar_\(user.id.uuidString).jpg"
                    
                    // Upload su Supabase
                    try? await client.storage.from("images").upload(
                        path: fileName,
                        file: comp,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                    
                    // Ottieni URL Pubblico
                    if let url = try? client.storage.from("images").getPublicURL(path: fileName) {
                        finalUserImageString = url.absoluteString // Ecco l'URL della foto vera!
                    }
                }
                
                // 2. Crea il partecipante con la stringa dell'immagine corretta (URL o Icona)
                let p = ParticipantDTO(
                    activity_id: activity.id,
                    user_id: user.id,
                    user_name: "\(user.name) \(user.surname)",
                    user_image: finalUserImageString, // <--- QUI PASSA L'URL
                    user_age: user.age,
                    user_bio: user.bio,
                    user_country: user.country
                )
                
                do {
                    try await client.from("participants").insert(p).execute()
                    await fetchParticipants(for: activity.id)
                    DispatchQueue.main.async { self.join(activity: activity) }
                } catch {
                    print("❌ Join error: \(error)")
                }
            }
        }
    
    func refreshMyParticipantDetails() {
        let user = UserManager.shared.currentUser
        Task {
            var userImageUrl = user.image
            // Upload anche durante il refresh se necessario
            if let data = user.profileImageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "avatar_\(user.id.uuidString).jpg"
                try? await client.storage.from("images").upload(path: fileName, file: comp, options: FileOptions(contentType: "image/jpeg", upsert: true))
                if let url = try? client.storage.from("images").getPublicURL(path: fileName) {
                    userImageUrl = url.absoluteString
                }
            }
            
            let payload = ParticipantUpdatePayload(
                user_name: "\(user.name) \(user.surname)",
                user_image: userImageUrl, // Aggiorna anche la foto
                user_bio: user.bio,
                user_age: user.age,
                user_country: user.country
            )
            
            do {
                try await client.from("participants").update(payload).eq("user_id", value: user.id.uuidString).execute()
                print("✅ Dati aggiornati!")
            } catch { print("⚠️ Errore refresh: \(error)") }
        }
    }
    
    func leaveActivityOnline(activity: Activity) {
        let userId = UserManager.shared.currentUser.id
        Task {
            do {
                try await client.from("participants").delete().eq("activity_id", value: activity.id.uuidString).eq("user_id", value: userId.uuidString).execute()
                await fetchParticipants(for: activity.id)
                DispatchQueue.main.async { self.leave(activity: activity) }
            } catch { print("❌ Leave error: \(error)") }
        }
    }

    func fetchParticipants(for activityID: UUID) async {
        do {
            let res: [ParticipantDTO] = try await client.from("participants").select().eq("activity_id", value: activityID.uuidString).execute().value
            DispatchQueue.main.async { self.participantsCache[activityID] = res }
        } catch { print("❌ Error fetching participants") }
    }
    
    // Logica Locale
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: "joinedActivities"), let dec = try? JSONDecoder().decode([Activity].self, from: data) { self.joinedActivities = dec }
        if let data = UserDefaults.standard.data(forKey: "favorites"), let dec = try? JSONDecoder().decode([UUID].self, from: data) { self.favoriteActivities = dec }
    }
    func join(activity: Activity) { if !isJoined(activity: activity) { joinedActivities.append(activity); saveJoined(); NotificationHelper.scheduleNotification(for: activity) } }
    func leave(activity: Activity) { joinedActivities.removeAll { $0.id == activity.id }; saveJoined(); NotificationHelper.cancelNotification(for: activity) }
    func toggleFavorite(activity: Activity) { if favoriteActivities.contains(activity.id) { favoriteActivities.removeAll { $0 == activity.id } } else { favoriteActivities.append(activity.id) }; saveFavorites() }
    func isFavorite(activity: Activity) -> Bool { favoriteActivities.contains(activity.id) }
    func isCreator(activity: Activity) -> Bool { return activity.creatorId == UserManager.shared.currentUser.id }
    func isJoined(activity: Activity) -> Bool { joinedActivities.contains(where: { $0.id == activity.id }) }
    
    func openDetailFor(activityID: UUID) {
        let found = allActivities.first { $0.id == activityID } ?? ActivityManager.defaultActivities.first { $0.id == activityID }
        if let act = found { self.selectedActivityFromNotification = act; self.showDetailFromNotification = true }
    }
    private func saveJoined() { if let enc = try? JSONEncoder().encode(joinedActivities) { UserDefaults.standard.set(enc, forKey: "joinedActivities") } }
    private func saveCreated() { if let enc = try? JSONEncoder().encode(createdActivities) { UserDefaults.standard.set(enc, forKey: "createdActivities") } }
    private func saveFavorites() { if let enc = try? JSONEncoder().encode(favoriteActivities) { UserDefaults.standard.set(enc, forKey: "favorites") } }
}

struct ActivityDTO: Codable {
    let id: UUID; let title: String; let category: String; let image_url: String?; let image_name: String; let description: String; let date: Double; let location_name: String; let latitude: Double; let longitude: Double
    let creator_id: UUID?
    
    init(from act: Activity, creatorIdOverride: UUID? = nil) {
        id = act.id; title = act.title; category = act.category; image_url = act.imageURL; image_name = act.imageName; description = act.description; date = act.date.timeIntervalSince1970; location_name = act.locationName; latitude = act.latitude; longitude = act.longitude
        creator_id = creatorIdOverride ?? act.creatorId
    }
    
    func toActivity() -> Activity {
        var d: Data? = nil; if let u = image_url, let url = URL(string: u) { d = try? Data(contentsOf: url) }
        return Activity(id: id, title: title, category: category, imageName: image_name, imageData: d, imageURL: image_url, color: .appGreen, description: description, date: Date(timeIntervalSince1970: date), locationName: location_name, lat: latitude, lon: longitude, creatorId: creator_id ?? UUID())
    }
}

struct Activity: Identifiable, Hashable, Codable {
    let id: UUID; let title: String; let category: String; let imageName: String; var imageData: Data?; var imageURL: String?; let latitude: Double; let longitude: Double; var description: String; var date: Date; var locationName: String
    let creatorId: UUID
    
    init(id: UUID = UUID(), title: String, category: String = "Sports", imageName: String, imageData: Data? = nil, imageURL: String? = nil, color: Color, description: String = "", date: Date = Date(), locationName: String = "Naples", lat: Double = 40.85, lon: Double = 14.26, creatorId: UUID = UUID()) {
        self.id = id; self.title = title; self.category = category; self.imageName = imageName; self.imageData = imageData; self.imageURL = imageURL; self.description = description; self.date = date; self.locationName = locationName; self.latitude = lat; self.longitude = lon
        self.creatorId = creatorId
    }
    static func == (lhs: Activity, rhs: Activity) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var color: Color { .appGreen }
}

struct UserProfile: Identifiable, Codable { var id = UUID(); var name, surname: String; var age: Int; var gender, bio, motto, image: String; var profileImageData: Data? = nil; var email, password: String; var interests: Set<String>; var shareLocation, notifications: Bool; var country: String = "🇮🇹 Italy" }
extension UserProfile { static let testUser = UserProfile(name: "App", surname: "Ariamoci", age: 25, gender: "Non-binary", bio: "Welcome!", motto: "Let's connect!", image: "person.crop.circle.fill", profileImageData: nil, email: "test@email.com", password: "Appariamoci2025!", interests: [], shareLocation: true, notifications: true, country: "🇮🇹 Italy") }
class UserManager: ObservableObject { static let shared = UserManager(); @Published var currentUser: UserProfile; init() { if let d = UserDefaults.standard.data(forKey: "savedUser"), let dec = try? JSONDecoder().decode(UserProfile.self, from: d) { self.currentUser = dec } else { self.currentUser = UserProfile.testUser } }; func saveUser(_ u: UserProfile) { self.currentUser = u; if let enc = try? JSONEncoder().encode(u) { UserDefaults.standard.set(enc, forKey: "savedUser") } }; func deleteUser() { UserDefaults.standard.removeObject(forKey: "savedUser"); self.currentUser = UserProfile.testUser } }
struct Validator { static func isValidEmail(_ e: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: e) }; static func isValidPassword(_ p: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "^(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$").evaluate(with: p) } }
struct CustomBackButton: View { @Environment(\.presentationMode) var pm; var body: some View { Button(action: { pm.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) } } }
struct DatiEvento { var titolo, tipo, descrizione: String; var data: Date; var luogo: String; var imageData: Data?; var lat, lon: Double?; init() { titolo=""; tipo=""; descrizione=""; data=Date(); luogo=""; imageData=nil; lat=nil; lon=nil } }

// --- EXTENSION PER PREVIEW ---
extension Activity {
    static let testActivity = Activity(id: UUID(), title: "Test", imageName: "star", color: .blue, creatorId: UUID())
}
extension ParticipantDTO {
    static let testParticipant = ParticipantDTO(id: 1, activity_id: UUID(), user_id: UUID(), user_name: "Test", user_image: "person", user_age: 20, user_bio: "Bio", user_country: "Italy")
}
