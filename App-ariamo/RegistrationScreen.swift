import SwiftUI

// --- STEP 1: CREDENZIALI & NOME ---
struct RegistrationStep1: View {
    @Binding var isLoggedIn: Bool
    
    // Dati di questo step
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // Sfondo
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            VStack(spacing: 25) {
                // Titolo
                Text("Step 1/4")
                    .font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray).padding(.top, 60)
                Text("Chi sei?")
                    .font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                
                // Campi
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Nome", text: $name)
                    CustomTextField(placeholder: "Cognome", text: $surname)
                    CustomTextField(placeholder: "Email", text: $email)
                    CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                }
                
                Spacer()
                
                // Bottone "Continua"
                NavigationLink(destination: RegistrationStep2(isLoggedIn: $isLoggedIn)) {
                    Text("Continua")
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
        }
        .navigationBarHidden(true)
    }
}

// --- STEP 2: DETTAGLI PERSONALI (FIX GENERE) ---
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
            
            VStack(spacing: 25) {
                // Header con tasto indietro custom
                ZStack {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen)
                        }
                        Spacer()
                    }
                    VStack {
                        Text("Step 2/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                        Text("Parlaci di te").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                    }
                }
                .padding(.top, 60)
                
                // Campi
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Bio (es. Amo lo sport)", text: $bio)
                    CustomTextField(placeholder: "Il tuo Motto", text: $motto)
                    
                    // --- FIX QUI SOTTO ---
                    // Età e Genere sulla stessa riga
                    HStack(spacing: 10) {
                        // Picker Genere
                        HStack(spacing: 5) {
                            Text("Genere:")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                                .lineLimit(1) // Impedisce a capo
                                .fixedSize()  // Forza la larghezza del testo
                            
                            Picker("", selection: $gender) {
                                Text("Uomo").tag("Man")
                                Text("Donna").tag("Woman")
                            }
                            .accentColor(.appGreen)
                            .labelsHidden()
                            .fixedSize() // *** FIX IMPORTANTE: Impedisce che "Uomo" vada a capo ***
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(30)
                        
                        Spacer()
                        
                        // Stepper Età
                        HStack(spacing: 5) {
                            Text("Età: \(age)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .fixedSize()
                            
                            Stepper("", value: $age, in: 18...99)
                                .labelsHidden()
                                .scaleEffect(0.9) // Rimpicciolisce leggermente lo stepper per farlo entrare meglio
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(30)
                    }
                    .padding(.horizontal, 10) // Padding esterno ridotto per dare più spazio
                }
                
                Spacer()
                
                NavigationLink(destination: RegistrationStep3(isLoggedIn: $isLoggedIn)) {
                    Text("Continua")
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
        }
        .navigationBarHidden(true)
    }
}

// --- STEP 3: SPORT ---
struct RegistrationStep3: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedSports: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    
    let sports = [("Nuoto", "figure.pool.swim"), ("Trekking", "figure.hiking"), ("Palestra", "dumbbell.fill"), ("Bici", "bicycle"), ("Tennis", "tennis.racket"), ("Volley", "figure.volleyball")]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        ZStack {
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            VStack(spacing: 25) {
                ZStack {
                    HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen) }; Spacer() }
                    VStack {
                        Text("Step 3/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                        Text("I tuoi Sport").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                    }
                }.padding(.top, 60)
                
                ScrollView {
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
                }
                
                Spacer()
                
                NavigationLink(destination: RegistrationStep4(isLoggedIn: $isLoggedIn)) {
                    Text("Continua")
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
        }
        .navigationBarHidden(true)
    }
}

// --- STEP 4: PREFERENZE & FINE ---
struct RegistrationStep4: View {
    @Binding var isLoggedIn: Bool
    @State private var sharePos = true
    @State private var notif = true
    @State private var dist = 10.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Image("app_foto").resizable().scaledToFill().edgesIgnoringSafeArea(.all).overlay(Color.white.opacity(0.92))
            
            VStack(spacing: 25) {
                ZStack {
                    HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.appGreen) }; Spacer() }
                    VStack {
                        Text("Step 4/4").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.gray)
                        Text("Preferenze").font(.system(.title, design: .rounded).bold()).foregroundColor(.appGreen)
                    }
                }.padding(.top, 60)
                
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        Toggle("Condividi Posizione", isOn: $sharePos)
                        Toggle("Ricevi Notifiche", isOn: $notif)
                    }
                    .padding().background(Color.white).cornerRadius(20).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    
                    VStack {
                        Text("Distanza Max: \(Int(dist)) km").font(.caption).foregroundColor(.gray)
                        Slider(value: $dist, in: 1...100, step: 1).accentColor(.appGreen)
                    }
                    .padding().background(Color.white).cornerRadius(20)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // BOTTONE GO FINALE
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
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        RegistrationStep2(isLoggedIn: .constant(false))
    }
}
