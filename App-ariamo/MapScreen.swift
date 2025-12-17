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
    @StateObject var locationManager = LocationManager.shared
    
    @StateObject private var filters = FilterSettings()
    @State private var showFilters = false
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    
    // Calcolo dei Pin da mostrare
    var filteredLocations: [MapLocation] {
        let allActivities = manager.allActivities
        let uniqueActivities = Array(Dictionary(grouping: allActivities, by: { $0.id }).compactMap { $0.value.first })
        let filteredActs = filters.apply(to: uniqueActivities)
        
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
        let found = manager.allActivities.first(where: { $0.id == current.id })
        
        if let act = found {
            return MapLocation(id: act.id, name: act.title, coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude), imageName: act.imageName, description: act.description, imageData: act.imageData)
        }
        return nil
    }
    
    // Costruzione della lista annotazioni
    var annotationItems: [MapLocation] {
        var items = filteredLocations
        if let userLoc = locationManager.userLocation {
            items.append(MapLocation(id: UUID(), name: "ME", coordinate: userLoc.coordinate, imageName: "person.fill", description: "", imageData: nil))
        }
        return items
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
            
            // MAPPA
            Map(coordinateRegion: $locationManager.region, annotationItems: annotationItems) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    annotationView(for: location)
                }
            }
            .ignoresSafeArea(.all)
            .onTapGesture {
                hideKeyboard()
                withAnimation { selectedLocation = nil }
            }
            
            // --- AVVISO GPS NEGATO ---
            if locationManager.permissionDenied {
                VStack {
                    HStack {
                        Image(systemName: "location.slash.fill").foregroundColor(.white)
                        Text("GPS disabled. Enable in Settings.").font(.caption).bold().foregroundColor(.white)
                        Spacer()
                        Button("Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .font(.caption).bold().foregroundColor(.appGreen).padding(.horizontal, 10).padding(.vertical, 5).background(Color.white).cornerRadius(10)
                    }
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.top, 110) // Avviso in basso per non coprire i tasti
                    Spacer()
                }
            }
            
            // --- UI SUPERIORE (FILTRI - GPS CENTRALE - SPAZIO VUOTO PER IL +) ---
            VStack {
                HStack {
                    // 1. SINISTRA: BOTTONE FILTRI
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
                    
                    Spacer()
                    
                    // 2. CENTRO: BOTTONE GPS (Visibile solo se permesso OK)
                    if !locationManager.permissionDenied {
                        Button(action: { locationManager.centerMapOnUser() }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                // *** MODIFICA COLORE: Ora è BLU come il pallino ***
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // 3. DESTRA: SPAZIO VUOTO (Qui sopra c'è il tuo bottone +)
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(14)
                }
                .padding(.horizontal, 20)
                // *** MODIFICA POSIZIONE: Ridotto a 40 per alzarli e allinearli al + ***
                .padding(.top, 40)
                
                Spacer()
            }
            // -----------------------------------
            
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
    
    // --- HELPER VIEW BUILDER ---
    @ViewBuilder
    func annotationView(for location: MapLocation) -> some View {
        if location.name == "ME" {
            UserLocationPin(filters: filters, region: locationManager.region)
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
            let found = manager.allActivities.first(where: { $0.id == loc.id })
            
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
            ZStack {
                Circle().fill(Color.white).frame(width: 24, height: 24).shadow(radius: 4)
                Circle().fill(Color.blue).frame(width: 18, height: 18)
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }
        }
    }
}

// 4. PIN ATTIVITÀ
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
                        .fill(isJoined ? Color.appGreen : (isCreatedByMe ? Color.blue : Color.red))
                        .frame(width: 40, height: 40)
                        .shadow(radius: 4)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    
                    Image(systemName: "mappin")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    if isCreatedByMe {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption).padding(3).background(Circle().fill(Color.white)).offset(x: 14, y: -14)
                    }
                    if isFavorite {
                        Image(systemName: "heart.fill").foregroundColor(.red).font(.caption).padding(3).background(Circle().fill(Color.white)).offset(x: -14, y: -14)
                    }
                }
                
                Text(location.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .scaleEffect(selectedLocation?.id == location.id ? 1.3 : 1.0)
            .animation(.spring(), value: selectedLocation?.id)
        }
    }
}

// 5. CARD MAPPA
struct MapLocationCard: View {
    let location: MapLocation
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 15) {
                if let data = location.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle()).overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
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
                Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)).padding(.trailing, 20)
            }
            .padding(20)
            .background(Color.themeCard)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
            .onTapGesture(perform: onTap)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.4)).padding(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
