import SwiftUI

// --- LISTA PARTECIPANTI ---
struct ParticipantsListView: View {
    let activityID: UUID
    @ObservedObject var manager = ActivityManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var participants: [ParticipantDTO] {
        return manager.participantsCache[activityID] ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer(); Text("Participants (\(participants.count))").font(.headline).bold().foregroundColor(.black); Spacer(); Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 15).background(Color(UIColor.systemGray6).ignoresSafeArea())
                
                // Lista
                ScrollView(showsIndicators: false) {
                    if participants.isEmpty {
                        VStack(spacing: 20) { Spacer().frame(height: 100); Image(systemName: "person.3.fill").font(.system(size: 60)).foregroundColor(.gray.opacity(0.3)); Text("No participants yet.").font(.headline).foregroundColor(.gray) }.padding(.top, 50)
                    } else {
                        LazyVStack(spacing: 15) {
                            ForEach(participants) { participant in
                                NavigationLink(destination: PublicProfileView(participant: participant)) {
                                    ParticipantRow(participant: participant)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
        }
        .onAppear { Task { await manager.fetchParticipants(for: activityID) } }
    }
}

// --- RIGA PARTECIPANTE (FIX IMMAGINE) ---
struct ParticipantRow: View {
    let participant: ParticipantDTO
    
    var body: some View {
        HStack(spacing: 15) {
            // AVATAR: Se è un URL usa AsyncImage, altrimenti Icona
            ZStack {
                Circle().fill(Color.appGreen.opacity(0.1))
                
                if let imgStr = participant.user_image, imgStr.hasPrefix("http"), let url = URL(string: imgStr) {
                    // FOTO VERA (URL)
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.fill").resizable().scaledToFit().foregroundColor(.appGreen.opacity(0.5)).padding(10)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    // ICONA DI SISTEMA
                    Image(systemName: participant.user_image ?? "person.fill")
                        .resizable().scaledToFit().frame(width: 24).foregroundColor(.appGreen)
                }
            }
            .frame(width: 50, height: 50).clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.user_name).font(.headline).foregroundColor(.black)
                if let country = participant.user_country { Text(country).font(.caption).foregroundColor(.gray) }
            }
            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray.opacity(0.4))
        }
        .padding(16).background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// --- PROFILO PUBBLICO (FIX IMMAGINE) ---
struct PublicProfileView: View {
    let participant: ParticipantDTO
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: { presentationMode.wrappedValue.dismiss() }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2) }; Spacer() }.padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // FOTO GRANDE
                    ZStack {
                        Circle().fill(Color.appGreen.opacity(0.1)).frame(width: 120, height: 120)
                        
                        if let imgStr = participant.user_image, imgStr.hasPrefix("http"), let url = URL(string: imgStr) {
                            // FOTO VERA
                            AsyncImage(url: url) { phase in
                                if let image = phase.image { image.resizable().scaledToFill() }
                                else { Image(systemName: "person.fill").resizable().scaledToFit().foregroundColor(.appGreen.opacity(0.5)).padding(30) }
                            }
                            .frame(width: 120, height: 120).clipShape(Circle())
                        } else {
                            // ICONA
                            Image(systemName: participant.user_image ?? "person.fill").resizable().scaledToFit().frame(width: 50).foregroundColor(.appGreen)
                        }
                        
                        Circle().stroke(Color.appGreen, lineWidth: 3).frame(width: 120, height: 120)
                    }.padding(.top, 20)
                    
                    VStack(spacing: 8) { Text(participant.user_name).font(.title2).bold().foregroundColor(.black); HStack(spacing: 5) { if let age = participant.user_age { Text("\(age) years").font(.subheadline).foregroundColor(.gray) }; if participant.user_age != nil && participant.user_country != nil { Text("•").foregroundColor(.gray) }; if let country = participant.user_country { Text(country).font(.subheadline).foregroundColor(.gray) } } }
                    Divider().padding(.horizontal, 40)
                    VStack(alignment: .leading, spacing: 10) { Text("BIO").font(.caption).bold().foregroundColor(.appGreen).tracking(1); Text(participant.user_bio ?? "No bio available.").font(.body).foregroundColor(.black).lineSpacing(4) }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5).padding(.horizontal, 20)
                    Spacer()
                }.padding(.bottom, 50)
            }
        }.navigationBarHidden(true).background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
}

struct SocialViews_Previews: PreviewProvider { static var previews: some View { ParticipantsListView(activityID: UUID()) } }
