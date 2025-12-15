import SwiftUI

// --- STEP 1: CREDENTIALS & NAME ---
struct RegistrationStep1: View {
    @Binding var isLoggedIn: Bool
    @State private var name = ""; @State private var surname = ""; @State private var email = ""; @State private var password = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToNext = false; @State private var showAlert = false; @State private var alertMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).clipped().ignoresSafeArea(.all)
                Color.white.opacity(0.92).ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        ZStack { HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).fontWeight(.bold).foregroundColor(.appGreen) }; Spacer() }; Text("Step 1/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray) }.padding(.top, 60)
                        
                        Text("Who are you?").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                        
                        VStack(spacing: 20) {
                            CustomTextField(placeholder: "Name *", text: $name)
                            CustomTextField(placeholder: "Surname *", text: $surname)
                            CustomTextField(placeholder: "Email *", text: $email)
                            CustomTextField(placeholder: "Password *", text: $password, isSecure: true)
                            Text("Password must be at least 8 characters, contain a number and a special character.").font(.caption2).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                        }
                        
                        Spacer().frame(height: 30)
                        
                        Button(action: {
                            endEditing()
                            if name.isEmpty || surname.isEmpty || email.isEmpty || password.isEmpty { alertMessage = "Please fill in all fields marked with *."; showAlert = true }
                            else if !Validator.isValidEmail(email) { alertMessage = "Invalid email format. Must contain '@' and '.'"; showAlert = true }
                            else if !Validator.isValidPassword(password) { alertMessage = "Password is too weak.\nIt must have min 8 chars, 1 number, and 1 special character."; showAlert = true }
                            else { navigateToNext = true }
                        }) {
                            Text("Continue").font(.system(.headline, design: .rounded).bold()).foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .alert(isPresented: $showAlert) { Alert(title: Text("Attention"), message: Text(alertMessage), dismissButton: .default(Text("OK"))) }
                        
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep2(isLoggedIn: $isLoggedIn) } label: { EmptyView() }
                        Spacer()
                    }.frame(minHeight: geometry.size.height).padding(.horizontal)
                }
            }
        }.onTapGesture { endEditing() }.ignoresSafeArea(.keyboard, edges: .bottom).navigationBarHidden(true)
    }
}

// --- STEP 2: PERSONAL DETAILS (Updated: Bio/Motto Optional, New Genders) ---
struct RegistrationStep2: View {
    @Binding var isLoggedIn: Bool
    @State private var bio = ""; @State private var motto = ""; @State private var age = 18; @State private var gender = "Man"
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToNext = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).clipped().ignoresSafeArea(.all)
                Color.white.opacity(0.92).ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        ZStack { HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).fontWeight(.bold).foregroundColor(.appGreen) }; Spacer() }; VStack { Text("Step 2/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray); Text("Tell us about you").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen) } }.padding(.top, 60)
                        
                        VStack(spacing: 20) {
                            // NO ASTERISK (*) - OPTIONAL
                            CustomTextField(placeholder: "Bio", text: $bio)
                            CustomTextField(placeholder: "Your Motto", text: $motto)
                            
                            HStack(spacing: 10) {
                                HStack(spacing: 5) {
                                    Text("Gender:").font(.caption).foregroundColor(.gray).fixedSize()
                                    // UPDATED PICKER WITH NEW OPTIONS
                                    Picker("", selection: $gender) {
                                        Text("Man").tag("Man")
                                        Text("Woman").tag("Woman")
                                        Text("Non-binary").tag("Non-binary")
                                        Text("Prefer not to say").tag("Prefer not to say")
                                    }
                                    .accentColor(.appGreen).labelsHidden().fixedSize()
                                }
                                .padding(10).background(Color.white).cornerRadius(30)
                                
                                Spacer()
                                HStack(spacing: 5) { Text("Age: \(age)").font(.caption).foregroundColor(.gray).fixedSize(); Stepper("", value: $age, in: 18...99).labelsHidden().scaleEffect(0.9) }.padding(10).background(Color.white).cornerRadius(30)
                            }.padding(.horizontal, 10)
                        }
                        
                        Spacer().frame(height: 30)
                        
                        Button(action: {
                            endEditing()
                            // NO VALIDATION BLOCK for Bio/Motto
                            navigateToNext = true
                        }) {
                            Text("Continue").font(.system(.headline, design: .rounded).bold()).foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep3(isLoggedIn: $isLoggedIn) } label: { EmptyView() }
                        Spacer()
                    }.frame(minHeight: geometry.size.height).padding(.horizontal)
                }
            }
        }.onTapGesture { endEditing() }.ignoresSafeArea(.keyboard, edges: .bottom).navigationBarHidden(true)
    }
}

// --- STEP 3: SPORTS ---
struct RegistrationStep3: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedSports: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    let sports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    @State private var navigateToNext = false; @State private var showAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).clipped().ignoresSafeArea(.all)
                Color.white.opacity(0.92).ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        ZStack { HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).fontWeight(.bold).foregroundColor(.appGreen) }; Spacer() }; VStack { Text("Step 3/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray); Text("Your Sports *").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen) } }.padding(.top, 60)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(sports, id: \.0) { sport in
                                Button(action: { if selectedSports.contains(sport.0) { selectedSports.remove(sport.0) } else { selectedSports.insert(sport.0) } }) {
                                    VStack { Image(systemName: sport.1).font(.title2); Text(sport.0).font(.caption).bold() }
                                    .frame(maxWidth: .infinity).padding(.vertical, 15).background(selectedSports.contains(sport.0) ? Color.appGreen : Color.white).foregroundColor(selectedSports.contains(sport.0) ? .white : .gray).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                        }.padding()
                        
                        Spacer().frame(height: 30)
                        Button(action: {
                            if selectedSports.isEmpty { showAlert = true } else { navigateToNext = true }
                        }) {
                            Text("Continue").font(.system(.headline, design: .rounded).bold()).foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .alert(isPresented: $showAlert) { Alert(title: Text("Select Sport"), message: Text("Please select at least one sport."), dismissButton: .default(Text("OK"))) }
                        NavigationLink(isActive: $navigateToNext) { RegistrationStep4(isLoggedIn: $isLoggedIn) } label: { EmptyView() }
                        Spacer()
                    }.frame(minHeight: geometry.size.height).padding(.horizontal)
                }
            }
        }.ignoresSafeArea(.keyboard, edges: .bottom).navigationBarHidden(true)
    }
}

// --- STEP 4: PREFERENCES & END ---
struct RegistrationStep4: View {
    @Binding var isLoggedIn: Bool
    @State private var sharePos = true; @State private var notif = true; @State private var dist = 10.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("app_foto").resizable().scaledToFill().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).clipped().ignoresSafeArea(.all)
                Color.white.opacity(0.92).ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        ZStack { HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).fontWeight(.bold).foregroundColor(.appGreen) }; Spacer() }; VStack { Text("Step 4/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray); Text("Preferences").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen) } }.padding(.top, 60)
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 15) { Toggle("Share Location", isOn: $sharePos); Toggle("Receive Notifications", isOn: $notif) }.padding().background(Color.white).cornerRadius(20).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                            VStack { Text("Max Distance: \(Int(dist)) km").font(.caption).foregroundColor(.gray); Slider(value: $dist, in: 1...100, step: 1).accentColor(.appGreen) }.padding().background(Color.white).cornerRadius(20)
                        }.padding(.horizontal)
                        
                        Spacer().frame(height: 30)
                        Button(action: { endEditing(); withAnimation { isLoggedIn = true } }) {
                            Text("Go!").font(.system(.headline, design: .rounded).bold()).foregroundColor(.white).padding().frame(width: 140).background(Color.appGreen).cornerRadius(30).shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        Spacer()
                    }.frame(minHeight: geometry.size.height).padding(.horizontal)
                }
            }
        }.onTapGesture { endEditing() }.ignoresSafeArea(.keyboard, edges: .bottom).navigationBarHidden(true)
    }
}
