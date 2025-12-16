import SwiftUI
import PhotosUI

// Oggetto temporaneo per accumulare i dati durante la registrazione
struct RegistrationData {
    var name = ""
    var surname = ""
    var email = ""
    var password = ""
    var bio = ""
    var motto = ""
    var age = 18
    var gender = "Man"
    var country = "🇮🇹 Italy"
    var image: Data? = nil
    var interests: Set<String> = []
}

// --- STEP 1: CREDENTIALS ---
struct RegistrationStep1: View {
    @Binding var isLoggedIn: Bool
    @State private var data = RegistrationData() // Dati accumulati
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToNext = false
    @State private var showAlert = false; @State private var alertMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.92).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        ZStack {
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer()
                            }
                            Text("Step 1/4").font(.subheadline).bold().foregroundColor(.gray)
                        }.padding(.top, 60)
                        
                        Text("Who are you?").font(.title).bold().foregroundColor(.appGreen)
                        
                        VStack(spacing: 20) {
                            CustomTextField(placeholder: "Name *", text: $data.name)
                            CustomTextField(placeholder: "Surname *", text: $data.surname)
                            CustomTextField(placeholder: "Email *", text: $data.email)
                            CustomTextField(placeholder: "Password *", text: $data.password, isSecure: true)
                        }
                        
                        Button(action: {
                            if data.name.isEmpty || data.surname.isEmpty || data.email.isEmpty || data.password.isEmpty { alertMessage = "Fill all fields"; showAlert = true }
                            else { navigateToNext = true }
                        }) {
                            Text("Continue").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 10)
                        }
                        .alert(isPresented: $showAlert) { Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
                        
                        // Passiamo 'data' al prossimo step
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep2(isLoggedIn: $isLoggedIn, data: data) } label: { EmptyView() }
                    }.padding(.horizontal).frame(minHeight: geometry.size.height)
                }
            }
        }.onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }.navigationBarHidden(true)
    }
}

// --- STEP 2: DETAILS ---
struct RegistrationStep2: View {
    @Binding var isLoggedIn: Bool
    @State var data: RegistrationData // Riceve dati
    
    @State private var showCamera = false; @State private var showGallery = false; @State private var showActionSheet = false
    @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil
    @State private var navigateToNext = false
    @Environment(\.presentationMode) var presentationMode
    
    let countries = ["🇮🇹 Italy", "🇺🇸 USA", "🇬🇧 UK", "🇫🇷 France", "🇪🇸 Spain", "🇩🇪 Germany", "🇨🇭 Switzerland", "🌍 Other"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.92).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        ZStack {
                            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer() }
                            VStack { Text("Step 2/4").font(.subheadline).bold().foregroundColor(.gray); Text("Details").font(.title).bold().foregroundColor(.appGreen) }
                        }.padding(.top, 60)
                        
                        VStack(spacing: 20) {
                            // Foto
                            ZStack {
                                Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 120, height: 120)
                                if let d = data.image, let ui = UIImage(data: d) { Image(uiImage: ui).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle()) }
                                else { Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 60).foregroundColor(.appGreen) }
                                Image(systemName: "camera.fill").foregroundColor(.white).padding(8).background(Color.appGreen).clipShape(Circle()).offset(x: 40, y: 40)
                            }.onTapGesture { showActionSheet = true }
                            
                            CustomTextField(placeholder: "Bio", text: $data.bio)
                            CustomTextField(placeholder: "Motto", text: $data.motto)
                            
                            HStack {
                                Picker("Gender", selection: $data.gender) { Text("Man").tag("Man"); Text("Woman").tag("Woman") }.pickerStyle(SegmentedPickerStyle())
                                Stepper("\(data.age) yrs", value: $data.age, in: 18...99)
                            }.padding()
                            
                            Picker("Country", selection: $data.country) { ForEach(countries, id: \.self) { Text($0).tag($0) } }.pickerStyle(MenuPickerStyle()).padding().background(Color.white).cornerRadius(10)
                        }
                        
                        Button(action: { navigateToNext = true }) {
                            Text("Continue").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 10)
                        }
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep3(isLoggedIn: $isLoggedIn, data: data) } label: { EmptyView() }
                    }.padding(.horizontal).frame(minHeight: geometry.size.height)
                }
            }
        }
        .confirmationDialog("Photo", isPresented: $showActionSheet) { Button("Camera") { showCamera = true }; Button("Gallery") { showGallery = true } }
        .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        .onChange(of: inputImage) { new in if let new = new { data.image = new.jpegData(compressionQuality: 0.8) } }
        .onChange(of: selectedItem) { item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { data.image = d } } }
        .navigationBarHidden(true)
    }
}

// --- STEP 3: SPORTS ---
struct RegistrationStep3: View {
    @Binding var isLoggedIn: Bool
    @State var data: RegistrationData
    @State private var navigateToNext = false
    @Environment(\.presentationMode) var presentationMode
    
    let sports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.92).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        ZStack {
                            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer() }
                            VStack { Text("Step 3/4").font(.subheadline).bold().foregroundColor(.gray); Text("Sports").font(.title).bold().foregroundColor(.appGreen) }
                        }.padding(.top, 60)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(sports, id: \.0) { sport in
                                Button(action: { if data.interests.contains(sport.0) { data.interests.remove(sport.0) } else { data.interests.insert(sport.0) } }) {
                                    VStack { Image(systemName: sport.1).font(.title2); Text(sport.0).font(.caption).bold() }
                                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .background(data.interests.contains(sport.0) ? Color.appGreen : Color.white)
                                    .foregroundColor(data.interests.contains(sport.0) ? .white : .gray)
                                    .cornerRadius(20).shadow(radius: 2)
                                }
                            }
                        }.padding()
                        
                        Button(action: { navigateToNext = true }) {
                            Text("Continue").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 10)
                        }
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep4(isLoggedIn: $isLoggedIn, data: data) } label: { EmptyView() }
                    }.padding(.horizontal).frame(minHeight: geometry.size.height)
                }
            }
        }.navigationBarHidden(true)
    }
}

// --- STEP 4: FINISH ---
struct RegistrationStep4: View {
    @Binding var isLoggedIn: Bool
    @State var data: RegistrationData
    @State private var sharePos = true; @State private var notif = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.92).ignoresSafeArea()
                
                VStack(spacing: 25) {
                    ZStack {
                        HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(radius: 4) }; Spacer() }
                        VStack { Text("Step 4/4").font(.subheadline).bold().foregroundColor(.gray); Text("Privacy").font(.title).bold().foregroundColor(.appGreen) }
                    }.padding(.top, 60)
                    
                    VStack(spacing: 15) { Toggle("Share Location", isOn: $sharePos); Toggle("Notifications", isOn: $notif) }
                        .padding().background(Color.white).cornerRadius(20).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    
                    Spacer()
                    
                    Button(action: {
                        // CREAZIONE NUOVO UTENTE
                        var newUser = UserProfile(
                            id: UUID(), // *** NUOVO ID UNIVOCO ***
                            name: data.name,
                            surname: data.surname,
                            age: data.age,
                            gender: data.gender,
                            bio: data.bio,
                            motto: data.motto,
                            image: "person.crop.circle.fill",
                            profileImageData: data.image,
                            email: data.email,
                            password: data.password,
                            interests: data.interests,
                            shareLocation: sharePos,
                            notifications: notif,
                            country: data.country
                        )
                        UserManager.shared.saveUser(newUser)
                        withAnimation { isLoggedIn = true }
                    }) {
                        Text("Finish!").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 10)
                    }
                    Spacer()
                }.padding(.horizontal)
            }
        }.navigationBarHidden(true)
    }
}
