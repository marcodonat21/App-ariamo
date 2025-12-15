import SwiftUI
import PhotosUI // NECESSARIO PER LA GALLERIA

// --- MAIN PROFILE SCREEN --- // Translated Comment
struct ProfileScreen: View {
    
    // Mock User Data // Translated Comment
    @State private var user = UserProfile(
        name: "Mario",
        surname: "Rossi",
        age: 25,
        gender: "Man",
        bio: "I love running and pizza!", // Translated
        motto: "Never give up",
        image: "person.crop.circle.fill",
        profileImageData: nil,
        email: "mario.rossi@email.com",
        password: "passwordSegreta",
        interests: ["Swimming", "Gym"],
        shareLocation: true,
        notifications: true,
        maxDistance: 10.0
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // PROFILE HEADER (Clickable) // Translated Comment
                NavigationLink(destination: EditProfileView(user: $user)) {
                    ProfileHeaderCard(user: user)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // ACTIVITIES MENU // Translated Comment
                VStack(spacing: 15) {
                    NavigationLink(destination: CreatedActivitiesView()) {
                        MenuRowItem(icon: "plus.circle.fill", title: "Created Activities", color: .appGreen) // Translated
                    }
                    
                    NavigationLink(destination: JoinedActivitiesView()) {
                        MenuRowItem(icon: "figure.run.circle.fill", title: "Joined Activities", color: .orange) // Translated
                    }
                }
                .padding(.horizontal)
                
                // Preferences Preview // Translated Comment
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your current preferences") // Translated
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    HStack {
                        PreferenceBadge(icon: "bell.fill", isActive: user.notifications)
                        PreferenceBadge(icon: "location.fill", isActive: user.shareLocation)
                        PreferenceBadge(text: "\(Int(user.maxDistance)) km", isActive: true)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
            .padding(.bottom, 100)
        }
        .navigationTitle("Profile") // Translated
    }
}

// Preference Badge
struct PreferenceBadge: View {
    var icon: String? = nil
    var text: String? = nil
    var isActive: Bool
    
    var body: some View {
        HStack {
            if let icon = icon { Image(systemName: icon) }
            if let text = text { Text(text) }
        }
        .padding(8)
        .background(isActive ? Color.appGreen.opacity(0.1) : Color.gray.opacity(0.1))
        .foregroundColor(isActive ? .appGreen : .gray)
        .cornerRadius(8)
    }
}

// --- EDIT SCREEN (ALL-IN-ONE) --- // Translated Comment
struct EditProfileView: View {
    @Binding var user: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    // Photo management states // Translated Comment
    @State private var showCamera = false
    @State private var showGallery = false // NEW: Controls gallery opening // Translated Comment
    @State private var showActionSheet = false
    
    @State private var selectedItem: PhotosPickerItem? = nil // For gallery
    @State private var inputImage: UIImage? = nil // Temporary camera image
    
    // Sports Data // Translated Comment
    let availableSports = [
        ("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"),
        ("Gym", "dumbbell.fill"), ("Cycle", "bicycle"),
        ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball"),
        ("Yoga", "figure.yoga"), ("Basket", "basketball.fill")
    ]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        Form {
            // SECTION 0: ADVANCED PROFILE PHOTO // Translated Comment
            Section(header: Text("Profile Photo")) { // Translated
                VStack(alignment: .center, spacing: 20) {
                    
                    // CURRENT PHOTO (or Default) // Translated Comment
                    ZStack {
                        // Circle Background
                        Circle()
                            .fill(Color.appGreen.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        // VISUALIZATION LOGIC: Do you have a real photo? // Translated Comment
                        if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                            // YES: Show real photo // Translated Comment
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            // NO: Show system icon // Translated Comment
                            Image(systemName: user.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.appGreen)
                        }
                        
                        // Overlay "Edit" Icon // Translated Comment
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.appGreen)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                    .onTapGesture {
                        showActionSheet = true // Open selection menu
                    }
                    
                    Text("Tap photo to edit") // Translated
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .confirmationDialog("Change Profile Photo", isPresented: $showActionSheet) { // Translated
                // OPTION 1: CAMERA
                Button("Take a photo") { // Translated
                    showCamera = true
                }
                
                // OPTION 2: GALLERY (Now in the menu!) // Translated
                Button("Choose from Gallery") { // Translated
                    showGallery = true
                }
                
                // OPTION 3: REMOVE PHOTO
                Button("Remove current photo", role: .destructive) { // Translated
                    user.profileImageData = nil
                }
                
                Button("Cancel", role: .cancel) { } // Translated
            } message: {
                Text("Choose how to change your image") // Translated
            }

            // SECTION 1: PERSONAL DATA
            Section(header: Text("Personal Data")) { // Translated
                TextField("First Name", text: $user.name); TextField("Last Name", text: $user.surname) // Translated Placeholders
                Picker("Gender", selection: $user.gender) { // Translated Label
                    Text("Man").tag("Man"); Text("Woman").tag("Woman"); Text("Other").tag("Other") // Translated
                }
                Stepper("Age: \(user.age) years", value: $user.age, in: 18...99) // Translated
            }
            
            // SECTION 2: INFO
            Section(header: Text("About you")) { // Translated
                TextField("Bio", text: $user.bio); TextField("Motto", text: $user.motto) // Translated Placeholders
            }
            
            // SECTION 3: ACCOUNT
            Section(header: Text("Credentials")) { // Translated
                TextField("Email", text: $user.email).keyboardType(.emailAddress).autocapitalization(.none)
                SecureField("Password", text: $user.password) // Translated Placeholder
            }
            
            // SECTION 4: PREFERENCES
            Section(header: Text("App Preferences")) { // Translated
                Toggle("Share Location", isOn: $user.shareLocation).toggleStyle(SwitchToggleStyle(tint: .appGreen)) // Translated
                Toggle("Receive Notifications", isOn: $user.notifications).toggleStyle(SwitchToggleStyle(tint: .appGreen)) // Translated
                VStack(alignment: .leading) {
                    Text("Max Distance: \(Int(user.maxDistance)) km") // Translated
                    Slider(value: $user.maxDistance, in: 1...100, step: 1).accentColor(.appGreen)
                }
            }
            
            // SECTION 5: SPORTS
            Section(header: Text("Your Sports")) { // Translated
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(availableSports, id: \.0) { sport in
                        Button(action: {
                            if user.interests.contains(sport.0) { user.interests.remove(sport.0) }
                            else { user.interests.insert(sport.0) }
                        }) {
                            VStack {
                                Image(systemName: sport.1).font(.title2)
                                Text(sport.0).font(.caption).bold()
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(user.interests.contains(sport.0) ? Color.appGreen : Color.gray.opacity(0.1))
                            .foregroundColor(user.interests.contains(sport.0) ? .white : .gray).cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // SAVE
            Section { // Translated
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Save Changes").bold().frame(maxWidth: .infinity).foregroundColor(.white).padding(10).background(Color.appGreen).cornerRadius(8) // Translated
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Edit Profile") // Translated
        
        // --- CAMERA SHEET --- // Translated Comment
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $inputImage)
        }
        
        // --- GALLERY PICKER (Activated by menu) --- // Translated Comment
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        
        // IMAGE SAVING LOGIC // Translated Comment
        
        // 1. From Camera
        .onChange(of: inputImage) { newImage in // Translated Comment
            if let newImage = newImage, let data = newImage.jpegData(compressionQuality: 0.8) {
                user.profileImageData = data
            }
        }
        // 2. From Gallery
        .onChange(of: selectedItem) { newItem in // Translated Comment
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    user.profileImageData = data
                }
            }
        }
    }
}

// --- REUSED UI COMPONENTS --- // Translated Comment
struct ProfileHeaderCard: View {
    let user: UserProfile
    var body: some View {
        HStack(spacing: 20) {
            // PHOTO VISUALIZATION LOGIC IN HEADER // Translated Comment
            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: user.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("\(user.name) \(user.surname)").font(.title2).bold().foregroundColor(.white)
                Text("\(user.age) years").font(.headline).foregroundColor(.white.opacity(0.9)) // Translated
                HStack { Text("Tap to edit"); Image(systemName: "pencil") } // Translated
                    .font(.caption).foregroundColor(.white).padding(.top, 5)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
        }
        .padding(25)
        .background(Color.appGreen)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct MenuRowItem: View {
    let icon: String; let title: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 40)
            Text(title).font(.headline).foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding().background(Color.white).cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct CreatedActivitiesView: View { var body: some View { Text("User created activities") } } // Translated
struct JoinedActivitiesView: View { var body: some View { Text("User joined activities") } } // Translated

// --- PREVIEW ---
struct ProfileFlow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileScreen()
        }
    }
}
