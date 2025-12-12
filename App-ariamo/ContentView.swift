import SwiftUI
import MapKit

// --- 1. CONFIGURAZIONE COLORI E DATI ---
extension Color {
    static let appGreen = Color(red: 0.0, green: 0.6, blue: 0.5) // Un verde simile allo screenshot
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String // Uso nomi di sistema SF Symbols per semplicità
}

// --- 2. MAIN ENTRY POINT (TAB BAR) ---
struct ContentView: View {
    @State private var showCreationWizard = false

    var body: some View {
        TabView {
            // Tab 1: Mappa
            MapScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Tab 2: Lista Attività
            ActivityListScreen()
                .tabItem {
                    Label("Attività", systemImage: "list.bullet.rectangle.portrait.fill")
                }
            
            // Tab 3: Info
            InfoScreen()
                .tabItem {
                    Label("Info", systemImage: "person.fill")
                }
        }
        .accentColor(.appGreen) // Colore della selezione
        .overlay(
            // Bottone galleggiante per aprire il "Wizard" (Riga in alto dello screenshot)
            Button(action: { showCreationWizard = true }) {
                Image(systemName: "plus")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.appGreen)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(),
            alignment: .bottomTrailing // Posizionato in basso a destra sopra la tab bar
        )
        .sheet(isPresented: $showCreationWizard) {
            CreationWizardView()
        }
    }
}

// --- 3. SCHERMATE PRINCIPALI (RIGA IN BASSO) ---

// Schermata Mappa
struct MapScreen: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), // Roma
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region)
                .edgesIgnoringSafeArea(.top)
            
            // Barra di ricerca simulata
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Cerca attività...")
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "mic.fill")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding()
            .shadow(radius: 3)
        }
    }
}

// Schermata Lista Attività (Quella centrale in basso)
struct ActivityListScreen: View {
    let activities = [
        Activity(title: "Sport", imageName: "figure.run"),
        Activity(title: "Travel & Adventure", imageName: "airplane"),
        Activity(title: "Party", imageName: "music.note"),
        Activity(title: "Holiday", imageName: "sun.max.fill")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(activities) { activity in
                        ZStack(alignment: .bottomLeading) {
                            // Immagine di sfondo (simulata con rettangolo grigio)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 150)
                                .cornerRadius(15)
                                .overlay(
                                    Image(systemName: activity.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50)
                                        .foregroundColor(.white.opacity(0.5))
                                )
                            
                            // Testo sopra l'immagine
                            VStack(alignment: .leading) {
                                Text(activity.title)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Activity")
        }
    }
}

// Schermata Info (Quella a destra in basso)
struct InfoScreen: View {
    var body: some View {
        VStack(spacing: 0) {
            // Immagine Header
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(Text("Foto Evento").foregroundColor(.gray))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Information")
                        .font(.title)
                        .bold()
                        .foregroundColor(.appGreen)
                    
                    HStack {
                        InfoCard(icon: "calendar", title: "Data", value: "12 Dic")
                        InfoCard(icon: "clock", title: "Ora", value: "18:30")
                    }
                    
                    Button(action: {}) {
                        Text("Partecipa")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appGreen)
                            .cornerRadius(10)
                    }
                    
                    Text("Dettagli dell'evento qui sotto...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.appGreen)
                .cornerRadius(8)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// --- 4. WIZARD CREAZIONE & RIEPILOGO ---

// Modello dati temporaneo per l'evento in creazione
struct DatiEvento {
    var tipo: String = ""
    var data: Date = Date()
    var luogo: String = ""
}

struct CreationWizardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var step = 1
    
    // Stato per contenere i dati che l'utente sta inserendo
    @State private var nuovoEvento = DatiEvento()
    
    var body: some View {
        VStack {
            // Header Navigazione
            HStack {
                if step > 1 && step < 4 { // Nascondi "Indietro" all'ultimo step
                    Button(action: { withAnimation { step -= 1 } }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                Spacer()
                // Il tasto chiudi è sempre disponibile
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            Spacer()
            
            // Contenuto dinamico in base allo step
            if step == 1 {
                Step1View(dati: $nuovoEvento, nextAction: nextStep)
            } else if step == 2 {
                Step2View(dati: $nuovoEvento, nextAction: nextStep)
            } else if step == 3 {
                Step3View(dati: $nuovoEvento, nextAction: nextStep)
            } else {
                // STEP 4: Riepilogo Finale
                RiepilogoEventoView(
                    evento: nuovoEvento,
                    closeAction: { presentationMode.wrappedValue.dismiss() }
                )
            }
            
            Spacer()
        }
    }
    
    func nextStep() {
        withAnimation {
            step += 1
        }
    }
}

// Step 1: Quale attività? (Aggiornato per salvare i dati)
struct Step1View: View {
    @Binding var dati: DatiEvento // Binding per modificare i dati
    var nextAction: () -> Void
    let options = ["Sport", "Travel & Adventure", "Party", "Holiday"]
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 40))
                .foregroundColor(.appGreen)
            
            Text("Quale attività\nvuoi apparare?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.appGreen)
            
            ForEach(options, id: \.self) { option in
                Button(action: {
                    dati.tipo = option // Salva la scelta
                    nextAction()
                }) {
                    Text(option)
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(25)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// Step 2: Quando? (Aggiornato per salvare i dati)
struct Step2View: View {
    @Binding var dati: DatiEvento
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quando vi apparate?")
                .font(.title2)
                .bold()
                .foregroundColor(.appGreen)
            
            DatePicker("", selection: $dati.data, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            
            Button(action: nextAction) {
                Text("Avanti")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.appGreen)
                    .cornerRadius(25)
            }
        }
    }
}

// Step 3: Dove? (Aggiornato per salvare i dati)
struct Step3View: View {
    @Binding var dati: DatiEvento
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dove vi apparate?")
                .font(.title2)
                .bold()
                .foregroundColor(.appGreen)
            
            TextField("Inserisci luogo...", text: $dati.luogo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            Button(action: nextAction) {
                Text("Crea Evento")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(dati.luogo.isEmpty ? Color.gray : Color.appGreen) // Disabilita se vuoto
                    .cornerRadius(25)
            }
            .disabled(dati.luogo.isEmpty)
        }
    }
}

// NUOVO STEP 4: Schermata di Dettaglio finale
struct RiepilogoEventoView: View {
    let evento: DatiEvento
    var closeAction: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            
            // Icona Successo
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.appGreen)
                .padding(.bottom, 10)
            
            Text("Congratulazioni!\nHai apparato!")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
            
            Divider().padding(.horizontal)
            
            // Card Riepilogo Dati
            VStack(alignment: .leading, spacing: 15) {
                Text("DETTAGLI EVENTO")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    Text(evento.tipo)
                        .font(.title3)
                        .bold()
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    // Formattazione data semplice
                    Text(evento.data.formatted(date: .long, time: .shortened))
                        .font(.body)
                }
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    Text(evento.luogo)
                        .font(.body)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer().frame(height: 20)
            
            Button(action: closeAction) {
                Text("Torna alla Home")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appGreen)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
        .transition(.scale) // Animazione di entrata
    }
}
