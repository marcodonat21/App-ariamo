import SwiftUI
import MapKit

struct MapScreen: View {
    // Coordinate aggiornate per Napoli
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681), // Napoli
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

struct MapScreen_Previews: PreviewProvider {
    static var previews: some View {
        MapScreen()
    }
}
