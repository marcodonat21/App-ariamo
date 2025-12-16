import SwiftUI

// --- LISTA PARTECIPANTI ---
struct ParticipantsListView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Dati simulati
    let participants: [UserProfile] = [
        UserProfile(name: "Marco", surname: "Donatore", age: 24, gender: "Man", bio: "Love football", motto: "Forza Napoli", image: "person.fill", email: "", password: "", interests: [], shareLocation: false, notifications: false),
        UserProfile(name: "Erika", surname: "Cortese", age: 22, gender: "Woman", bio: "Travel addict", motto: "Carpe Diem", image: "person.fill", email: "", password: "", interests: [], shareLocation: false, notifications: false),
        UserProfile(name: "Arianna", surname: "Trombaccia", age: 18, gender: "Man", bio: "Tech & Gym", motto: "Push limits", image: "person.fill", email: "", password: "", interests: [], shareLocation: false, notifications: false),
        UserManager.shared.currentUser
    ]
    
    var body: some View {
        // STESSA STRUTTURA DI CreatedActivitiesView
        VStack(spacing: 0) {
            
            // HEADER CUSTOM (Copiato dal tuo codice funzionante)
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appGreen)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer()
                Text("Participants").font(.headline).bold()
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding()
            .padding(.top, 40) // Questo è il padding che usavi nel file funzionante
            
            // LISTA
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    ForEach(participants) { user in
                        NavigationLink(destination: PublicProfileView(user: user)) {
                            ParticipantRow(user: user)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .background(Color(UIColor.systemGray6).ignoresSafeArea()) // Sfondo grigio come le attività
    }
}

// --- RIGA PARTECIPANTE (Stile ActivityRow del tuo codice) ---
struct ParticipantRow: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50) // Dimensioni come ActivityRow
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
            } else {
                ZStack {
                    Circle().fill(Color.appGreen.opacity(0.1)) // Sfondo verde chiaro come ActivityRow
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundColor(.appGreen)
                }
                .frame(width: 50, height: 50)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(user.name) \(user.surname)")
                    .font(.headline)
                    .foregroundColor(.black) // Come il tuo codice
                
                Text(user.motto.isEmpty ? "No motto" : user.motto)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white) // Sfondo bianco card
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// --- PROFILO PUBBLICO (Stesso layout) ---
struct PublicProfileView: View {
    let user: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            
            // HEADER
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appGreen)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer()
            }
            .padding()
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // Foto
                    if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .overlay(Circle().stroke(Color.appGreen, lineWidth: 3))
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                    }
                    
                    // Nome
                    VStack(spacing: 5) {
                        Text("\(user.name) \(user.surname)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.black)
                        
                        Text("\(user.age) years • \(user.gender)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Info Card
                    VStack(alignment: .leading, spacing: 20) {
                        if !user.bio.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("BIO").font(.caption).bold().foregroundColor(.appGreen)
                                Text(user.bio).font(.body).foregroundColor(.black)
                            }
                            Divider()
                        }
                        
                        if !user.motto.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MOTTO").font(.caption).bold().foregroundColor(.appGreen)
                                Text("\"\(user.motto)\"").font(.body).italic().foregroundColor(.black)
                            }
                        }
                    }
                    .padding(25)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding()
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}
