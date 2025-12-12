import SwiftUI

// --- WIZARD CREAZIONE & RIEPILOGO ---

struct CreationWizardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var step = 1
    
    // Stato per contenere i dati che l'utente sta inserendo (DatiEvento da AppConstants)
    @State private var nuovoEvento = DatiEvento()
    
    var body: some View {
        VStack {
            // Header Navigazione
            HStack {
                if step > 1 && step < 4 {
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
            Group {
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

// Step 1: Quale attività?
struct Step1View: View {
    @Binding var dati: DatiEvento
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
                    dati.tipo = option
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

// Step 2: Quando?
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

// Step 3: Dove?
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
                    .background(dati.luogo.isEmpty ? Color.gray : Color.appGreen)
                    .cornerRadius(25)
            }
            .disabled(dati.luogo.isEmpty)
        }
    }
}

// STEP 4: Schermata di Dettaglio finale
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
        .transition(.scale)
    }
}
