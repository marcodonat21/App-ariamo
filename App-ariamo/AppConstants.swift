import SwiftUI
import Foundation
import Combine
import CoreLocation
import UserNotifications
import Supabase
import EventKit // <--- NUOVO IMPORT FONDAMENTALE

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

// --- CALENDAR MANAGER (NUOVO) ---
class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }
    
    func addEvent(for activity: Activity) {
        requestAccess { granted in
            guard granted else { return }
            
            let event = EKEvent(eventStore: self.eventStore)
            event.title = "App-ariamo: \(activity.title)"
            event.startDate = activity.date
            event.endDate = activity.date.addingTimeInterval(3600) // Durata default 1 ora
            event.notes = activity.description + "\n\nLocation: \(activity.locationName)"
            event.calendar = self.eventStore.defaultCalendarForNewEvents
            
            do {
                try self.eventStore.save(event, span: .thisEvent)
                // Salviamo l'ID dell'evento per poterlo rimuovere dopo
                UserDefaults.standard.set(event.eventIdentifier, forKey: "calendar_event_\(activity.id.uuidString)")
                print("✅ Event added to calendar")
            } catch {
                print("❌ Failed to save event: \(error)")
            }
        }
    }
    
    func removeEvent(for activity: Activity) {
        requestAccess { granted in
            guard granted else { return }
            
            // Recuperiamo l'ID salvato
            if let eventID = UserDefaults.standard.string(forKey: "calendar_event_\(activity.id.uuidString)") {
                if let event = self.eventStore.event(withIdentifier: eventID) {
                    do {
                        try self.eventStore.remove(event, span: .thisEvent)
                        UserDefaults.standard.removeObject(forKey: "calendar_event_\(activity.id.uuidString)")
                        print("🗑️ Event removed from calendar")
                    } catch {
                        print("❌ Failed to remove event: \(error)")
                    }
                }
            }
        }
    }
}

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

struct ProfileTable: Codable {
    let id: UUID
    let name: String
    let surname: String
    let age: Int
    let gender: String
    let bio: String
    let motto: String?
    let country: String
    let interests: [String]
    let avatar_url: String?
}

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    let supabaseURL = URL(string: "https://ywuvltphmcvtlswanmyj.supabase.co")!
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3dXZsdHBobWN2dGxzd2FubXlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk5MjEsImV4cCI6MjA4MTQ2NTkyMX0.mKW1vNu5EMKlxByD7HFLMcKcMr5G8vUiMc9dnfM5-2o"
    
    var client: SupabaseClient
    
    @Published var allActivities: [Activity] = []
    @Published var joinedActivities: [Activity] = []
    @Published var createdActivities: [Activity] = []
    @Published var favoriteActivities: [UUID] = []
    
    var favoriteActivitiesList: [Activity] {
        return allActivities.filter { favoriteActivities.contains($0.id) }
    }
    
    @Published var participantsCache: [UUID: [ParticipantDTO]] = [:]
    
    @Published var showDetailFromNotification: Bool = false
    @Published var selectedActivityFromNotification: Activity? = nil
    
    @Published var shouldShowSuccessAfterLogin: Bool = false
    @Published var shouldShowFavoriteSuccessAfterLogin: Bool = false
    
    private var isSaving = false
    private var imageCache: [String: Data] = [:]
    
    // Timer per refresh automatico ogni 5 secondi
    private var refreshTimer: Timer?
    
    static var userLocation: CLLocation {
        return LocationManager.shared.userLocation ?? CLLocation(latitude: 40.8518, longitude: 14.2681)
    }

    static let defaultActivities: [Activity] = []
    
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
        
        // Avvia il timer di refresh automatico ogni 5 secondi
        startAutoRefresh()
    }
    
    // MARK: - Auto Refresh Timer
    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchActivities()
                // Refresh anche i partecipanti delle attività visualizzate
                if let self = self {
                    for activity in self.allActivities {
                        await self.fetchParticipants(for: activity.id)
                    }
                }
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    func loadImageAsync(from urlString: String) async -> Data? {
        if let cachedData = imageCache[urlString] { return cachedData }
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            imageCache[urlString] = data
            return data
        } catch { return nil }
    }
    
    func fetchActivities() async {
        do {
            let dtos: [ActivityDTO] = try await client.from("activities").select().execute().value
            var activities: [Activity] = []
            for dto in dtos {
                let activity = await dto.toActivity()
                activities.append(activity)
            }
            DispatchQueue.main.async {
                self.allActivities = activities
                if UserManager.shared.isLoggedIn {
                    let myId = UserManager.shared.currentUser.id
                    self.createdActivities = activities.filter { $0.creatorId == myId }
                    self.saveCreated() // ✅ Salva le attività create
                    print("✅ Fetched \(activities.count) activities, \(self.createdActivities.count) created by me")
                }
            }
        } catch { print("❌ Fetch error: \(error)") }
    }
    
    func fetchMyJoinedActivities() async {
        guard UserManager.shared.isLoggedIn else { return }
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
        
        let creatorId = UserManager.shared.currentUser.id
        
        // Creiamo una copia dell'attività con il creatorId corretto
        var activityWithCreator = activity
        activityWithCreator = Activity(
            id: activity.id,
            title: activity.title,
            category: activity.category,
            imageName: activity.imageName,
            imageData: activity.imageData,
            imageURL: activity.imageURL,
            color: activity.color,
            description: activity.description,
            date: activity.date,
            locationName: activity.locationName,
            lat: activity.latitude,
            lon: activity.longitude,
            creatorId: creatorId // ✅ Impostiamo il creatorId corretto
        )
        
        DispatchQueue.main.async {
            self.createdActivities.append(activityWithCreator)
            self.allActivities.append(activityWithCreator)
            self.saveCreated()
            print("✅ Activity created with creatorId: \(creatorId)")
        }
        
        Task {
            var finalAct = activityWithCreator
            if let data = activityWithCreator.imageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "\(activityWithCreator.id.uuidString).jpg"
                try? await client.storage.from("images").upload(path: fileName, file: comp, options: FileOptions(contentType: "image/jpeg"))
                let url = try? client.storage.from("images").getPublicURL(path: fileName)
                finalAct.imageURL = url?.absoluteString; finalAct.imageData = nil
            }
            let dto = ActivityDTO(from: finalAct, creatorIdOverride: creatorId)
            do {
                try await client.from("activities").insert(dto).execute()
                joinActivityOnline(activity: finalAct)
            } catch {
                DispatchQueue.main.async {
                    self.createdActivities.removeAll { $0.id == activityWithCreator.id }
                    self.allActivities.removeAll { $0.id == activityWithCreator.id }
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
            
            // RIMUOVI DAL CALENDARIO
            CalendarManager.shared.removeEvent(for: activity)
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

    func joinActivityOnline(activity: Activity) {
        if ActivityManager.defaultActivities.contains(where: { $0.id == activity.id }) {
            DispatchQueue.main.async { self.join(activity: activity) }
            return
        }
        let user = UserManager.shared.currentUser
        Task {
            var finalUserImageString = user.image
            if user.image == "person.circle" || user.image.isEmpty, let data = user.profileImageData, let comp = UIImage(data: data)?.jpegData(compressionQuality: 0.5) {
                let fileName = "avatar_\(user.id.uuidString).jpg"
                try? await client.storage.from("images").upload(path: fileName, file: comp, options: FileOptions(contentType: "image/jpeg", upsert: true))
                if let url = try? client.storage.from("images").getPublicURL(path: fileName) {
                    finalUserImageString = url.absoluteString
                }
            }
            
            let p = ParticipantDTO(
                activity_id: activity.id,
                user_id: user.id,
                user_name: "\(user.name) \(user.surname)",
                user_image: finalUserImageString,
                user_age: user.age,
                user_bio: user.bio,
                user_country: user.country
            )
            do {
                try await client.from("participants").insert(p).execute()
                await fetchParticipants(for: activity.id)
                DispatchQueue.main.async { self.join(activity: activity) }
            } catch { print("❌ Join error: \(error)") }
        }
    }
    
    func leaveActivityOnline(activity: Activity) {
        let userId = UserManager.shared.currentUser.id
        Task {
            do {
                try await client.from("participants").delete().eq("activity_id", value: activity.id.uuidString).eq("user_id", value: userId.uuidString).execute()
                await fetchParticipants(for: activity.id)
                DispatchQueue.main.async { self.leave(activity: activity) }
            } catch { print("❌ Leave error") }
        }
    }

    func fetchParticipants(for activityID: UUID) async {
        do {
            let res: [ParticipantDTO] = try await client.from("participants").select().eq("activity_id", value: activityID.uuidString).execute().value
            DispatchQueue.main.async { self.participantsCache[activityID] = res }
        } catch { print("❌ Error fetching participants") }
    }
    
    func clearUserData() {
        joinedActivities.removeAll()
        createdActivities.removeAll()
        favoriteActivities.removeAll()
        participantsCache.removeAll()
        UserDefaults.standard.removeObject(forKey: "joinedActivities")
        UserDefaults.standard.removeObject(forKey: "createdActivities")
        UserDefaults.standard.removeObject(forKey: "favorites")
    }
    
    private func loadLocalData() {
        if let data = UserDefaults.standard.data(forKey: "joinedActivities"), let dec = try? JSONDecoder().decode([Activity].self, from: data) { self.joinedActivities = dec }
        if let data = UserDefaults.standard.data(forKey: "createdActivities"), let dec = try? JSONDecoder().decode([Activity].self, from: data) { self.createdActivities = dec }
        if let data = UserDefaults.standard.data(forKey: "favorites"), let dec = try? JSONDecoder().decode([UUID].self, from: data) { self.favoriteActivities = dec }
        print("📦 Loaded local data - created: \(createdActivities.count), joined: \(joinedActivities.count), favorites: \(favoriteActivities.count)")
    }
    
    func join(activity: Activity) {
        if !isJoined(activity: activity) {
            joinedActivities.append(activity)
            saveJoined()
            NotificationHelper.scheduleNotification(for: activity)
            // AGGIUNGI AL CALENDARIO
            CalendarManager.shared.addEvent(for: activity)
        }
    }
    
    func leave(activity: Activity) {
        joinedActivities.removeAll { $0.id == activity.id }
        saveJoined()
        NotificationHelper.cancelNotification(for: activity)
        // RIMUOVI DAL CALENDARIO
        CalendarManager.shared.removeEvent(for: activity)
    }
    
    func toggleFavorite(activity: Activity) { if favoriteActivities.contains(activity.id) { favoriteActivities.removeAll { $0 == activity.id } } else { favoriteActivities.append(activity.id) }; saveFavorites() }
    func isFavorite(activity: Activity) -> Bool { favoriteActivities.contains(activity.id) }
    func isCreator(activity: Activity) -> Bool {
        let isInCreatedList = createdActivities.contains(where: { $0.id == activity.id })
        let matchesUserId = activity.creatorId == UserManager.shared.currentUser.id
        print("🔍 isCreator check - Activity: \(activity.title), isInCreatedList: \(isInCreatedList), matchesUserId: \(matchesUserId), creatorId: \(activity.creatorId), currentUserId: \(UserManager.shared.currentUser.id)")
        return isInCreatedList || matchesUserId
    }
    func isJoined(activity: Activity) -> Bool { joinedActivities.contains(where: { $0.id == activity.id }) }
    func openDetailFor(activityID: UUID) {
        if let found = allActivities.first(where: { $0.id == activityID }) { self.selectedActivityFromNotification = found; self.showDetailFromNotification = true }
    }
    private func saveJoined() { if let enc = try? JSONEncoder().encode(joinedActivities) { UserDefaults.standard.set(enc, forKey: "joinedActivities") } }
    private func saveCreated() { if let enc = try? JSONEncoder().encode(createdActivities) { UserDefaults.standard.set(enc, forKey: "createdActivities") } }
    private func saveFavorites() { if let enc = try? JSONEncoder().encode(favoriteActivities) { UserDefaults.standard.set(enc, forKey: "favorites") } }
}

struct ActivityDTO: Codable {
    let id: UUID; let title: String; let category: String; let image_url: String?; let image_name: String; let description: String; let date: Double; let location_name: String; let latitude: Double; let longitude: Double; let creator_id: UUID?
    init(from act: Activity, creatorIdOverride: UUID? = nil) {
        id = act.id; title = act.title; category = act.category; image_url = act.imageURL; image_name = act.imageName; description = act.description; date = act.date.timeIntervalSince1970; location_name = act.locationName; latitude = act.latitude; longitude = act.longitude; creator_id = creatorIdOverride ?? act.creatorId
    }
    func toActivity() async -> Activity {
        var imageData: Data? = nil
        if let urlString = image_url {
            imageData = await ActivityManager.shared.loadImageAsync(from: urlString)
        }
        return Activity(id: id, title: title, category: category, imageName: image_name, imageData: imageData, imageURL: image_url, color: .appGreen, description: description, date: Date(timeIntervalSince1970: date), locationName: location_name, lat: latitude, lon: longitude, creatorId: creator_id ?? UUID())
    }
}

struct Activity: Identifiable, Hashable, Codable {
    let id: UUID; let title: String; let category: String; let imageName: String; var imageData: Data?; var imageURL: String?; let latitude: Double; let longitude: Double; var description: String; var date: Date; var locationName: String; let creatorId: UUID
    init(id: UUID = UUID(), title: String, category: String = "Sports", imageName: String, imageData: Data? = nil, imageURL: String? = nil, color: Color, description: String = "", date: Date = Date(), locationName: String = "Naples", lat: Double = 40.85, lon: Double = 14.26, creatorId: UUID = UUID()) {
        self.id = id; self.title = title; self.category = category; self.imageName = imageName; self.imageData = imageData; self.imageURL = imageURL; self.description = description; self.date = date; self.locationName = locationName; self.latitude = lat; self.longitude = lon; self.creatorId = creatorId
    }
    static func == (lhs: Activity, rhs: Activity) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var color: Color { .appGreen }
}

struct UserProfile: Identifiable, Codable {
    var id = UUID(); var name, surname: String; var age: Int; var gender, bio, motto, image: String; var profileImageData: Data? = nil; var email, password: String; var interests: Set<String>; var shareLocation, notifications: Bool; var country: String = "🇮🇹 Italy"
    static var empty: UserProfile {
        UserProfile(id: UUID(), name: "", surname: "", age: 18, gender: "Prefer not to say", bio: "", motto: "", image: "person.circle", email: "", password: "", interests: [], shareLocation: false, notifications: false)
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: UserProfile = .empty
    @Published var isLoggedIn: Bool = false
    
    private let client = ActivityManager.shared.client
    
    init() {
        checkSession()
    }
    
    func checkSession() {
        Task {
            if let user = try? await client.auth.session.user {
                await fetchProfile(userId: user.id)
            } else {
                await MainActor.run { self.isLoggedIn = false }
            }
        }
    }
    
    func signUp(user: UserProfile) async throws {
        let response = try await client.auth.signUp(email: user.email, password: user.password)
        let userId = response.user.id
        
        var avatarUrl = user.image
        if let data = user.profileImageData {
            let fileName = "avatar_\(userId).jpg"
            try? await client.storage.from("images").upload(path: fileName, file: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            if let url = try? client.storage.from("images").getPublicURL(path: fileName) {
                avatarUrl = url.absoluteString
            }
        }
        
        let profileTable = ProfileTable(
            id: userId, name: user.name, surname: user.surname, age: user.age, gender: user.gender, bio: user.bio, motto: user.motto, country: user.country, interests: Array(user.interests), avatar_url: avatarUrl
        )
        
        try await client.from("profiles").insert(profileTable).execute()
        
        var finalUser = user; finalUser.id = userId; finalUser.image = avatarUrl
        await MainActor.run { self.currentUser = finalUser; self.isLoggedIn = true }
    }
    
    func login(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)
        await fetchProfile(userId: response.user.id)
    }
    
    func fetchProfile(userId: UUID) async {
        do {
            let table: ProfileTable = try await client.from("profiles").select().eq("id", value: userId.uuidString).single().execute().value
            var loadedUser = UserProfile(id: table.id, name: table.name, surname: table.surname, age: table.age, gender: table.gender, bio: table.bio, motto: table.motto ?? "", image: table.avatar_url ?? "person.circle", profileImageData: nil, email: "", password: "", interests: Set(table.interests), shareLocation: true, notifications: true, country: table.country)
            if let sessionEmail = try? await client.auth.session.user.email { loadedUser.email = sessionEmail }
            if let urlString = table.avatar_url, let url = URL(string: urlString) {
                let (data, _) = try await URLSession.shared.data(from: url)
                loadedUser.profileImageData = data
            }
            await MainActor.run { self.currentUser = loadedUser; self.isLoggedIn = true }
            await ActivityManager.shared.fetchMyJoinedActivities()
        } catch { await MainActor.run { self.isLoggedIn = false } }
    }
    
    func updateUserProfile(user: UserProfile) async throws {
        var avatarUrl = user.image
        if let data = user.profileImageData {
            let fileName = "avatar_\(user.id.uuidString).jpg"
            try? await client.storage.from("images").upload(path: fileName, file: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            if let url = try? client.storage.from("images").getPublicURL(path: fileName) { avatarUrl = url.absoluteString + "?t=\(Int(Date().timeIntervalSince1970))" }
        }
        let profileTable = ProfileTable(id: user.id, name: user.name, surname: user.surname, age: user.age, gender: user.gender, bio: user.bio, motto: user.motto, country: user.country, interests: Array(user.interests), avatar_url: avatarUrl)
        try await client.from("profiles").update(profileTable).eq("id", value: user.id.uuidString).execute()
        var finalUser = user; finalUser.image = avatarUrl
        await MainActor.run { self.currentUser = finalUser }
    }
    
    func updateCredentials(email: String, password: String) async throws {
        let attributes = UserAttributes(email: email, password: password)
        try await client.auth.update(user: attributes)
        await MainActor.run {
            self.currentUser.email = email
            self.currentUser.password = password
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    // --- FUNZIONE DELETE ACCOUNT ---
    func deleteAccount() async throws {
        let userId = currentUser.id.uuidString
        try await client.from("activities").delete().eq("creator_id", value: userId).execute()
        try await client.from("participants").delete().eq("user_id", value: userId).execute()
        try await client.from("profiles").delete().eq("id", value: userId).execute()
        logout()
    }
    
    func logout() {
        Task {
            try? await client.auth.signOut()
            await MainActor.run { self.currentUser = .empty; self.isLoggedIn = false; ActivityManager.shared.clearUserData() }
        }
    }
    func saveUser(_ u: UserProfile) { self.currentUser = u }
}

struct Validator {
    static func isValidEmail(_ e: String) -> Bool { NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: e) }
    static func isValidPassword(_ p: String) -> Bool { p.count >= 8 }
}

struct CustomBackButton: View { @Environment(\.presentationMode) var pm; var body: some View { Button(action: { pm.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) } } }
struct DatiEvento { var titolo, tipo, descrizione: String; var data: Date; var luogo: String; var imageData: Data?; var lat, lon: Double?; init() { titolo=""; tipo=""; descrizione=""; data=Date(); luogo=""; imageData=nil; lat=nil; lon=nil } }

extension Activity { static let testActivity = Activity(id: UUID(), title: "Test", imageName: "star", color: .blue, creatorId: UUID()) }

// --- FIX PER LO SWIPE BACK ---
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
