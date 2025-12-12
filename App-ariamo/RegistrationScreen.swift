import SwiftUI

// --- 1. CREATE ACCOUNT - STEP 1 (Dati base) ---
struct CreateAccountStep1: View {
    @Binding var isLoggedIn: Bool
    @State private var name = ""
    @State private var surname = ""
    @State private var age = 18
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create an account")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                CustomTextField(placeholder: "Name", text: $name)
                CustomTextField(placeholder: "Surname", text: $surname)
                
                // Selettore Età
                HStack {
                    Text("Age (years)")
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $age) {
                        ForEach(18...100, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(5)
                    .background(Color.inputGray)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                CustomTextField(placeholder: "Enter your email", text: $email)
                CustomTextField(placeholder: "Create a Password", text: $password, isSecure: true)
                CustomTextField(placeholder: "Repeat Password", text: $password, isSecure: true)
                
                Spacer(minLength: 50)
                
                NavigationLink(destination: CreateAccountStep2(isLoggedIn: $isLoggedIn)) {
                    Text("Go!")
                        .bold()
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 100)
                        .background(Color.appMint.opacity(0.3))
                        .cornerRadius(25)
                }
            }
            .padding()
        }
    }
}

// --- 2. CREATE ACCOUNT - STEP 2 (Profilo) ---
struct CreateAccountStep2: View {
    @Binding var isLoggedIn: Bool
    @State private var bio = ""
    @State private var motto = ""
    @State private var gender = "Man"
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Complete your account")
                .font(.title2)
                .bold()
            
            Text("Upload a profile picture")
                .font(.caption)
                .foregroundColor(.gray)
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            // Gender Picker Custom (Componente riutilizzabile)
            HStack(spacing: 20) {
                GenderButton(title: "Man", isSelected: gender == "Man") { gender = "Man" }
                GenderButton(title: "Woman", isSelected: gender == "Woman") { gender = "Woman" }
            }
            
            CustomTextField(placeholder: "Tell us about yourself (Bio)", text: $bio)
            CustomTextField(placeholder: "Insert your motto here", text: $motto)
            
            Spacer()
            
            NavigationLink(destination: InterestsScreen(isLoggedIn: $isLoggedIn)) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 100)
                    .background(Color.appMint.opacity(0.3))
                    .cornerRadius(25)
            }
            .padding(.bottom, 30)
        }
    }
}

// --- 3. SELEZIONE INTERESSI (Griglia Sport) ---
struct InterestsScreen: View {
    @Binding var isLoggedIn: Bool
    
    let sports = [
        ("Swimming", "figure.pool.swim"),
        ("Hiking", "figure.hiking"),
        ("Gym", "dumbbell.fill"),
        ("Cycle", "bicycle"),
        ("Tennis", "tennis.racket"),
        ("Volleyball", "figure.volleyball")
    ]
    
    @State private var selectedSports: Set<String> = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack {
            Text("Selected a sport")
                .font(.title2)
                .bold()
                .padding()
            
            Text("Select your favorite hobby")
                .font(.caption)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(sports, id: \.0) { sport in
                    Button(action: {
                        if selectedSports.contains(sport.0) {
                            selectedSports.remove(sport.0)
                        } else {
                            selectedSports.insert(sport.0)
                        }
                    }) {
                        SportInterestCard(name: sport.0, icon: sport.1, isSelected: selectedSports.contains(sport.0))
                    }
                }
            }
            .padding()
            
            Spacer()
            
            NavigationLink(destination: PreferencesScreen(isLoggedIn: $isLoggedIn)) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 100)
                    .background(Color.appMint.opacity(0.3))
                    .cornerRadius(25)
            }
            .padding(.bottom, 30)
        }
    }
}

// Sottocomponente locale per Card Sport
struct SportInterestCard: View {
    let name: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(isSelected ? Color.appMint : Color.gray.opacity(0.3))
                .frame(height: 100)
                .cornerRadius(15)
                
            VStack(alignment: .leading) {
                Image(systemName: icon)
                    .font(.title)
                    .padding(5)
                Text(name)
                    .font(.headline)
                    .padding(5)
            }
            .foregroundColor(.white)
        }
    }
}

// --- 4. PREFERENZE (Running toggle e slider) ---
struct PreferencesScreen: View {
    @Binding var isLoggedIn: Bool
    @State private var locationToggle = true
    @State private var notificationToggle = true
    @State private var distance: Double = 5.0
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Text("Running")
                .font(.title)
                .bold()
            
            Text("Pick your running preferences")
                .foregroundColor(.gray)
            
            VStack(spacing: 20) {
                Toggle("Share your live location", isOn: $locationToggle)
                    .padding()
                    .background(Color.inputGray)
                    .cornerRadius(15)
                
                Toggle("Do you want to receive notification?", isOn: $notificationToggle)
                    .padding()
                    .background(Color.inputGray)
                    .cornerRadius(15)
                
                VStack(alignment: .leading) {
                    Text("Max. distance for events")
                    Slider(value: $distance, in: 0...50, step: 1)
                    Text("\(Int(distance)) km")
                        .font(.headline)
                        .foregroundColor(.appMint)
                }
                .padding()
                .background(Color.inputGray)
                .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // FINE DEL FLUSSO: Impostiamo isLoggedIn a TRUE
            Button(action: {
                withAnimation {
                    isLoggedIn = true
                }
            }) {
                Text("Go!")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 150)
                    .background(Color.black)
                    .cornerRadius(25)
            }
            .padding(.bottom, 50)
        }
    }
}

// --- PREVIEWS ---
struct CreateAccountStep1_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateAccountStep1(isLoggedIn: .constant(false))
        }
    }
}

struct InterestsScreen_Previews: PreviewProvider {
    static var previews: some View {
        InterestsScreen(isLoggedIn: .constant(false))
    }
}
