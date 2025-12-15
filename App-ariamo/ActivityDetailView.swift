import SwiftUI
import MapKit // Fondamentale per CLLocationCoordinate2D

struct ActivityDetailView: View {
    let location: MapLocation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Immagine
                Rectangle()
                    .fill(Color.appGreen.opacity(0.1))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: location.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .foregroundColor(.appGreen)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(location.name)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Label("Napoli, NA", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Label("Aperto ora", systemImage: "clock")
                            .foregroundColor(.green)
                    }
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    
                    Divider()
                    
                    Text("Informazioni")
                        .font(.title2)
                        .bold()
                    
                    Text(location.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(5)
                    
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.")
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 50)
                    
                    Button(action: {}) {
                        Text("Partecipa all'evento")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appGreen)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .padding(25)
                .background(Color.white)
                .cornerRadius(30)
                .offset(y: -30) // Effetto sovrapposizione
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

// --- PREVIEW CORRETTA ---
struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityDetailView(location: MapLocation(
            name: "Pizzeria Esempio",
            // FIX: Coordinate esplicite invece di .init()
            coordinate: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
            imageName: "fork.knife",
            description: "Descrizione di prova per la preview."
        ))
    }
}
