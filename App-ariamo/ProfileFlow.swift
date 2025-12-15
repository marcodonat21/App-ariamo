import SwiftUI
import PhotosUI

// --- MAIN PROFILE SCREEN ---
struct ProfileScreen: View {
    @State private var user = UserProfile(
        name: "Mario", surname: "Rossi", age: 25, gender: "Man",
        bio: "I love running and pizza!", motto: "Never give up",
        image: "person.crop.circle.fill", profileImageData: nil,
        email: "mario.rossi@email.com", password: "secretPassword",
        interests: ["Swimming", "Gym"], shareLocation: true, notifications: true, maxDistance: 10.0
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                NavigationLink(destination: EditProfileView(user: $user)) { ProfileHeaderCard(user: user) }.buttonStyle(PlainButtonStyle())
                Divider()
                VStack(spacing: 15) {
                    NavigationLink(destination: CreatedActivitiesView()) { MenuRowItem(icon: "plus.circle.fill", title: "Created Activities", color: .appGreen) }
                    NavigationLink(destination: JoinedActivitiesView()) { MenuRowItem(icon: "figure.run.circle.fill", title: "Joined Activities", color: .orange) }
                }.padding(.horizontal)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your current preferences").font(.caption).foregroundColor(.gray).padding(.horizontal)
                    HStack {
                        PreferenceBadge(icon: "bell.fill", isActive: user.notifications)
                        PreferenceBadge(icon: "location.fill", isActive: user.shareLocation)
                        PreferenceBadge(text: "\(Int(user.maxDistance)) km", isActive: true)
                    }.padding(.horizontal)
                }
                Spacer()
            }.padding(.top).padding(.bottom, 100)
        }.navigationTitle("Profile")
    }
}

// --- EDIT SCREEN ---
struct EditProfileView: View {
    @Binding var user: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showCamera = false; @State private var showGallery = false; @State private var showActionSheet = false
    @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil
    
    let availableSports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball"), ("Yoga", "figure.yoga"), ("Basketball", "basketball.fill")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        Form {
            Section(header: Text("Profile Photo")) {
                VStack(alignment: .center, spacing: 20) {
                    ZStack {
                        Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 120, height: 120)
                        if let data = user.profileImageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle()) }
                        else { Image(systemName: user.image).resizable().aspectRatio(contentMode: .fit).frame(width: 60, height: 60).foregroundColor(.appGreen) }
                        VStack { Spacer(); HStack { Spacer(); Image(systemName: "camera.fill").foregroundColor(.white).padding(8).background(Color.appGreen).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2)) } }.frame(width: 120, height: 120)
                    }.onTapGesture { showActionSheet = true }
                    Text("Tap photo to edit").font(.caption).foregroundColor(.gray)
                }.frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .confirmationDialog("Change Profile Photo", isPresented: $showActionSheet) {
                Button("Take a photo") { showCamera = true }; Button("Choose from Gallery") { showGallery = true }
                Button("Remove current photo", role: .destructive) { user.profileImageData = nil }; Button("Cancel", role: .cancel) { }
            } message: { Text("Choose how to change your image") }

            Section(header: Text("Personal Data")) {
                TextField("First Name", text: $user.name)
                TextField("Last Name", text: $user.surname)
                Picker("Gender", selection: $user.gender) {
                    Text("Man").tag("Man"); Text("Woman").tag("Woman")
                    Text("Non-binary").tag("Non-binary"); Text("Prefer not to say").tag("Prefer not to say")
                }
                Stepper("Age: \(user.age) years", value: $user.age, in: 18...99)
            }
            Section(header: Text("About you")) { TextField("Bio", text: $user.bio); TextField("Motto", text: $user.motto) }
            Section(header: Text("Credentials")) { TextField("Email", text: $user.email).keyboardType(.emailAddress).autocapitalization(.none); SecureField("Password", text: $user.password) }
            Section(header: Text("App Preferences")) {
                Toggle("Share Location", isOn: $user.shareLocation).toggleStyle(SwitchToggleStyle(tint: .appGreen)); Toggle("Receive Notifications", isOn: $user.notifications).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                VStack(alignment: .leading) { Text("Max Distance: \(Int(user.maxDistance)) km"); Slider(value: $user.maxDistance, in: 1...100, step: 1).accentColor(.appGreen) }
            }
            Section(header: Text("Your Sports")) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(availableSports, id: \.0) { sport in
                        Button(action: { if user.interests.contains(sport.0) { user.interests.remove(sport.0) } else { user.interests.insert(sport.0) } }) {
                            VStack { Image(systemName: sport.1).font(.title2); Text(sport.0).font(.caption).bold() }
                            .frame(maxWidth: .infinity).padding(.vertical, 10).background(user.interests.contains(sport.0) ? Color.appGreen : Color.gray.opacity(0.1)).foregroundColor(user.interests.contains(sport.0) ? .white : .gray).cornerRadius(10)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // SAVE BUTTON
            Section {
                Button(action: {
                    // Chiudi tastiera
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    // Torna indietro
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Changes")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.appGreen)
                        .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Edit Profile")
        // HO RIMOSSO IL .onTapGesture { endEditing() } QUI PERCHE' BLOCCAVA IL BOTTONE
        .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        .onChange(of: inputImage) { newImage in if let newImage = newImage, let data = newImage.jpegData(compressionQuality: 0.8) { user.profileImageData = data } }
        .onChange(of: selectedItem) { newItem in Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { user.profileImageData = data } } }
    }
}

// Components
struct ProfileHeaderCard: View { let user: UserProfile; var body: some View { HStack(spacing: 20) { if let data = user.profileImageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2)) } else { Image(systemName: user.image).resizable().aspectRatio(contentMode: .fit).frame(width: 80, height: 80).foregroundColor(.white).padding(5).background(Color.white.opacity(0.3)).clipShape(Circle()) }; VStack(alignment: .leading, spacing: 5) { Text("\(user.name) \(user.surname)").font(.title2).bold().foregroundColor(.white); Text("\(user.age) years").font(.headline).foregroundColor(.white.opacity(0.9)); HStack { Text("Tap to edit"); Image(systemName: "pencil") }.font(.caption).foregroundColor(.white).padding(.top, 5) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7)) }.padding(25).background(Color.appGreen).cornerRadius(20).shadow(radius: 5).padding(.horizontal) } }
struct JoinedActivitiesView: View { @ObservedObject var manager = ActivityManager.shared; var body: some View { VStack { if manager.joinedActivities.isEmpty { VStack(spacing: 15) { Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 50)).foregroundColor(.gray); Text("No activities joined yet.").font(.headline).foregroundColor(.gray); Text("Go to the Map or Activity list to join one!").font(.caption).foregroundColor(.gray) }.padding() } else { ScrollView { VStack(spacing: 15) { ForEach(manager.joinedActivities) { activity in NavigationLink(destination: ActivityDetailView(activity: activity)) { HStack { Image(systemName: activity.imageName).font(.title).foregroundColor(.white).frame(width: 50, height: 50).background(activity.color).clipShape(Circle()); VStack(alignment: .leading) { Text(activity.title).font(.headline).foregroundColor(.black); Text(activity.description).font(.caption).foregroundColor(.gray).lineLimit(1) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray) }.padding().background(Color.white).cornerRadius(15).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) } } }.padding() } } }.navigationTitle("Joined Activities").background(Color(UIColor.systemGray6)) } }
struct MenuRowItem: View { let icon: String; let title: String; let color: Color; var body: some View { HStack { Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 40); Text(title).font(.headline).foregroundColor(.black); Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray) }.padding().background(Color.white).cornerRadius(15).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2), lineWidth: 1)) } }
struct PreferenceBadge: View { var icon: String? = nil; var text: String? = nil; var isActive: Bool; var body: some View { HStack { if let icon = icon { Image(systemName: icon) }; if let text = text { Text(text) } }.padding(8).background(isActive ? Color.appGreen.opacity(0.1) : Color.gray.opacity(0.1)).foregroundColor(isActive ? .appGreen : .gray).cornerRadius(8) } }
struct CreatedActivitiesView: View { var body: some View { Text("User created activities") } }
#Preview { NavigationView { ProfileScreen() } }
