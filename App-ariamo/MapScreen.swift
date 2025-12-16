import SwiftUI
import MapKit

// 1. STRUTTURA DATI PER LA MAPPA
struct MapLocation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let description: String
    let imageData: Data?
    
    static func == (lhs: MapLocation, rhs: MapLocation) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// 2. SCHERMATA MAPPA PRINCIPALE
struct MapScreen: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    
    @ObservedObject var manager = ActivityManager.shared
    @ObservedObject var userManager = UserManager.shared
    
    @StateObject private var filters = FilterSettings()
    @State private var showFilters = false
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Calcolo dei Pin da mostrare
    var filteredLocations: [MapLocation] {
        let allActivities = Array(Set(
            ActivityManager.defaultActivities +
            manager.createdActivities +
            manager.joinedActivities
        ))
        
        let filteredActs = filters.apply(to: allActivities)
        
        var locations = filteredActs.map { act in
            MapLocation(
                id: act.id,
                name: act.title,
                coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude),
                imageName: act.imageName,
                description: act.description,
                imageData: act.imageData
            )
        }
        
        if !searchText.isEmpty {
            locations = locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return locations
    }
    
    // Gestione selezione "Viva"
    var liveSelectedLocation: MapLocation? {
        guard let current = selectedLocation else { return nil }
        
        let found = manager.createdActivities.first(where: { $0.id == current.id })
            ?? manager.joinedActivities.first(where: { $0.id == current.id })
            ?? ActivityManager.defaultActivities.first(where: { $0.id == current.id })
        
        if let act = found {
            return MapLocation(id: act.id, name: act.title, coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude), imageName: act.imageName, description: act.description, imageData: act.imageData)
        }
        return nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Sfondo cliccabile per deselezionare
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                    withAnimation { selectedLocation = nil }
                }
            
            // MAPPA (Logica estratta per aiutare il compilatore)
            Map(coordinateRegion: $region, annotationItems: filteredLocations + [
                MapLocation(id: UUID(), name: "ME", coordinate: ActivityManager.userLocation.coordinate, imageName: "person.fill", description: "", imageData: nil)
            ]) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    annotationView(for: location)
                }
            }
            .ignoresSafeArea(.all)
            .onTapGesture {
                hideKeyboard()
                withAnimation { selectedLocation = nil }
            }
            
            // BOTTONE FILTRI
            VStack {
                HStack {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appGreen)
                            .padding(14)
                            .background(Color.themeCard)
                            .clipShape(Circle())
                            .shadow(color: .appGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                    Spacer()
                }
                Spacer()
            }
            
            // CARD DETTAGLIO
            if let liveLoc = liveSelectedLocation {
                MapLocationCard(location: liveLoc) {
                    navigateToDetail = true
                } onClose: {
                    withAnimation { selectedLocation = nil }
                }
                .zIndex(2)
            }
        }
        .background(
            NavigationLink(destination: destinationView, isActive: $navigateToDetail) { EmptyView() }
        )
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) {
            FilterSheetView(filters: filters, showSortOptions: false)
        }
    }
    
    // --- HELPER VIEW BUILDER (Risolve l'errore del compilatore) ---
    @ViewBuilder
    func annotationView(for location: MapLocation) -> some View {
        if location.name == "ME" {
            UserLocationPin(filters: filters, region: region)
        } else {
            MapPinView(location: location, manager: manager, selectedLocation: selectedLocation) {
                withAnimation(.spring()) {
                    hideKeyboard()
                    isSearchActive = false
                    selectedLocation = location
                }
            }
        }
    }
    
    var destinationView: some View {
        if let loc = liveSelectedLocation {
            let found = manager.createdActivities.first(where: { $0.id == loc.id })
                ?? manager.joinedActivities.first(where: { $0.id == loc.id })
                ?? ActivityManager.defaultActivities.first(where: { $0.id == loc.id })
            
            if let act = found {
                return AnyView(ActivityDetailView(activity: act))
            }
        }
        return AnyView(EmptyView())
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 3. PIN UTENTE
struct UserLocationPin: View {
    @ObservedObject var filters: FilterSettings
    let region: MKCoordinateRegion
    
    var body: some View {
        ZStack {
            if filters.enableDistanceFilter {
                GeometryReader { geo in
                    let pixelRadius = (filters.maxDistanceKm / 111.0) * (UIScreen.main.bounds.height / region.span.latitudeDelta)
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.15))
                            .frame(width: pixelRadius * 2, height: pixelRadius * 2)
                        Circle().stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            .frame(width: pixelRadius * 2, height: pixelRadius * 2)
                    }
                    .position(x: 0, y: 0)
                }
                .frame(width: 0, height: 0)
            }
            Circle().fill(Color.white).frame(width: 20, height: 20).shadow(radius: 3)
            Circle().fill(Color.blue).frame(width: 14, height: 14)
        }
    }
}

// 4. PIN ATTIVITÀ (Mancava nel tuo file)
struct MapPinView: View {
    let location: MapLocation
    @ObservedObject var manager: ActivityManager
    let selectedLocation: MapLocation?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    let isJoined = manager.joinedActivities.contains(where: { $0.id == location.id })
                    let isCreatedByMe = manager.createdActivities.contains(where: { $0.id == location.id })
                    let isFavorite = manager.favoriteActivities.contains(location.id)
                    
                    Circle()
                        .fill(isJoined ? Color.appGreen : Color.red)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 4)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    
                    Image(systemName: "mappin")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    if isCreatedByMe {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .padding(3)
                            .background(Circle().fill(Color.white))
                            .offset(x: 14, y: -14)
                    }
                    
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(3)
                            .background(Circle().fill(Color.white))
                            .offset(x: -14, y: -14)
                    }
                }
                
                Text(location.name)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
            .scaleEffect(selectedLocation?.id == location.id ? 1.2 : 1.0)
            .animation(.spring(), value: selectedLocation?.id)
        }
    }
}

// 5. CARD MAPPA (Mancava nel tuo file)
struct MapLocationCard: View {
    let location: MapLocation
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 15) {
                if let data = location.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
                } else {
                    ZStack {
                        Circle().fill(Color.appGreen.opacity(0.15)).frame(width: 60, height: 60)
                        Image(systemName: location.imageName).font(.title).foregroundColor(.appGreen)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name).font(.headline).foregroundColor(.primary)
                    Text(location.description).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.trailing, 20)
            }
            .padding(20)
            .background(Color.themeCard)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
            .onTapGesture(perform: onTap)
            
            Button(action: onClose) {
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
