import SwiftUI
import PhotosUI
import UserNotifications
import CoreLocation

// --- MAIN PROFILE SCREEN ---
struct ProfileScreen: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject var userManager = UserManager.shared
    @State private var showLogoutConfirmation = false
    
    // Callback per la ContentView (Navigazione Intelligente)
    var onLoginRequest: (() -> Void)?
    
    var isUserLoggedIn: Bool {
        return !userManager.currentUser.email.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if isUserLoggedIn {
                ScrollView {
                    VStack(spacing: 30) {
                        Text("About you!")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.themeText)
                            .padding(.top, 10)
                        NavigationLink(destination: EditProfileView(user: $userManager.currentUser, isLoggedIn: $isLoggedIn)) {
                            ProfileHeaderCard(user: userManager.currentUser)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                        
                        VStack(spacing: 15) {
                            NavigationLink(destination: CreatedActivitiesView(onLoginRequest: onLoginRequest)) {
                                MenuRowItem(icon: "plus.circle.fill", title: "Created Activities", color: .appGreen)
                            }
                            NavigationLink(destination: JoinedActivitiesView(onLoginRequest: onLoginRequest)) {
                                MenuRowItem(icon: "figure.run.circle.fill", title: "Joined Activities", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        Button(action: { showLogoutConfirmation = true }) {
                            Text("Log Out")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                    }
                    .padding(.top)
                }
            } else {
                VStack(spacing: 25) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 80)).foregroundColor(.appGreen.opacity(0.5))
                    VStack(spacing: 10) {
                        Text("Ready to join us?").font(.title2).bold()
                        Text("Create a profile to save your favorite activities and see your stats.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    Button(action: {
                        // NOTIFICA ALLA CONTENTVIEW DI APRIRE IL LOGIN
                        onLoginRequest?()
                    }) {
                        Text("Login / Register").fontWeight(.bold).foregroundColor(.white).padding().frame(maxWidth: 250).background(Color.appGreen).cornerRadius(15)
                    }
                    Spacer()
                }
            }
            
            if showLogoutConfirmation {
                LiquidConfirmationModal(
                    title: "Log Out",
                    message: "Are you sure you want to exit?",
                    actionTitle: "Log Out",
                    isDestructive: true,
                    onCancel: { showLogoutConfirmation = false },
                    onConfirm: { performLogout() }
                )
                .zIndex(100)
            }
        }
        .navigationTitle("Profile")
    }
    
    private func performLogout() {
        showLogoutConfirmation = false
        UserManager.shared.logout()
        withAnimation(.easeInOut) {
            self.isLoggedIn = false
        }
    }
}

struct EditProfileView: View {
    @Binding var user: UserProfile
    @Binding var isLoggedIn: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showCamera = false; @State private var showGallery = false; @State private var showActionSheet = false
    @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil
    @State private var showDeleteConfirmation = false
    
    let availableSports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball"), ("Yoga", "figure.yoga"), ("Basketball", "basketball.fill")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    let countries = ["🇮🇹 Italy", "🇺🇸 USA", "🇬🇧 UK", "🇫🇷 France", "🇪🇸 Spain", "🇩🇪 Germany", "🇨🇭 Switzerland", "🌍 Other"]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea().onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer(); Text("Edit Profile").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44)
                }.padding().padding(.top, 40).background(Color(UIColor.systemGray6))
                
                Form {
                    Section(header: Text("Profile Photo")) {
                        VStack(alignment: .center, spacing: 20) {
                            ZStack {
                                Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 120, height: 120)
                                if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle())
                                } else {
                                    Image(systemName: user.image).resizable().aspectRatio(contentMode: .fit).frame(width: 60, height: 60).foregroundColor(.appGreen)
                                }
                                VStack { Spacer(); HStack { Spacer(); Image(systemName: "camera.fill").foregroundColor(.white).padding(8).background(Color.appGreen).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2)) } }.frame(width: 120, height: 120)
                            }.onTapGesture { showActionSheet = true }
                        }.frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    
                    Section(header: Text("Credentials")) {
                        TextField("Email", text: $user.email).keyboardType(.emailAddress).autocapitalization(.none)
                        SecureField("Password", text: $user.password)
                    }
                    
                    Section(header: Text("Personal Data")) {
                        TextField("First Name", text: $user.name); TextField("Last Name", text: $user.surname)
                        Picker("Gender", selection: $user.gender) { Text("Man").tag("Man"); Text("Woman").tag("Woman"); Text("Non-binary").tag("Non-binary"); Text("Prefer not to say").tag("Prefer not to say") }
                        Picker("Country", selection: $user.country) { ForEach(countries, id: \.self) { c in Text(c).tag(c) } }
                        Stepper("Age: \(user.age) years", value: $user.age, in: 18...99)
                    }
                    
                    Section(header: Text("Sports Interests")) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(availableSports, id: \.0) { sport in
                                Button(action: {
                                    if user.interests.contains(sport.0) { user.interests.remove(sport.0) }
                                    else { user.interests.insert(sport.0) }
                                }) {
                                    VStack { Image(systemName: sport.1); Text(sport.0).font(.caption2).bold() }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(user.interests.contains(sport.0) ? Color.appGreen : Color.gray.opacity(0.1))
                                        .foregroundColor(user.interests.contains(sport.0) ? .white : .gray).cornerRadius(10)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }.padding(.vertical, 5)
                    }
                    
                    Section {
                        Button(action: {
                            hideKeyboard()
                            UserManager.shared.saveUser(user)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save Changes").bold().frame(maxWidth: .infinity).foregroundColor(.appGreen)
                        }
                    }
                    
                    Section {
                        Button(action: { showDeleteConfirmation = true }) {
                            Text("Delete Account").bold().frame(maxWidth: .infinity).foregroundColor(.red)
                        }
                    }
                    
                    // Spazio extra per evitare che vada sotto la tab bar
                    /*Section {
                        Color.clear.frame(height: 30)
                    }*/
                }.padding(.bottom, 100)
                .scrollDismissesKeyboard(.immediately)
            }
            
            if showDeleteConfirmation {
                LiquidConfirmationModal(title: "Delete Account", message: "Are you sure?", actionTitle: "Delete Forever", isDestructive: true, onCancel: { showDeleteConfirmation = false }, onConfirm: {
                    showDeleteConfirmation = false
                    UserManager.shared.logout()
                    isLoggedIn = false
                }).zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Photo", isPresented: $showActionSheet) {
            Button("Camera") { showCamera = true }
            Button("Gallery") { showGallery = true }
            Button("Remove", role: .destructive) { user.profileImageData = nil }
        }
        .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        .onChange(of: inputImage) { new in if let new = new, let d = new.jpegData(compressionQuality: 0.8) { user.profileImageData = d } }
        .onChange(of: selectedItem) { item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { user.profileImageData = d } } }
    }
    func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}

struct CreatedActivitiesView: View {
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Callback per richiedere il login quando necessario
    var onLoginRequest: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4)
                }
                Spacer(); Text("Created Activities").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44)
            }.padding().padding(.top, 40)
            
            if manager.createdActivities.isEmpty {
                Spacer(); Text("No activities created yet.").foregroundColor(.gray); Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(manager.createdActivities) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: { context in
                                onLoginRequest?()
                            })) { ActivityRow(activity: activity) }
                        }
                    }.padding()
                }
            }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

struct JoinedActivitiesView: View {
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Callback per richiedere il login quando necessario
    var onLoginRequest: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4)
                }
                Spacer(); Text("Joined Activities").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44)
            }.padding().padding(.top, 40)
            
            if manager.joinedActivities.isEmpty {
                Spacer(); Text("No activities joined yet.").foregroundColor(.gray); Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(manager.joinedActivities) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: { context in
                                onLoginRequest?()
                            })) { ActivityRow(activity: activity) }
                        }
                    }.padding()
                }
            }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

struct ActivityRow: View {
    let activity: Activity
    var body: some View {
        HStack {
            Image(systemName: activity.imageName).foregroundColor(.white).frame(width: 50, height: 50).background(activity.color).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(activity.title).font(.headline).foregroundColor(.black)
                Text(activity.description).font(.caption).foregroundColor(.gray).lineLimit(1)
            }
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray)
        }.padding().background(Color.white).cornerRadius(15).shadow(radius: 2)
    }
}

struct ProfileHeaderCard: View {
    let user: UserProfile
    var body: some View {
        HStack(spacing: 20) {
            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: user.image).resizable().aspectRatio(contentMode: .fit).frame(width: 80, height: 80).foregroundColor(.white).padding(5).background(Color.white.opacity(0.3)).clipShape(Circle())
            };
            VStack(alignment: .leading, spacing: 5) {
                Text("\(user.name) \(user.surname)").font(.title2).bold().foregroundColor(.white)
                Text("\(user.age) years • \(user.gender)").font(.subheadline).foregroundColor(.white.opacity(0.9))
                HStack { Text("Tap to edit profile"); Image(systemName: "pencil") }.font(.caption2).bold().foregroundColor(.white).padding(.top, 5)
            };
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
        }.padding(25).background(Color.appGreen).cornerRadius(20).shadow(radius: 5).padding(.horizontal)
    }
}

struct MenuRowItem: View {
    let icon: String; let title: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 40)
            Text(title).font(.headline).foregroundColor(.black)
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray)
        }.padding().background(Color.white).cornerRadius(15).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct LiquidConfirmationModal: View {
    let title: String; let message: String; let actionTitle: String; let isDestructive: Bool
    let onCancel: () -> Void; let onConfirm: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { onCancel() }
            VStack(spacing: 25) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(isDestructive ? .red : .orange).padding(.top, 10)
                VStack(spacing: 10) {
                    Text(title).font(.title2).bold()
                    Text(message).font(.body).multilineTextAlignment(.center).foregroundColor(.gray).padding(.horizontal)
                }
                HStack(spacing: 15) {
                    Button(action: onCancel) { Text("Cancel").fontWeight(.semibold).foregroundColor(.gray).padding().frame(maxWidth: .infinity).background(Color.gray.opacity(0.2)).cornerRadius(15) }
                    Button(action: onConfirm) { Text(actionTitle).fontWeight(.bold).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(isDestructive ? Color.red : Color.appGreen).cornerRadius(15) }
                }.padding(.horizontal)
            }.padding(25).background(.ultraThinMaterial).cornerRadius(30).padding(30)
        }
    }
}

// --- PREVIEWS ---
struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview Utente Loggato
            NavigationView {
                ProfileScreen(isLoggedIn: .constant(true))
                    .onAppear {
                        UserManager.shared.currentUser = UserProfile(
                            name: "Mario",
                            surname: "Rossi",
                            age: 30,
                            gender: "Man",
                            bio: "Ciao!",
                            motto: "",
                            image: "person.circle",
                            email: "mario@rossi.it",
                            password: "password",
                            interests: ["Swimming", "Hiking"],
                            shareLocation: true,
                            notifications: true
                        )
                    }
            }
            .previewDisplayName("Loggato")
            
            // Preview Ospite
            NavigationView {
                ProfileScreen(isLoggedIn: .constant(false))
                    .onAppear {
                        UserManager.shared.currentUser = UserProfile.empty
                    }
            }
            .previewDisplayName("Ospite")
        }
    }
}
