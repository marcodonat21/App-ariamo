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
                    VStack(spacing: 20) {
                        
                        // --- TITOLO "ABOUT YOU!" ---
                        Text("About you!")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.themeText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                            .padding(.top, 20)
                        
                        // CARD VERDE PROFILO
                        NavigationLink(destination: EditProfileView(user: $userManager.currentUser, isLoggedIn: $isLoggedIn)) {
                            ProfileHeaderCard(user: userManager.currentUser)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 10)
                        
                        Divider().padding(.vertical, 10)
                        
                        // MENU ATTIVITÀ
                        VStack(spacing: 15) {
                            NavigationLink(destination: CreatedActivitiesView(onLoginRequest: onLoginRequest)) {
                                MenuRowItem(icon: "plus.circle.fill", title: "Created Activities", color: .appGreen)
                            }
                            NavigationLink(destination: JoinedActivitiesView(onLoginRequest: onLoginRequest)) {
                                MenuRowItem(icon: "figure.run.circle.fill", title: "Joined Activities", color: .orange)
                            }
                            NavigationLink(destination: FavoriteActivitiesView(onLoginRequest: onLoginRequest)) {
                                MenuRowItem(icon: "heart.circle.fill", title: "Favorite Activities", color: .red)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider().padding(.vertical, 10)
                        
                        // LOGOUT
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
                        
                        // SPAZIO FINALE PULITO (Per non far coprire il tasto dalla TabBar)
                        Spacer().frame(height: 100)
                    }
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

// --- EDIT PROFILE VIEW (NUOVO DESIGN SENZA "FORM") ---
struct EditProfileView: View {
    @Binding var user: UserProfile
    @Binding var isLoggedIn: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showCamera = false; @State private var showGallery = false; @State private var showActionSheet = false
    @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    
    let availableSports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball"), ("Yoga", "figure.yoga"), ("Basketball", "basketball.fill")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    let countries = ["🇮🇹 Italy", "🇺🇸 USA", "🇬🇧 UK", "🇫🇷 France", "🇪🇸 Spain", "🇩🇪 Germany", "🇨🇭 Switzerland", "🌍 Other"]
    let genders = ["Man", "Woman", "Non-binary", "Prefer not to say"]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea().onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer(); Text("Edit Profile").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44)
                }
                .padding().padding(.top, 10).background(Color(UIColor.systemGray6))
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // FOTO PROFILO
                        VStack(alignment: .center) {
                            ZStack {
                                Circle().fill(Color.white).frame(width: 125, height: 125).shadow(color: .black.opacity(0.05), radius: 5)
                                if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 115, height: 115).clipShape(Circle())
                                } else {
                                    Image(systemName: user.image).resizable().aspectRatio(contentMode: .fit).frame(width: 60, height: 60).foregroundColor(.appGreen)
                                }
                                Image(systemName: "camera.fill").foregroundColor(.white).padding(8).background(Color.appGreen).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 3)).offset(x: 40, y: 40)
                            }
                            .onTapGesture { showActionSheet = true }
                            Text("Change Photo").font(.caption).foregroundColor(.appGreen).padding(.top, 5)
                        }
                        .padding(.top, 10)
                        
                        // SECTION: CREDENTIALS
                        EditProfileCard(title: "Credentials") {
                            VStack(spacing: 15) {
                                CustomProfileTextField(title: "Email", text: $user.email, icon: "envelope.fill", keyboardType: .emailAddress)
                                CustomProfileSecureField(title: "New Password", text: $user.password, icon: "lock.fill")
                            }
                        }
                        
                        // SECTION: PERSONAL DATA
                        EditProfileCard(title: "Personal Data") {
                            VStack(spacing: 15) {
                                HStack(spacing: 15) {
                                    CustomProfileTextField(title: "Name", text: $user.name, icon: "person.fill")
                                    CustomProfileTextField(title: "Surname", text: $user.surname, icon: "")
                                }
                                
                                // Gender & Country
                                HStack(spacing: 10) {
                                    Menu {
                                        Picker("Gender", selection: $user.gender) {
                                            ForEach(genders, id: \.self) { g in Text(g).tag(g) }
                                        }
                                    } label: {
                                        HStack {
                                            Text(user.gender).font(.subheadline).foregroundColor(.black)
                                            Spacer()
                                            Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    
                                    Menu {
                                        Picker("Country", selection: $user.country) {
                                            ForEach(countries, id: \.self) { c in Text(c).tag(c) }
                                        }
                                    } label: {
                                        HStack {
                                            Text(user.country).font(.subheadline).foregroundColor(.black).lineLimit(1)
                                            Spacer()
                                            Image(systemName: "globe").font(.caption).foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                    }
                                }
                                
                                // Age Stepper
                                HStack {
                                    Text("Age").font(.subheadline).foregroundColor(.gray)
                                    Spacer()
                                    Button(action: { if user.age > 18 { user.age -= 1 } }) { Image(systemName: "minus.circle.fill").foregroundColor(.appGreen).font(.title3) }
                                    Text("\(user.age)").font(.headline).frame(width: 30)
                                    Button(action: { if user.age < 99 { user.age += 1 } }) { Image(systemName: "plus.circle.fill").foregroundColor(.appGreen).font(.title3) }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                
                                CustomProfileTextField(title: "Bio", text: $user.bio, icon: "text.quote")
                                CustomProfileTextField(title: "Motto", text: $user.motto, icon: "star.fill")
                            }
                        }
                        
                        // SECTION: SPORTS
                        EditProfileCard(title: "Sports Interests") {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(availableSports, id: \.0) { sport in
                                    Button(action: {
                                        if user.interests.contains(sport.0) { user.interests.remove(sport.0) }
                                        else { user.interests.insert(sport.0) }
                                    }) {
                                        VStack { Image(systemName: sport.1); Text(sport.0).font(.caption2).bold() }
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(user.interests.contains(sport.0) ? Color.appGreen : Color(UIColor.systemGray6))
                                            .foregroundColor(user.interests.contains(sport.0) ? .white : .gray)
                                            .cornerRadius(10)
                                            //.shadow(color: .black.opacity(0.05), radius: 2)
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // SAVE BUTTON
                        if isLoading {
                            ProgressView().tint(.appGreen)
                        } else {
                            Button(action: saveProfile) {
                                Text("Save Changes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.appGreen)
                                    .cornerRadius(15)
                                    .shadow(color: .appGreen.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal)
                        }
                        
                        // DELETE ACCOUNT BUTTON (PULITO E IN BASSO)
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(.red)
                            .padding()
                        }
                        .padding(.bottom, 80) // SPAZIO PER NON ANDARE SOTTO LA BARRA
                    }
                    .padding(.bottom, 20)
                }
            }
            
            if showDeleteConfirmation {
                LiquidConfirmationModal(title: "Delete Account", message: "This action is irreversible. All your data will be lost.", actionTitle: "Delete Forever", isDestructive: true, onCancel: { showDeleteConfirmation = false }, onConfirm: {
                    Task {
                        do {
                            try await UserManager.shared.deleteAccount()
                            isLoggedIn = false
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Error deleting account: \(error)")
                        }
                    }
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
    
    func saveProfile() {
        hideKeyboard()
        isLoading = true
        Task {
            do {
                try await UserManager.shared.updateUserProfile(user: user)
                if !user.email.isEmpty && !user.password.isEmpty {
                   try await UserManager.shared.updateCredentials(email: user.email, password: user.password)
                }
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Errore aggiornamento: \(error)")
            }
            isLoading = false
        }
    }
}

// --- HELPER COMPONENTS PER EDIT PROFILE ---
struct EditProfileCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).bold().foregroundColor(.gray).padding(.leading, 5)
            VStack {
                content
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

struct CustomProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            if !icon.isEmpty { Image(systemName: icon).foregroundColor(.appGreen).frame(width: 20) }
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct CustomProfileSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            if !icon.isEmpty { Image(systemName: icon).foregroundColor(.appGreen).frame(width: 20) }
            SecureField(title, text: $text)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

// --- LISTE ATTIVITÀ (PADDING CORRETTO) ---

struct CreatedActivitiesView: View {
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    var onLoginRequest: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer(); Text("Created Activities").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44) }.padding().padding(.top, 10)
            if manager.createdActivities.isEmpty { Spacer(); Text("No activities created yet.").foregroundColor(.gray); Spacer() }
            else { ScrollView { VStack(spacing: 15) { ForEach(manager.createdActivities) { activity in NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: { _ in onLoginRequest?() })) { ActivityRow(activity: activity) } } }.padding() } }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

struct JoinedActivitiesView: View {
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    var onLoginRequest: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer(); Text("Joined Activities").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44) }.padding().padding(.top, 10)
            if manager.joinedActivities.isEmpty { Spacer(); Text("No activities joined yet.").foregroundColor(.gray); Spacer() }
            else { ScrollView { VStack(spacing: 15) { ForEach(manager.joinedActivities) { activity in NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: { _ in onLoginRequest?() })) { ActivityRow(activity: activity) } } }.padding() } }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

struct FavoriteActivitiesView: View {
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    var onLoginRequest: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4)
                }
                Spacer(); Text("Favorite Activities").font(.headline).bold(); Spacer(); Color.clear.frame(width: 44, height: 44)
            }.padding().padding(.top, 10)
            
            if manager.favoriteActivitiesList.isEmpty {
                Spacer(); Text("No favorites yet.").foregroundColor(.gray); Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(manager.favoriteActivitiesList) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: { _ in onLoginRequest?() })) {
                                ActivityRow(activity: activity)
                            }
                        }
                    }.padding()
                }
            }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

// --- ACTIVITY ROW STYLE: "Category View Like" (Circle + Green Border) ---
struct ActivityRow: View {
    let activity: Activity
    @ObservedObject var manager = ActivityManager.shared
    
    var body: some View {
        HStack(spacing: 15) {
            // IMMAGINE TONDA CON BORDO VERDE
            Group {
                if let data = activity.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
                } else if let urlStr = activity.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
                } else {
                    Image(systemName: activity.imageName)
                        .font(.title) // Icona grande come nella CategoryView
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(activity.color)
                        .clipShape(Circle())
                }
            }
            .frame(width: 60, height: 60)
            
            // TESTI
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // ICONE DI STATO (Stella, Cuore, Spunta, Freccia)
            HStack(spacing: 6) {
                // 1. STELLA (Creator)
                if manager.isCreator(activity: activity) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                // 2. CUORE (Favorite)
                if manager.isFavorite(activity: activity) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // 3. SPUNTA (Joined)
                if manager.isJoined(activity: activity) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appGreen)
                        .font(.caption)
                }
                
                // 4. FRECCIA
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15) // Card Arrotondata
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("\(user.name) \(user.surname)").font(.title2).bold().foregroundColor(.white)
                Text("\(user.age) years • \(user.gender)").font(.subheadline).foregroundColor(.white.opacity(0.9))
                HStack { Text("Tap to edit profile"); Image(systemName: "pencil") }.font(.caption2).bold().foregroundColor(.white).padding(.top, 5)
            }
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
        }.padding(25).background(Color.appGreen).cornerRadius(20).shadow(radius: 5).padding(.horizontal)
    }
}

struct MenuRowItem: View {
    let icon: String; let title: String; let color: Color
    var body: some View {
        HStack { Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 40); Text(title).font(.headline).foregroundColor(.black); Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray) }
        .padding().background(Color.white).cornerRadius(15).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2), lineWidth: 1))
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
                VStack(spacing: 10) { Text(title).font(.title2).bold(); Text(message).font(.body).multilineTextAlignment(.center).foregroundColor(.gray).padding(.horizontal) }
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
            NavigationView {
                ProfileScreen(isLoggedIn: .constant(true))
                    .onAppear {
                        UserManager.shared.currentUser = UserProfile(name: "Mario", surname: "Rossi", age: 30, gender: "Man", bio: "Ciao!", motto: "", image: "person.circle", email: "mario@rossi.it", password: "password", interests: ["Swimming", "Hiking"], shareLocation: true, notifications: true)
                    }
            }.previewDisplayName("Loggato")
            NavigationView {
                ProfileScreen(isLoggedIn: .constant(false))
                    .onAppear { UserManager.shared.currentUser = UserProfile.empty }
            }.previewDisplayName("Ospite")
        }
    }
}
