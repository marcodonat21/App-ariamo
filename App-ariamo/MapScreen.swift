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
    @Binding var isSearchActive: Bool // Receive the search state // Translated Comment
    
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let allLocations = [
        MapLocation(name: "Da Michele Pizzeria", coordinate: CLLocationCoordinate2D(latitude: 40.8498, longitude: 14.2633), imageName: "fork.knife", description: "Naples' most famous pizza."), // Translated
        MapLocation(name: "Maradona Stadium", coordinate: CLLocationCoordinate2D(latitude: 40.8279, longitude: 14.1930), imageName: "figure.soccer", description: "The temple of football."), // Translated
        MapLocation(name: "Waterfront", coordinate: CLLocationCoordinate2D(latitude: 40.8322, longitude: 14.2426), imageName: "sun.max.fill", description: "Walk with a view of Vesuvius.") // Translated
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. MAP
            Map(coordinateRegion: $region, annotationItems: filteredLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        withAnimation(.spring()) {
                            // When I click a PIN: Close search and keyboard // Translated Comment
                            isSearchActive = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // Open the preview
                            selectedLocation = location // Translated Comment
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
            // Tap on empty map closes the preview // Translated Comment
            .onTapGesture { withAnimation { selectedLocation = nil } }
            
            // Invisible navigation Link // Translated Comment
            NavigationLink(isActive: $navigateToDetail) {
                if let loc = selectedLocation { ActivityDetailView(location: loc) }
            } label: { EmptyView() }

            // 2. PREVIEW CARD
            if let location = selectedLocation { // Translated Comment
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
        
        // --- NEW: LISTENER --- // Translated Comment
        // If isSearchActive becomes TRUE (open search), close the preview. // Translated Comment
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
