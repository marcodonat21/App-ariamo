import SwiftUI

enum ActivityAlert: Identifiable { case leave; case delete; var id: Int { hashValue } }

struct ActivityDetailView: View {
    let initialActivity: Activity
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager = ActivityManager.shared
    
    @State private var showSuccess = false; @State private var showLeaveSuccess = false; @State private var showDeleteSuccess = false; @State private var activeAlert: ActivityAlert?
    @State private var showEditView = false
    
    init(activity: Activity) { self.initialActivity = activity }
    
    var activityToShow: Activity {
        if let updated = manager.createdActivities.first(where: { $0.id == initialActivity.id }) { return updated }
        if let updated = manager.joinedActivities.first(where: { $0.id == initialActivity.id }) { return updated }
        return initialActivity
    }
    var isAlreadyJoined: Bool { manager.isJoined(activity: activityToShow) }
    var isCreator: Bool { manager.isCreator(activity: activityToShow) }
    var isFavorite: Bool { manager.isFavorite(activity: activityToShow) } // Check Preferiti
    
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
                        Button(action: { showEditView = true }) { Image(systemName: "pencil").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) }
                    } else { Color.clear.frame(width: 44, height: 44) }
                }.padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 15).background(Color.themeBackground)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // CARD UNICA
                        VStack(spacing: 0) {
                            
                            // IMMAGINE
                            GeometryReader { geo in
                                if let data = activityToShow.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: geo.size.width, height: 250).clipped()
                                } else {
                                    ZStack { Rectangle().fill(activityToShow.color.opacity(0.8)); Image(systemName: activityToShow.imageName).font(.system(size: 80)).foregroundColor(.white.opacity(0.3)) }
                                }
                            }.frame(height: 250)
                            
                            // INFO
                            VStack(alignment: .leading, spacing: 20) {
                                
                                // TITOLO E CUORE
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(activityToShow.category.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(activityToShow.color).padding(.horizontal, 10).padding(.vertical, 5).background(activityToShow.color.opacity(0.1)).cornerRadius(8)
                                        Spacer()
                                        
                                        // TASTO CUORE (PREFERITI)
                                        Button(action: { manager.toggleFavorite(activity: activityToShow) }) {
                                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                                .font(.title2)
                                                .foregroundColor(isFavorite ? .red : .gray)
                                                .padding(8)
                                                .background(Color.themeBackground)
                                                .clipShape(Circle())
                                        }
                                    }
                                    Text(activityToShow.title).font(.title2).fontWeight(.heavy).foregroundColor(.themeText).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                    
                                    // --- LISTA PARTECIPANTI (CLICKABLE) ---
                                    NavigationLink(destination: ParticipantsListView()) {
                                        HStack(spacing: 10) {
                                            HStack(spacing: -10) {
                                                ForEach(0..<3) { _ in
                                                    Circle().stroke(Color.themeCard, lineWidth: 2).background(Circle().fill(Color.gray.opacity(0.3))).overlay(Image(systemName: "person.fill").font(.caption).foregroundColor(.gray)).frame(width: 30, height: 30)
                                                }
                                                ZStack { Circle().stroke(Color.themeCard, lineWidth: 2); Circle().fill(Color.appGreen); Text("+5").font(.caption2).bold().foregroundColor(.white) }.frame(width: 30, height: 30)
                                            }
                                            Text("8 people joined").font(.caption).foregroundColor(.themeSecondaryText)
                                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                                        }
                                        .padding(.top, 5)
                                    }
                                }
                                
                                VStack(spacing: 0) {
                                    DetailRow(icon: "calendar", title: "Date", value: activityToShow.date.formatted(date: .long, time: .omitted))
                                    Divider().padding(.leading, 50)
                                    DetailRow(icon: "clock", title: "Time", value: activityToShow.date.formatted(date: .omitted, time: .shortened))
                                    Divider().padding(.leading, 50)
                                    DetailRow(icon: "mappin.and.ellipse", title: "Location", value: activityToShow.locationName)
                                }.padding().background(Color.themeBackground).cornerRadius(15)
                                
                                VStack(alignment: .leading, spacing: 10) { Text("About").font(.headline).foregroundColor(.themeText); Text(activityToShow.description).font(.body).foregroundColor(.themeSecondaryText).lineSpacing(4) }
                                
                                Button(action: {
                                    if isCreator { activeAlert = .delete } else if isAlreadyJoined { activeAlert = .leave } else { manager.join(activity: activityToShow); withAnimation { showSuccess = true } }
                                }) {
                                    Text(isCreator ? "Cancel Activity" : (isAlreadyJoined ? "Leave Activity" : "Join Activity")).font(.headline).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding().frame(height: 55).background(isCreator || isAlreadyJoined ? Color.red : Color.appGreen).cornerRadius(18).shadow(color: (isCreator || isAlreadyJoined ? Color.red : Color.appGreen).opacity(0.3), radius: 8, y: 4)
                                }
                            }.padding(20)
                        }
                        .background(Color.themeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        Spacer().frame(height: 120)
                    }.padding(.horizontal, 25).padding(.top, 10)
                }
            }.ignoresSafeArea(.all, edges: .top)
            
            if showSuccess { SuccessOverlay(onClose: { showSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
            if showLeaveSuccess { LeaveSuccessOverlay(title: "Left", message: "You left the activity.", iconName: "arrow.uturn.left", color: .red, onClose: { showLeaveSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
            if showDeleteSuccess { LeaveSuccessOverlay(title: "Cancelled", message: "Activity deleted.", iconName: "trash", color: .red, onClose: { manager.delete(activity: activityToShow); showDeleteSuccess = false; presentationMode.wrappedValue.dismiss() }).zIndex(20) }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditView) { EditActivityView(activity: activityToShow) }
        .alert(item: $activeAlert) { type in
            switch type { case .leave: return Alert(title: Text("Leave?"), message: Text("Sure?"), primaryButton: .destructive(Text("Leave")) { manager.leave(activity: activityToShow); DispatchQueue.main.asyncAfter(deadline: .now()+0.2){withAnimation{showLeaveSuccess=true}} }, secondaryButton: .cancel()); case .delete: return Alert(title: Text("Delete?"), message: Text("Sure?"), primaryButton: .destructive(Text("Delete")) { DispatchQueue.main.asyncAfter(deadline: .now()+0.2){withAnimation{showDeleteSuccess=true}} }, secondaryButton: .cancel()) }
        }
    }
}

// Helpers
struct DetailRow: View { let icon: String; let title: String; let value: String; var body: some View { HStack(spacing: 15) { ZStack { Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 40, height: 40); Image(systemName: icon).font(.system(size: 18)).foregroundColor(.appGreen) }; VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption).foregroundColor(.gray); Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(.themeText).lineLimit(1) }; Spacer() }.padding(.vertical, 8) } }
struct SuccessOverlay: View { var onClose: () -> Void; var body: some View { ZStack { Color.black.opacity(0.6).ignoresSafeArea(); VStack(spacing: 20) { Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.appGreen); Text("Success!").font(.title).bold().foregroundColor(.white); Button("OK") { onClose() }.padding().frame(maxWidth: .infinity).background(Color.appGreen).foregroundColor(.white).cornerRadius(15).padding(.horizontal) }.padding(30).background(Color.themeCard).cornerRadius(20).padding(40) } } }
struct LeaveSuccessOverlay: View { var title: String; var message: String; var iconName: String; var color: Color; var onClose: () -> Void; var body: some View { ZStack { Color.black.opacity(0.6).ignoresSafeArea(); VStack(spacing: 20) { Image(systemName: iconName).font(.system(size: 80)).foregroundColor(color); Text(title).font(.title).bold().foregroundColor(.white); Text(message).multilineTextAlignment(.center).foregroundColor(.gray); Button("OK") { onClose() }.padding().frame(maxWidth: .infinity).background(color).foregroundColor(.white).cornerRadius(15).padding(.horizontal) }.padding(30).background(Color.themeCard).cornerRadius(20).padding(40) } } }
