import SwiftUI

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

// Card Informazioni
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

struct InfoScreen_Previews: PreviewProvider {
    static var previews: some View {
        InfoScreen()
    }
}
