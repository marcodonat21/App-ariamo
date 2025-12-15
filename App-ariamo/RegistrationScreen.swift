import SwiftUI

// --- STEP 1: CREDENTIALS & NAME ---
struct RegistrationStep1: View {
    @Binding var isLoggedIn: Bool
    
    // Data for this step
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // Background
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            // CONTENUTO RESO SCORREVOLE
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Title
                    Text("Step 1/4")
                        .font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray).padding(.top, 60)
                    Text("Who are you?")
                        .font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                    
                    // Fields
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Name", text: $name)
                        CustomTextField(placeholder: "Surname", text: $surname)
                        CustomTextField(placeholder: "Email", text: $email)
                        CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                    }
                    
                    Spacer()
                    
                    // "Continue" Button
                    NavigationLink(destination: RegistrationStep2(isLoggedIn: $isLoggedIn)) {
                        Text("Continue")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140)
                            .background(Color.appGreen)
                            .cornerRadius(30)
                            .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 60)
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height) // Forziamo l'altezza minima
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // IGNORA TASTIERA
        .navigationBarHidden(true)
    }
}

// --- STEP 2: PERSONAL DETAILS (GENDER FIX) ---
struct RegistrationStep2: View {
    @Binding var isLoggedIn: Bool
    @State private var bio = ""
    @State private var motto = ""
    @State private var age = 18
    @State private var gender = "Man"
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            // CONTENUTO RESO SCORREVOLE
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Header with custom back button
                    ZStack {
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen)
                            }
                            Spacer()
                        }
                        VStack {
                            Text("Step 2/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                            Text("Tell us about you")
                                .font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Fields
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Bio (e.g. I love sports)", text: $bio)
                        CustomTextField(placeholder: "Your Motto", text: $motto)
                        
                        // Age and Gender on the same row
                        HStack(spacing: 10) {
                            // Gender Picker
                            HStack(spacing: 5) {
                                Text("Gender:")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .fixedSize()
                                
                                Picker("", selection: $gender) {
                                    Text("Man").tag("Man")
                                    Text("Woman").tag("Woman")
                                }
                                .accentColor(.appGreen)
                                .labelsHidden()
                                .fixedSize() // FIX: Prevents text wrap
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                            .background(Color.white)
                            .cornerRadius(30)
                            
                            Spacer()
                            
                            // Age Stepper
                            HStack(spacing: 5) {
                                Text("Age: \(age)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .fixedSize()
                                
                                Stepper("", value: $age, in: 18...99)
                                    .labelsHidden()
                                    .scaleEffect(0.9)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                            .background(Color.white)
                            .cornerRadius(30)
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: RegistrationStep3(isLoggedIn: $isLoggedIn)) {
                        Text("Continue")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140)
                            .background(Color.appGreen)
                            .cornerRadius(30)
                            .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 60)
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height) // Forziamo l'altezza minima
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // IGNORA TASTIERA
        .navigationBarHidden(true)
    }
}

// --- STEP 3: SPORTS ---
struct RegistrationStep3: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedSports: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    
    let sports = [("Swimming", "figure.pool.swim"), ("Hiking", "figure.hiking"), ("Gym", "dumbbell.fill"), ("Cycling", "bicycle"), ("Tennis", "tennis.racket"), ("Volleyball", "figure.volleyball")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        ZStack {
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            // CONTENUTO RESO SCORREVOLE
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    ZStack {
                        HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen) }; Spacer() }
                        VStack {
                            Text("Step 3/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                            Text("Your Sports")
                                .font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                        }
                    }.padding(.top, 60)
                    
                    // Contenuto Scrollable degli Sport
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(sports, id: \.0) { sport in
                            Button(action: {
                                if selectedSports.contains(sport.0) { selectedSports.remove(sport.0) }
                                else { selectedSports.insert(sport.0) }
                            }) {
                                VStack {
                                    Image(systemName: sport.1).font(.title2)
                                    Text(sport.0).font(.caption).bold()
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(selectedSports.contains(sport.0) ? Color.appGreen : Color.white)
                                .foregroundColor(selectedSports.contains(sport.0) ? .white : .gray)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                    }.padding()
                    
                    Spacer()
                    
                    NavigationLink(destination: RegistrationStep4(isLoggedIn: $isLoggedIn)) {
                        Text("Continue")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140)
                            .background(Color.appGreen)
                            .cornerRadius(30)
                            .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 60)
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height) // Forziamo l'altezza minima
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // IGNORA TASTIERA
        .navigationBarHidden(true)
    }
}

// --- STEP 4: PREFERENCES & END ---
struct RegistrationStep4: View {
    @Binding var isLoggedIn: Bool
    @State private var sharePos = true
    @State private var notif = true
    @State private var dist = 10.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            // CONTENUTO RESO SCORREVOLE
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    ZStack {
                        HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen) }; Spacer() }
                        VStack {
                            Text("Step 4/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                            Text("Preferences")
                                .font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                        }
                    }.padding(.top, 60)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 15) {
                            Toggle("Share Location", isOn: $sharePos)
                            Toggle("Receive Notifications", isOn: $notif)
                        }
                        .padding().background(Color.white).cornerRadius(20).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                        
                        VStack {
                            Text("Max Distance: \(Int(dist)) km").font(.caption).foregroundColor(.gray)
                            Slider(value: $dist, in: 1...100, step: 1).accentColor(.appGreen)
                        }
                        .padding().background(Color.white).cornerRadius(20)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // FINAL GO BUTTON
                    Button(action: {
                        withAnimation { isLoggedIn = true }
                    }) {
                        Text("Go!")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140)
                            .background(Color.appGreen)
                            .cornerRadius(30)
                            .shadow(color: .appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 60)
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height) // Forziamo l'altezza minima
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // IGNORA TASTIERA
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        RegistrationStep2(isLoggedIn: .constant(false))
    }
}
