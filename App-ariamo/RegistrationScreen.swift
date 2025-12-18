import SwiftUI
import PhotosUI

// Oggetto temporaneo per accumulare i dati
struct RegistrationData {
    var name = ""
    var surname = ""
    var email = ""
    var password = ""
    var bio = ""
    var motto = ""
    var age = 18
    var gender = "Man" // Default
    var country = "🇮🇹 Italy"
    var image: Data? = nil
    var interests: Set<String> = []
}

// --- STEP 1: CREDENTIALS (INVARIATO - CON SUPPORTO KEYCHAIN) ---
struct RegistrationStep1: View {
    @Binding var isLoggedIn: Bool
    @State private var data = RegistrationData()
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToNext = false
    @State private var showAlert = false; @State private var alertMessage = ""
    
    @FocusState private var focusedField: Field?
    enum Field { case name, surname, email, password }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.95).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(10).background(Color.white).clipShape(Circle()).shadow(radius: 3)
                                }
                                Spacer()
                            }
                            Text("Step 1/3").font(.subheadline).bold().foregroundColor(.gray)
                        }
                        .padding(.top, 60)
                        
                        Text("Who are you?").font(.title).bold().foregroundColor(.appGreen).padding(.bottom, 5)
                        
                        VStack(spacing: 15) {
                            TextField("Name *", text: $data.name)
                                .focused($focusedField, equals: .name)
                                .textContentType(.givenName)
                                .submitLabel(.next)
                                .font(.system(.body, design: .rounded))
                                .padding().background(Color.white).cornerRadius(30).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 40)
                            
                            TextField("Surname *", text: $data.surname)
                                .focused($focusedField, equals: .surname)
                                .textContentType(.familyName)
                                .submitLabel(.next)
                                .font(.system(.body, design: .rounded))
                                .padding().background(Color.white).cornerRadius(30).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 40)
                            
                            TextField("Email *", text: $data.email)
                                .focused($focusedField, equals: .email)
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .submitLabel(.next)
                                .font(.system(.body, design: .rounded))
                                .padding().background(Color.white).cornerRadius(30).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 40)
                            
                            SecureField("Password *", text: $data.password)
                                .focused($focusedField, equals: .password)
                                .textContentType(.newPassword)
                                .submitLabel(.done)
                                .font(.system(.body, design: .rounded))
                                .padding().background(Color.white).cornerRadius(30).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 40)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if data.name.isEmpty || data.surname.isEmpty || data.email.isEmpty || data.password.isEmpty { alertMessage = "Fill all fields"; showAlert = true }
                            else { navigateToNext = true }
                        }) {
                            Text("Continue").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 5)
                        }
                        .alert(isPresented: $showAlert) { Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
                        .padding(.bottom, 20)
                        
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep2(isLoggedIn: $isLoggedIn, data: data) } label: { EmptyView() }
                    }
                    .padding(.horizontal)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .top)
                }
            }
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .navigationBarHidden(true)
    }
}

// --- STEP 2: DETAILS (RESTYLED & AGGIORNATO) ---
struct RegistrationStep2: View {
    @Binding var isLoggedIn: Bool
    @State var data: RegistrationData
    
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var showActionSheet = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var inputImage: UIImage? = nil
    @State private var navigateToNext = false
    @Environment(\.presentationMode) var presentationMode
    
    let countries = ["🇮🇹 Italy", "🇺🇸 USA", "🇬🇧 UK", "🇫🇷 France", "🇪🇸 Spain", "🇩🇪 Germany", "🇨🇭 Switzerland", "🌍 Other"]
    let genders = ["Man", "Woman", "Non-binary", "Prefer not to say"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.95).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // HEADER
                        ZStack {
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(10).background(Color.white).clipShape(Circle()).shadow(radius: 3)
                                }
                                Spacer()
                            }
                            VStack(spacing: 2) {
                                Text("Step 2/3").font(.subheadline).bold().foregroundColor(.gray)
                                Text("Details").font(.title2).bold().foregroundColor(.appGreen)
                            }
                        }
                        .padding(.top, 60)
                        
                        // FOTO PROFILO (Restyled)
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            
                            if let d = data.image, let ui = UIImage(data: d) {
                                Image(uiImage: ui).resizable().scaledToFill().frame(width: 110, height: 110).clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable().scaledToFit()
                                    .frame(width: 110)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            
                            // Badge Camera
                            Image(systemName: "camera.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.appGreen)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .offset(x: 40, y: 40)
                        }
                        .onTapGesture { showActionSheet = true }
                        .padding(.bottom, 10)
                        
                        // CAMPI DI TESTO
                        VStack(spacing: 15) {
                            CustomTextField(placeholder: "Bio (tell us about you)", text: $data.bio)
                            CustomTextField(placeholder: "Motto (your favorite quote)", text: $data.motto)
                            
                            // GENDER & AGE ROW (Restyled)
                            HStack(spacing: 15) {
                                // Gender Menu (Stile Pillola)
                                Menu {
                                    Picker("Gender", selection: $data.gender) {
                                        ForEach(genders, id: \.self) { g in Text(g).tag(g) }
                                    }
                                } label: {
                                    HStack {
                                        Text(data.gender.isEmpty ? "Gender" : data.gender)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Image(systemName: "chevron.down").foregroundColor(.appGreen)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(30)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                
                                // Age Stepper (Custom UI)
                                HStack {
                                    Button(action: { if data.age > 18 { data.age -= 1 } }) {
                                        Image(systemName: "minus").foregroundColor(.appGreen).frame(width: 30, height: 30)
                                    }
                                    
                                    Text("\(data.age)")
                                        .font(.headline)
                                        .frame(minWidth: 30)
                                    
                                    Button(action: { if data.age < 99 { data.age += 1 } }) {
                                        Image(systemName: "plus").foregroundColor(.appGreen).frame(width: 30, height: 30)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal, 40)
                            
                            // COUNTRY PICKER (Stile Pillola)
                            Menu {
                                Picker("Country", selection: $data.country) {
                                    ForEach(countries, id: \.self) { c in Text(c).tag(c) }
                                }
                            } label: {
                                HStack {
                                    Text(data.country)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "globe.europe.africa.fill").foregroundColor(.appGreen)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                        
                        Button(action: { navigateToNext = true }) {
                            Text("Continue").font(.headline).bold().foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(radius: 5)
                        }
                        .padding(.bottom, 20)
                        
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep3(isLoggedIn: $isLoggedIn, data: data) } label: { EmptyView() }
                    }
                    .padding(.horizontal)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .top)
                }
            }
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .confirmationDialog("Photo", isPresented: $showActionSheet) {
            Button("Camera") { showCamera = true }
            Button("Gallery") { showGallery = true }
        }
        .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }
        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
        .onChange(of: inputImage) { new in if let new = new { data.image = new.jpegData(compressionQuality: 0.8) } }
        .onChange(of: selectedItem) { item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { data.image = d } } }
        .navigationBarHidden(true)
    }
}

// --- STEP 3: SPORTS & FINISH (INVARIATO) ---
struct RegistrationStep3: View {
    @Binding var isLoggedIn: Bool
    @State var data: RegistrationData
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var showAlert = false; @State private var alertMessage = ""
    let sports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width).clipped().ignoresSafeArea()
                Color.white.opacity(0.95).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.headline).foregroundColor(.appGreen).padding(10).background(Color.white).clipShape(Circle()).shadow(radius: 3) }; Spacer() }
                            VStack(spacing: 2) { Text("Step 3/3").font(.subheadline).bold().foregroundColor(.gray); Text("Sports & Finish").font(.title2).bold().foregroundColor(.appGreen) }
                        }.padding(.top, 60)
                        
                        Text("Select your interests").font(.caption).foregroundColor(.gray)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(sports, id: \.0) { sport in
                                Button(action: { if data.interests.contains(sport.0) { data.interests.remove(sport.0) } else { data.interests.insert(sport.0) } }) {
                                    VStack { Image(systemName: sport.1).font(.title2); Text(sport.0).font(.caption).bold() }
                                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                                        .background(data.interests.contains(sport.0) ? Color.appGreen : Color.white)
                                        .foregroundColor(data.interests.contains(sport.0) ? .white : .gray).cornerRadius(15).shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                        }.padding(.horizontal, 5)
                        
                        Spacer()
                        
                        if isLoading { ProgressView().tint(.appGreen) } else {
                            Button(action: performRegistration) { Text("Finish!").font(.headline).bold().foregroundColor(.white).padding().frame(width: 160).background(Color.appGreen).cornerRadius(30).shadow(radius: 5) }.padding(.bottom, 50)
                        }
                    }
                    .padding(.horizontal)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .top)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) { Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
    }
    
    func performRegistration() {
        isLoading = true
        let newUser = UserProfile(id: UUID(), name: data.name, surname: data.surname, age: data.age, gender: data.gender, bio: data.bio, motto: data.motto, image: "person.crop.circle.fill", profileImageData: data.image, email: data.email, password: data.password, interests: data.interests, shareLocation: true, notifications: true, country: data.country)
        Task {
            do {
                try await UserManager.shared.signUp(user: newUser)
            } catch {
                alertMessage = "Registration failed: \(error.localizedDescription)"; showAlert = true
            }
            isLoading = false
        }
    }
}
