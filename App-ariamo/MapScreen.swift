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
    @Binding var isSearchActive: Bool
    
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let allLocations = [
        MapLocation(name: "Da Michele Pizzeria", coordinate: CLLocationCoordinate2D(latitude: 40.8498, longitude: 14.2633), imageName: "fork.knife", description: "Naples' most famous pizza."),
        MapLocation(name: "Maradona Stadium", coordinate: CLLocationCoordinate2D(latitude: 40.8279, longitude: 14.1930), imageName: "figure.soccer", description: "The temple of football."),
        MapLocation(name: "Waterfront", coordinate: CLLocationCoordinate2D(latitude: 40.8322, longitude: 14.2426), imageName: "sun.max.fill", description: "Walk with a view of Vesuvius.")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. MAP LAYER (Sfondo)
            // Usa GeometryReader o ZStack standard ignorando safe area per la mappa
            Map(coordinateRegion: $region, annotationItems: filteredLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        withAnimation(.spring()) {
                            endEditing() // Chiudi tastiera se aperta
                            isSearchActive = false
                            selectedLocation = location
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(selectedLocation?.id == location.id ? Color.appGreen : Color.red).frame(width: 40, height: 40).shadow(radius: 4).overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Image(systemName: "mappin").foregroundColor(.white).font(.headline)
                            }
                            Text(location.name).font(.caption).bold().foregroundColor(.black).padding(.horizontal, 4).background(Color.white.opacity(0.7)).cornerRadius(4)
                        }
                        .scaleEffect(selectedLocation?.id == location.id ? 1.2 : 1.0)
                    }
                }
            }
            .ignoresSafeArea(.all) // La mappa copre tutto
            .onTapGesture {
                // TAP SULLA MAPPA: Chiudi tutto
                withAnimation {
                    selectedLocation = nil
                    endEditing() // CHIUDE LA TASTIERA
                }
            }
            
            // 2. SEARCH BAR LAYER (Sopra la mappa)
            // NON usiamo .ignoresSafeArea(.keyboard) qui, così viene spinto su!
            VStack {
                Spacer() // Spinge la barra in basso
                
                if isSearchActive {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                        TextField("Search...", text: $searchText)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.7)) }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6)) // Sfondo scuro per contrasto
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 25)
                    .padding(.bottom, 10) // Un po' di margine dal bordo (o tastiera)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // Importante: Questo VStack rispetterà la tastiera e salirà
            
            // 3. NAVIGATION LINK INVISIBILE
            NavigationLink(isActive: $navigateToDetail) {
                if let loc = selectedLocation {
                    // CONVERSIONE: Da MapLocation a Activity per la view dettagliata
                    let activityFromMap = Activity(
                        title: loc.name,
                        imageName: loc.imageName,
                        color: .appGreen, // Default color
                        description: loc.description
                    )
                    ActivityDetailView(activity: activityFromMap)
                }
            } label: { EmptyView() }

            // 4. PREVIEW CARD
            if let location = selectedLocation {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .center, spacing: 15) {
                        ZStack {
                            Circle().fill(Color.appGreen.opacity(0.15)).frame(width: 60, height: 60)
                            Image(systemName: location.imageName).font(.title).foregroundColor(.appGreen)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name).font(.headline).foregroundColor(.black)
                            Text(location.description).font(.subheadline).foregroundColor(.gray).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)).padding(.trailing, 20)
                    }
                    .padding(20).background(Color.white).cornerRadius(25).shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
                    .onTapGesture { navigateToDetail = true }
                    
                    Button(action: { withAnimation { selectedLocation = nil } }) {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.4)).padding(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onChange(of: isSearchActive) { isActive in if isActive { withAnimation { selectedLocation = nil } } }
    }
    
    var filteredLocations: [MapLocation] {
        if searchText.isEmpty { return allLocations }
        else { return allLocations.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
    }
}
