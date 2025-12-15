import SwiftUI

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.presentationMode) var presentationMode
    
    // Osserviamo il manager per reagire ai cambiamenti di stato
    @ObservedObject var manager = ActivityManager.shared
    
    @State private var showSuccess = false
    
    // Calcoliamo dinamicamente se partecipiamo
    var isAlreadyJoined: Bool {
        manager.isJoined(activity: activity)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header Image
                ZStack(alignment: .topLeading) {
                    Image("app_foto")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .ignoresSafeArea()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(activity.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Image(systemName: activity.imageName)
                            .font(.largeTitle)
                            .foregroundColor(activity.color)
                    }
                    
                    Text(activity.description)
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Text("Naples, Italy")
                            .font(.subheadline)
                    }
                    
                    // STATUS INDICATOR (Se partecipi già)
                    if isAlreadyJoined {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appGreen)
                            Text("Status: ALREADY JOINED")
                                .font(.headline)
                                .foregroundColor(.appGreen)
                        }
                        .padding(.top, 5)
                    }
                    
                    Spacer()
                    
                    // DYNAMIC ACTION BUTTON
                    Button(action: {
                        if isAlreadyJoined {
                            // LOGICA LEAVE (CANCELLA PARTECIPAZIONE)
                            manager.leave(activity: activity)
                            presentationMode.wrappedValue.dismiss() // Torna indietro dopo aver cancellato
                        } else {
                            // LOGICA JOIN (PARTECIPA)
                            manager.join(activity: activity)
                            withAnimation { showSuccess = true }
                        }
                    }) {
                        Text(isAlreadyJoined ? "Leave Activity" : "Join Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAlreadyJoined ? Color.red : Color.appGreen) // ROSSO se joined, VERDE se new
                            .cornerRadius(25)
                            .shadow(color: (isAlreadyJoined ? Color.red : Color.appGreen).opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 30)
                }
                .padding(25)
                .background(Color.white)
                .cornerRadius(30)
                .offset(y: -40)
            }
            
            // SUCCESS OVERLAY (Solo quando ti unisci)
            if showSuccess {
                SuccessOverlay(onClose: {
                    showSuccess = false
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
    }
}

// Success Overlay (Invariato)
struct SuccessOverlay: View {
    var onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.appGreen).padding(.top, 20)
                Text("Bravo!").font(.largeTitle).fontWeight(.heavy).foregroundColor(.black)
                Text("You have successfully joined\nthis event.").font(.body).multilineTextAlignment(.center).foregroundColor(.gray)
                Divider()
                Button(action: onClose) {
                    Text("OK, Great!").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.appGreen).cornerRadius(20)
                }.padding(.horizontal).padding(.bottom, 20)
            }.frame(width: 300).background(Color.white).cornerRadius(25).shadow(radius: 20).transition(.scale)
        }
    }
}
