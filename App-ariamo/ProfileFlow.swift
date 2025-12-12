import SwiftUI
import PhotosUI // NECESSARIO PER LA GALLERIA

// --- SCHERMATA PROFILO PRINCIPALE ---
struct ProfileScreen: View {
    
    @State private var user = UserProfile(
        name: "Mario",
        surname: "Rossi",
        age: 25,
        gender: "Man",
        bio: "Amo la corsa e la pizza!",
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
                
                // HEADER PROFILO (Cliccabile)
                NavigationLink(destination: EditProfileView(user: $user)) {
                    ProfileHeaderCard(user: user)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // MENU ATTIVITÀ
                VStack(spacing: 15) {
                    NavigationLink(destination: CreatedActivitiesView()) {
                        MenuRowItem(icon: "plus.circle.fill", title: "Attività Create", color: .appGreen)
                    }
                    
                    NavigationLink(destination: JoinedActivitiesView()) {
                        MenuRowItem(icon: "figure.run.circle.fill", title: "Attività alle quali partecipi", color: .orange)
                    }
                }
                .padding(.horizontal)
                
                // Anteprima Preferenze
                VStack(alignment: .leading, spacing: 10) {
                    Text("Le tue preferenze attuali")
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
        .navigationTitle("Profile")
    }
}

// Badge Preferenze
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

// --- SCHERMATA MODIFICA (ALL-IN-ONE) ---
struct EditProfileView: View {
    @Binding var user: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    // Stati per la gestione Foto
    @State private var showCamera = false
    @State private var showGallery = false // NUOVO: Controlla apertura galleria
    @State private var showActionSheet = false
    
    @State private var selectedItem: PhotosPickerItem? = nil // Per la galleria
    @State private var inputImage: UIImage? = nil // Immagine temporanea camera
    
    // Dati Sport
    let availableSports = [
        ("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"),
        ("Gym", "dumbbell.fill"), ("Cycle", "bicycle"),
        ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball"),
        ("Yoga", "figure.yoga"), ("Basket", "basketball.fill")
    ]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        Form {
            // SEZIONE 0: FOTO PROFILO AVANZATA
            Section(header: Text("Foto Profilo")) {
                VStack(alignment: .center, spacing: 20) {
                    
                    // FOTO ATTUALE (O Default)
                    ZStack {
                        // Sfondo Cerchio
                        Circle()
                            .fill(Color.appGreen.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        // LOGICA VISUALIZZAZIONE: Hai una foto reale?
                        if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                            // SI: Mostra la foto reale
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            // NO: Mostra l'icona di sistema
                            Image(systemName: user.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.appGreen)
                        }
                        
                        // Icona "Edit" sovrapposta
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
                        showActionSheet = true // Apre il menu scelta
                    }
                    
                    Text("Tocca la foto per modificare")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .confirmationDialog("Cambia foto profilo", isPresented: $showActionSheet) {
                // OPZIONE 1: FOTOCAMERA
                Button("Scatta una foto") {
                    showCamera = true
                }
                
                // OPZIONE 2: GALLERIA (Ora nel menu!)
                Button("Scegli dalla Galleria") {
                    showGallery = true
                }
                
                // OPZIONE 3: RIMUOVI FOTO
                Button("Rimuovi foto attuale", role: .destructive) {
                    user.profileImageData = nil
                }
                
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Scegli come cambiare la tua immagine")
            }

            // SEZIONE 1: DATI PERSONALI
            Section(header: Text("Anagrafica")) {
                TextField("Nome", text: $user.name); TextField("Cognome", text: $user.surname)
                Picker("Genere", selection: $user.gender) {
                    Text("Uomo").tag("Man"); Text("Donna").tag("Woman"); Text("Altro").tag("Other")
                }
                Stepper("Età: \(user.age) anni", value: $user.age, in: 18...99)
            }
            
            // SEZIONE 2: INFO
            Section(header: Text("Su di te")) { TextField("Bio", text: $user.bio); TextField("Motto", text: $user.motto) }
            
            // SEZIONE 3: ACCOUNT
            Section(header: Text("Credenziali")) {
                TextField("Email", text: $user.email).keyboardType(.emailAddress).autocapitalization(.none)
                SecureField("Password", text: $user.password)
            }
            
            // SEZIONE 4: PREFERENZE
            Section(header: Text("Preferenze App")) {
                Toggle("Condividi Posizione", isOn: $user.shareLocation).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                Toggle("Ricevi Notifiche", isOn: $user.notifications).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                VStack(alignment: .leading) {
                    Text("Distanza Max: \(Int(user.maxDistance)) km")
                    Slider(value: $user.maxDistance, in: 1...100, step: 1).accentColor(.appGreen)
                }
            }
            
            // SEZIONE 5: SPORT
            Section(header: Text("I tuoi Sport")) {
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
            
            // SALVA
            Section {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Salva Modifiche").bold().frame(maxWidth: .infinity).foregroundColor(.white).padding(10).background(Color.appGreen).cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Modifica Profilo")
        
        // --- SHEET FOTOCAMERA ---
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $inputImage)
        }
        
        // --- PICKER GALLERIA (Attivato dal menu) ---
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        
        // LOGICA DI SALVATAGGIO IMMAGINI
        
        // 1. Dalla Fotocamera
        .onChange(of: inputImage) { newImage in
            if let newImage = newImage, let data = newImage.jpegData(compressionQuality: 0.8) {
                user.profileImageData = data
            }
        }
        // 2. Dalla Galleria
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    user.profileImageData = data
                }
            }
        }
    }
}

// --- COMPONENTI UI RIUTILIZZATI ---
struct ProfileHeaderCard: View {
    let user: UserProfile
    var body: some View {
        HStack(spacing: 20) {
            // LOGICA VISUALIZZAZIONE FOTO NELL'HEADER
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
                Text("\(user.age) anni").font(.headline).foregroundColor(.white.opacity(0.9))
                HStack { Text("Clicca per modificare"); Image(systemName: "pencil") }
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

struct CreatedActivitiesView: View { var body: some View { Text("Attività create dall'utente") } }
struct JoinedActivitiesView: View { var body: some View { Text("Attività a cui partecipa l'utente") } }

// --- PREVIEW ---
struct ProfileFlow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileScreen()
        }
    }
}
