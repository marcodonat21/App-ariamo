import SwiftUI
import MapKit

enum ActivityAlert: Identifiable { case leave; case delete; var id: Int { hashValue } }

struct ActivityDetailView: View {
    let initialActivity: Activity
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager = ActivityManager.shared
    @ObservedObject var userManager = UserManager.shared
    
    var onLoginRequest: ((AuthContext) -> Void)?
    
    @State private var showSuccess = false
    @State private var showLeaveSuccess = false
    @State private var showDeleteSuccess = false
    @State private var showFavoriteSuccess = false
    @State private var showUnfavoriteSuccess = false
    
    @State private var activeAlert: ActivityAlert?
    @State private var showEditView = false
    
    var isLoggedIn: Bool {
        return !userManager.currentUser.email.isEmpty
    }
    
    init(activity: Activity, onLoginRequest: ((AuthContext) -> Void)? = nil) {
        self.initialActivity = activity
        self.onLoginRequest = onLoginRequest
    }
    
    var activityToShow: Activity {
        if let updated = manager.createdActivities.first(where: { $0.id == initialActivity.id }) { return updated }
        if let updated = manager.joinedActivities.first(where: { $0.id == initialActivity.id }) { return updated }
        if let updated = manager.allActivities.first(where: { $0.id == initialActivity.id }) { return updated }
        return initialActivity
    }
    
    var participants: [ParticipantDTO] { return manager.participantsCache[activityToShow.id] ?? [] }
    
    var isJoined: Bool {
        guard isLoggedIn else { return false }
        let myID = userManager.currentUser.id
        return manager.isJoined(activity: activityToShow) || participants.contains { $0.user_id == myID }
    }
    
    var isCreator: Bool {
        guard isLoggedIn else {
            print("❌ Not logged in, can't be creator")
            return false
        }
        let result = manager.isCreator(activity: activityToShow)
        print("✏️ ActivityDetailView - isCreator: \(result) for activity: \(activityToShow.title)")
        return result
    }
    
    var isFavorite: Bool {
        guard isLoggedIn else { return false }
        return manager.isFavorite(activity: activityToShow)
    }
    
    var approximateLocation: String {
        let components = activityToShow.locationName.components(separatedBy: ",")
        if components.count > 1 { return components.last?.trimmingCharacters(in: .whitespaces) ?? "General Area" }
        return "Within 2km of this area"
    }
    
    // --- MESSAGGIO DI CONDIVISIONE ---
    var shareMessage: String {
        let time = activityToShow.date.formatted(date: .omitted, time: .shortened)
        let userName = userManager.currentUser.name.isEmpty ? "Someone" : userManager.currentUser.name
        return "\(userName) invites you! ⚽️ \(activityToShow.title) at \(activityToShow.locationName) @ \(time). Join us? Download App-ariamo!"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer(); Text("Details").font(.headline).foregroundColor(.themeText); Spacer()
                    
                    if isCreator {
                        Button(action: { showEditView = true }) {
                            Image(systemName: "pencil").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    } else { Color.clear.frame(width: 44, height: 44) }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 15).background(Color.themeBackground)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // CARD PRINCIPALE
                        VStack(spacing: 0) {
                            // Immagine
                            GeometryReader { geo in
                                if let data = activityToShow.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: geo.size.width, height: 250).clipped()
                                } else if let urlStr = activityToShow.imageURL, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { image in image.resizable().aspectRatio(contentMode: .fill) } placeholder: { Rectangle().fill(Color.gray.opacity(0.3)) }.frame(width: geo.size.width, height: 250).clipped()
                                } else {
                                    ZStack { Rectangle().fill(activityToShow.color.opacity(0.8)); Image(systemName: activityToShow.imageName).font(.system(size: 80)).foregroundColor(.white.opacity(0.3)) }
                                }
                            }.frame(height: 250)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                // Titolo e Header
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(activityToShow.category.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(activityToShow.color).padding(.horizontal, 10).padding(.vertical, 5).background(activityToShow.color.opacity(0.1)).cornerRadius(8)
                                        Spacer()
                                        Button(action: {
                                            if isLoggedIn {
                                                manager.toggleFavorite(activity: activityToShow)
                                                if manager.isFavorite(activity: activityToShow) { withAnimation { showFavoriteSuccess = true } }
                                                else { withAnimation { showUnfavoriteSuccess = true } }
                                            } else {
                                                onLoginRequest?(.joinActivity(activityToShow))
                                            }
                                        }) {
                                            Image(systemName: isFavorite ? "heart.fill" : "heart").font(.title2).foregroundColor(isFavorite ? .red : .gray).padding(8).background(Color.themeBackground).clipShape(Circle())
                                        }
                                    }
                                    Text(activityToShow.title).font(.title2).fontWeight(.heavy).foregroundColor(.themeText)
                                    HStack(spacing: 10) {
                                        HStack(spacing: -10) {
                                            ForEach(0..<min(participants.count, 3), id: \.self) { _ in Circle().stroke(Color.themeCard, lineWidth: 2).background(Circle().fill(Color.gray.opacity(0.3))).overlay(Image(systemName: "person.fill").font(.caption).foregroundColor(.gray)).frame(width: 30, height: 30) }
                                            if participants.count > 3 { ZStack { Circle().stroke(Color.themeCard, lineWidth: 2); Circle().fill(Color.appGreen); Text("+\(participants.count - 3)").font(.caption2).bold().foregroundColor(.white) }.frame(width: 30, height: 30) }
                                        }
                                        Text(participants.isEmpty ? "Be first to join!" : "\(participants.count) people joined").font(.caption).foregroundColor(.themeSecondaryText)
                                    }.padding(.top, 5)
                                }
                                
                                if isLoggedIn {
                                    VStack(spacing: 0) {
                                        DetailRow(icon: "calendar", title: "Date", value: activityToShow.date.formatted(date: .long, time: .omitted))
                                        Divider().padding(.leading, 50)
                                        DetailRow(icon: "clock", title: "Time", value: activityToShow.date.formatted(date: .omitted, time: .shortened))
                                        Divider().padding(.leading, 50)
                                        
                                        // RIGA LOCATION CUSTOM (CON TASTO GO)
                                        HStack(spacing: 15) {
                                            ZStack {
                                                Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 40, height: 40)
                                                Image(systemName: "mappin.and.ellipse").font(.system(size: 18)).foregroundColor(.appGreen)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Location").font(.caption).foregroundColor(.gray)
                                                Text(activityToShow.locationName).font(.subheadline).fontWeight(.semibold).foregroundColor(.themeText).lineLimit(1)
                                            }
                                            Spacer()
                                            
                                            // TASTO GO
                                            Button(action: openMaps) {
                                                Text("GO")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.appGreen)
                                                    .cornerRadius(10)
                                            }
                                        }
                                        .padding(.vertical, 8).padding(.horizontal, 15)
                                    }
                                    .padding().background(Color.themeBackground).cornerRadius(15)
                                } else {
                                    VStack(spacing: 0) { DetailRow(icon: "mappin.and.ellipse", title: "Area", value: approximateLocation) }.padding().background(Color.themeBackground).cornerRadius(15)
                                    HStack { Image(systemName: "lock.fill").foregroundColor(.appGreen).font(.caption); Text("Sign in to see exact date, time and location").font(.caption).foregroundColor(.themeSecondaryText) }.padding(.horizontal, 15).padding(.vertical, 10).background(Color.appGreen.opacity(0.1)).cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) { Text("About").font(.headline).foregroundColor(.themeText); Text(activityToShow.description).font(.body).foregroundColor(.themeSecondaryText).lineSpacing(4) }
                                
                                // --- TASTO INVITE FRIENDS (ORA SOPRA) ---
                                if isLoggedIn {
                                    ShareLink(item: shareMessage) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Invite Friends")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.appGreen)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appGreen.opacity(0.1))
                                        .cornerRadius(18)
                                    }
                                    .padding(.bottom, 5) // Spazio per staccarlo dal bottone sotto
                                }
                                
                                // BOTTONE PRINCIPALE (SOTTO)
                                Button(action: {
                                    if isLoggedIn {
                                        if isCreator { activeAlert = .delete }
                                        else if isJoined { activeAlert = .leave }
                                        else {
                                            manager.joinActivityOnline(activity: activityToShow)
                                            if manager.shouldShowSuccessAfterLogin { /* Gestito in onAppear */ }
                                            else { withAnimation { showSuccess = true } }
                                        }
                                    } else {
                                        onLoginRequest?(.joinActivity(activityToShow))
                                    }
                                }) {
                                    Text(isCreator ? "Cancel Activity" : (isJoined ? "Leave Activity" : "Join Activity")).font(.headline).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding().frame(height: 55).background(isCreator || isJoined ? Color.red : Color.appGreen).cornerRadius(18).shadow(color: (isCreator || isJoined ? Color.red : Color.appGreen).opacity(0.3), radius: 8, y: 4)
                                }
                                
                            }.padding(20)
                        }.background(Color.themeCard).clipShape(RoundedRectangle(cornerRadius: 25)).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        Spacer().frame(height: 120)
                    }.padding(.horizontal, 25).padding(.top, 10)
                }
            }
            
            if showSuccess { SuccessOverlay(onClose: { showSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
            if showLeaveSuccess { LeaveSuccessOverlay(title: "Left", message: "You left the activity.", iconName: "arrow.uturn.left", color: .red, onClose: { showLeaveSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
            if showDeleteSuccess { LeaveSuccessOverlay(title: "Cancelled", message: "Activity deleted.", iconName: "trash", color: .red, onClose: { manager.delete(activity: activityToShow); showDeleteSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
            if showFavoriteSuccess { LeaveSuccessOverlay(title: "Great!", message: "Added to favourites!", iconName: "heart.fill", color: .red, onClose: { withAnimation { showFavoriteSuccess = false } }).zIndex(20) }
            if showUnfavoriteSuccess { LeaveSuccessOverlay(title: "Removed", message: "Removed from favorites.", iconName: "heart.slash.fill", color: .gray, onClose: { withAnimation { showUnfavoriteSuccess = false } }).zIndex(20) }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditView) { EditActivityView(activity: activityToShow) }
        .onAppear {
            Task { await manager.fetchParticipants(for: activityToShow.id) }
            if manager.shouldShowSuccessAfterLogin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { showSuccess = true }; manager.shouldShowSuccessAfterLogin = false }
            }
        }.onChange(of: manager.shouldShowSuccessAfterLogin) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showSuccess = true }
                    manager.shouldShowSuccessAfterLogin = false
                }
            }
        }
        .alert(item: $activeAlert) { type in
            switch type {
            case .leave: return Alert(title: Text("Leave?"), message: Text("Sure?"), primaryButton: .destructive(Text("Leave")) { manager.leaveActivityOnline(activity: activityToShow); DispatchQueue.main.asyncAfter(deadline: .now()+0.2){withAnimation{showLeaveSuccess=true}} }, secondaryButton: .cancel())
            case .delete: return Alert(title: Text("Delete?"), message: Text("Sure?"), primaryButton: .destructive(Text("Delete")) { DispatchQueue.main.asyncAfter(deadline: .now()+0.2){withAnimation{showDeleteSuccess=true}} }, secondaryButton: .cancel())
            }
        }
    }
    
    func openMaps() {
        let lat = activityToShow.latitude
        let lon = activityToShow.longitude
        let url = URL(string: "maps://?daddr=\(lat),\(lon)")
        if let url = url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// --- SUPPORTING VIEWS ---
struct DetailRow: View {
    let icon: String; let title: String; let value: String
    var body: some View {
        HStack(spacing: 15) {
            ZStack { Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 40, height: 40); Image(systemName: icon).font(.system(size: 18)).foregroundColor(.appGreen) }
            VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption).foregroundColor(.gray); Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(.themeText).lineLimit(1) }
            Spacer()
        }.padding(.vertical, 8).padding(.horizontal, 15)
    }
}

struct SuccessOverlay: View {
    var onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.appGreen)
                Text("Success!").font(.title).bold().foregroundColor(.white)
                Text("You joined this activity!").font(.body).foregroundColor(.gray)
                Button("OK") { onClose() }.padding().frame(maxWidth: .infinity).background(Color.appGreen).foregroundColor(.white).cornerRadius(15).padding(.horizontal)
            }.padding(30).background(Color.themeCard).cornerRadius(20).padding(40)
        }
    }
}

struct LeaveSuccessOverlay: View {
    var title: String; var message: String; var iconName: String; var color: Color; var onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: iconName).font(.system(size: 80)).foregroundColor(color)
                Text(title).font(.title).bold().foregroundColor(.white)
                Text(message).multilineTextAlignment(.center).foregroundColor(.gray)
                Button("OK") { onClose() }.padding().frame(maxWidth: .infinity).background(color).foregroundColor(.white).cornerRadius(15).padding(.horizontal)
            }.padding(30).background(Color.themeCard).cornerRadius(20).padding(40)
        }
    }
}
