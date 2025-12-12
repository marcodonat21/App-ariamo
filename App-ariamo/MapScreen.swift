import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let description: String
}

struct MapScreen: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool // Riceviamo lo stato della ricerca
    
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let allLocations = [
        MapLocation(name: "Pizzeria da Michele", coordinate: CLLocationCoordinate2D(latitude: 40.8498, longitude: 14.2633), imageName: "fork.knife", description: "La pizza più famosa di Napoli."),
        MapLocation(name: "Stadio Maradona", coordinate: CLLocationCoordinate2D(latitude: 40.8279, longitude: 14.1930), imageName: "figure.soccer", description: "Il tempio del calcio."),
        MapLocation(name: "Lungomare", coordinate: CLLocationCoordinate2D(latitude: 40.8322, longitude: 14.2426), imageName: "sun.max.fill", description: "Passeggiata con vista Vesuvio.")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. MAPPA
            Map(coordinateRegion: $region, annotationItems: filteredLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        withAnimation(.spring()) {
                            // Quando clicco un PIN: Chiudo la ricerca e la tastiera
                            isSearchActive = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // Apro l'anteprima
                            selectedLocation = location
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(selectedLocation?.id == location.id ? Color.appGreen : Color.red)
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 4)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Image(systemName: "mappin").foregroundColor(.white).font(.headline)
                            }
                            
                            Text(location.name)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .shadow(color: .white.opacity(0.8), radius: 0, x: 1, y: 1)
                                .shadow(color: .white.opacity(0.8), radius: 0, x: -1, y: -1)
                                .shadow(color: .white.opacity(0.8), radius: 0, x: 1, y: -1)
                                .shadow(color: .white.opacity(0.8), radius: 0, x: -1, y: 1)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        }
                        .scaleEffect(selectedLocation?.id == location.id ? 1.2 : 1.0)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            // Tap sulla mappa vuota chiude l'anteprima
            .onTapGesture { withAnimation { selectedLocation = nil } }
            
            // Link Invisibile navigazione
            NavigationLink(isActive: $navigateToDetail) {
                if let loc = selectedLocation { ActivityDetailView(location: loc) }
            } label: { EmptyView() }

            // 2. ANTEPRIMA CARD
            if let location = selectedLocation {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .center, spacing: 15) {
                        ZStack {
                            Circle().fill(Color.appGreen.opacity(0.15)).frame(width: 60, height: 60)
                            Image(systemName: location.imageName)
                                .font(.title)
                                .foregroundColor(.appGreen)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name).font(.headline).foregroundColor(.black)
                            Text(location.description).font(.subheadline).foregroundColor(.gray).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)).padding(.trailing, 20)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
                    .onTapGesture { navigateToDetail = true }
                    
                    Button(action: { withAnimation { selectedLocation = nil } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.4))
                            .padding(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        
        // --- NUOVO: ASCOLTATORE ---
        // Se isSearchActive diventa TRUE (apri la ricerca), chiudi l'anteprima.
        .onChange(of: isSearchActive) { isActive in
            if isActive {
                withAnimation {
                    selectedLocation = nil
                }
            }
        }
    }
    
    var filteredLocations: [MapLocation] {
        if searchText.isEmpty { return allLocations }
        else { return allLocations.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
    }
}

struct MapScreen_Previews: PreviewProvider {
    static var previews: some View {
        MapScreen(searchText: .constant(""), isSearchActive: .constant(false))
    }
}
