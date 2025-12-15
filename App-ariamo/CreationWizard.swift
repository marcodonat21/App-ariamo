import SwiftUI

// --- CREATION WIZARD & SUMMARY --- // Translated Comment

struct CreationWizardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var step = 1
    
    // State to hold the data the user is entering (DatiEvento from AppConstants) // Translated Comment
    @State private var nuovoEvento = DatiEvento()
    
    var body: some View {
        VStack {
            // Navigation Header
            HStack { // Translated Comment
                if step > 1 && step < 4 {
                    Button(action: { withAnimation { step -= 1 } }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                Spacer()
                // The close button is always available // Translated Comment
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            Spacer()
            
            // Dynamic content based on the step // Translated Comment
            Group {
                if step == 1 {
                    Step1View(data: $nuovoEvento, nextAction: nextStep)
                } else if step == 2 {
                    Step2View(data: $nuovoEvento, nextAction: nextStep)
                } else if step == 3 {
                    Step3View(data: $nuovoEvento, nextAction: nextStep)
                } else {
                    // STEP 4: Final Summary // Translated Comment
                    EventSummaryView( // Translated View Name
                        event: nuovoEvento,
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

// Step 1: What activity? // Translated Comment
struct Step1View: View {
    @Binding var data: DatiEvento
    var nextAction: () -> Void
    let options = ["Sports", "Travel & Adventure", "Party", "Holiday"] // Translated Options
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 40))
                .foregroundColor(.appGreen)
            
            Text("Which activity\ndo you want to join?") // Translated
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.appGreen)
            
            ForEach(options, id: \.self) { option in
                Button(action: {
                    data.tipo = option
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

// Step 2: When? // Translated Comment
struct Step2View: View {
    @Binding var data: DatiEvento
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("When are you joining?") // Translated
                .font(.title2)
                .bold()
                .foregroundColor(.appGreen)
            
            DatePicker("", selection: $data.data, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            
            Button(action: nextAction) {
                Text("Next") // Translated
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.appGreen)
                    .cornerRadius(25)
            }
        }
    }
}

// Step 3: Where? // Translated Comment
struct Step3View: View {
    @Binding var data: DatiEvento
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Where are you joining?") // Translated
                .font(.title2)
                .bold()
                .foregroundColor(.appGreen)
            
            TextField("Enter location...", text: $data.luogo) // Translated Placeholder
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            Button(action: nextAction) {
                Text("Create Event") // Translated
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(data.luogo.isEmpty ? Color.gray : Color.appGreen)
                    .cornerRadius(25)
            }
            .disabled(data.luogo.isEmpty)
        }
    }
}

// STEP 4: Final Summary Screen // Translated Comment
struct EventSummaryView: View { // Translated View Name
    let event: DatiEvento
    var closeAction: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            
            // Success Icon
            Image(systemName: "checkmark.seal.fill") // Translated Comment
                .font(.system(size: 60))
                .foregroundColor(.appGreen)
                .padding(.bottom, 10)
            
            Text("Congratulations!\nYou've created an event!") // Translated
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
            
            Divider().padding(.horizontal)
            
            // Data Summary Card // Translated Comment
            VStack(alignment: .leading, spacing: 15) {
                Text("EVENT DETAILS") // Translated
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    Text(event.tipo)
                        .font(.title3)
                        .bold()
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    // Simple date formatting // Translated Comment
                    Text(event.data.formatted(date: .long, time: .shortened))
                        .font(.body)
                }
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.appGreen)
                        .frame(width: 30)
                    Text(event.luogo)
                        .font(.body)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer().frame(height: 20)
            
            Button(action: closeAction) {
                Text("Back to Home") // Translated
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
