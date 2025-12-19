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

// --- STRUTTURA PER I CLUSTER ---
struct ClusterAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let locations: [MapLocation]
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
    
    // Callback per richiedere il login quando necessario
    var onLoginRequest: ((AuthContext) -> Void)?
    
    // Callback per mostrare creation wizard
    var onCreateActivity: (() -> Void)?
    
    // Stato login
    var isLoggedIn: Bool
    
    // Funzione per approssimare coordinate (offset casuale entro 1km per guest)
    func approximateCoordinate(original: CLLocationCoordinate2D, activityId: UUID) -> CLLocationCoordinate2D {
        guard !isLoggedIn else { return original }
        
        // Usa l'ID dell'attività come seed per avere offset consistente
        let seed = Double(activityId.hashValue % 1000) / 1000.0
        
        // Offset casuale entro ~1km (0.009 gradi ≈ 1km)
        let maxOffset = 0.001
        let latOffset = (seed - 0.5) * 2 * maxOffset
        let lonOffset = ((Double((activityId.hashValue / 1000) % 1000) / 1000.0) - 0.5) * 2 * maxOffset
        
        return CLLocationCoordinate2D(
            latitude: original.latitude + latOffset,
            longitude: original.longitude + lonOffset
        )
    }
    
    // Calcolo dei Pin da mostrare
    var filteredLocations: [MapLocation] {
        let allActivities = manager.allActivities
        let uniqueActivities = Array(Dictionary(grouping: allActivities, by: { $0.id }).compactMap { $0.value.first })
        let filteredActs = filters.apply(to: uniqueActivities)
        
        var locations = filteredActs.map { act in
            // Coordinate approssimate per guest, precise per logged
            let coord = approximateCoordinate(
                original: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude),
                activityId: act.id
            )
            
            return MapLocation(
                id: act.id,
                name: act.title,
                coordinate: coord,
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
    
    // --- LOGICA DI CLUSTERING MENO AGGRESSIVO ---
    var clusteredAnnotations: [ClusterAnnotation] {
        // Calcolo distanza in base allo zoom
        let zoomLevel = locationManager.region.span.latitudeDelta
        
        // Se lo zoom è stretto (< 0.05), non fare clustering
        // *** MODIFICATO: era 0.01, ora 0.05 per clustering più lasco ***
        if zoomLevel < 0.05 {
            return []
        }
        
        // Distanza di raggruppamento in base allo zoom (più zoom = meno clustering)
        // *** MODIFICATO: era 0.3, ora 0.5 per cluster più grandi e meno frequenti ***
        let clusterDistance = max(zoomLevel * 0.5, 0.01)
        
        var clusters: [ClusterAnnotation] = []
        var processedLocations: Set<UUID> = []
        
        for location in filteredLocations {
            if processedLocations.contains(location.id) { continue }
            
            // Trova tutte le location vicine
            var nearbyLocations = [location]
            processedLocations.insert(location.id)
            
            for otherLocation in filteredLocations {
                if processedLocations.contains(otherLocation.id) { continue }
                
                let distance = sqrt(
                    pow(location.coordinate.latitude - otherLocation.coordinate.latitude, 2) +
                    pow(location.coordinate.longitude - otherLocation.coordinate.longitude, 2)
                )
                
                if distance < clusterDistance {
                    nearbyLocations.append(otherLocation)
                    processedLocations.insert(otherLocation.id)
                }
            }
            
            // Crea cluster solo se ci sono 2+ location
            if nearbyLocations.count >= 2 {
                let avgLat = nearbyLocations.map { $0.coordinate.latitude }.reduce(0, +) / Double(nearbyLocations.count)
                let avgLon = nearbyLocations.map { $0.coordinate.longitude }.reduce(0, +) / Double(nearbyLocations.count)
                
                clusters.append(ClusterAnnotation(
                    coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                    count: nearbyLocations.count,
                    locations: nearbyLocations
                ))
            }
        }
        
        return clusters
    }
    
    // Location non raggruppate (singole)
    var individualLocations: [MapLocation] {
        let zoomLevel = locationManager.region.span.latitudeDelta
        
        // Se lo zoom è stretto, mostra tutte le location individuali
        // *** MODIFICATO: era 0.01, ora 0.05 ***
        if zoomLevel < 0.05 {
            return filteredLocations
        }
        
        // *** MODIFICATO: era 0.3, ora 0.5 ***
        let clusterDistance = max(zoomLevel * 0.5, 0.01)
        
        var processed: Set<UUID> = []
        var individuals: [MapLocation] = []
        
        for location in filteredLocations {
            if processed.contains(location.id) { continue }
            
            var hasNearby = false
            for otherLocation in filteredLocations {
                if location.id == otherLocation.id { continue }
                if processed.contains(otherLocation.id) { continue }
                
                let distance = sqrt(
                    pow(location.coordinate.latitude - otherLocation.coordinate.latitude, 2) +
                    pow(location.coordinate.longitude - otherLocation.coordinate.longitude, 2)
                )
                
                if distance < clusterDistance {
                    hasNearby = true
                    processed.insert(location.id)
                    processed.insert(otherLocation.id)
                    break
                }
            }
            
            if !hasNearby {
                individuals.append(location)
                processed.insert(location.id)
            }
        }
        
        return individuals
    }
    
    var liveSelectedLocation: MapLocation? {
        guard let current = selectedLocation else { return nil }
        let found = manager.allActivities.first(where: { $0.id == current.id })
        
        if let act = found {
            return MapLocation(id: act.id, name: act.title, coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude), imageName: act.imageName, description: act.description, imageData: act.imageData)
        }
        return nil
    }
    
    var annotationItems: [MapLocation] {
        var items = individualLocations
        if let userLoc = locationManager.userLocation {
            items.append(MapLocation(id: UUID(), name: "ME", coordinate: userLoc.coordinate, imageName: "person.fill", description: "", imageData: nil))
        }
        return items
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // MAPPA
            Map(coordinateRegion: $locationManager.region, annotationItems: annotationItems) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    annotationView(for: location)
                }
            }
            .overlay(
                // OVERLAY PER I CLUSTER
                ForEach(clusteredAnnotations) { cluster in
                    GeometryReader { geometry in
                        let screenPoint = coordinateToScreen(cluster.coordinate, in: geometry)
                        
                        ClusterPinView(cluster: cluster, onTap: {
                            // Zoom sulla prima location del cluster
                            if let firstLocation = cluster.locations.first {
                                withAnimation {
                                    locationManager.region = MKCoordinateRegion(
                                        center: cluster.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                }
                            }
                        })
                        .position(x: screenPoint.x, y: screenPoint.y)
                    }
                }
            )
            .ignoresSafeArea(.all)
            .onTapGesture {
                hideKeyboard()
                withAnimation { selectedLocation = nil }
            }
            
            // --- AVVISO GPS NEGATO (Solo se realmente negato) ---
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
                    .padding(.top, 110)
                    Spacer()
                }
            }
            
            // --- BOTTONI VERTICALI (in basso a destra, sopra search) ---
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // BOTTONE FILTRI
                        if !isSearchActive {
                            Button(action: { showFilters = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appGreen)
                                    .padding(14)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        // BOTTONE + (CREATE)
                        if !isSearchActive {
                            Button(action: {
                                if isLoggedIn {
                                    onCreateActivity?()
                                } else {
                                    onLoginRequest?(.createActivity)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(Color.appGreen)
                                    .clipShape(Circle())
                                    .shadow(color: .appGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        // BOTTONE GPS
                        if !isSearchActive {
                            if !locationManager.permissionDenied {
                                Button(action: { locationManager.centerMapOnUser() }) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(14)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                    }.padding(.bottom, 90)
                    .padding(.trailing, 25)
                }
            }
            
            // --- CARD DETTAGLIO (se pin selezionato) ---
            if let location = selectedLocation {
                MapLocationCard(
                    location: location,
                    onTap: { navigateToDetail = true },
                    onClose: { withAnimation { selectedLocation = nil } }
                )
            }
            
            // --- NAVIGATION LINK INVISIBILE ---
            NavigationLink(
                destination: destinationView,
                isActive: $navigateToDetail,
                label: { EmptyView() }
            )
            .hidden()
        }
        .sheet(isPresented: $showFilters) {
            FilterSheetView(filters: filters, showSortOptions: false)
        }
    }
    
    @ViewBuilder
    func annotationView(for location: MapLocation) -> some View {
        if location.name == "ME" {
            UserLocationPin(filters: filters, region: locationManager.region)
        } else {
            MapPinView(
                location: location,
                manager: manager,
                selectedLocation: selectedLocation,
                onTap: {
                    withAnimation(.spring()) {
                        hideKeyboard()
                        isSearchActive = false
                        selectedLocation = location
                    }
                },
                isLoggedIn: isLoggedIn
            )
        }
    }
    
    // Funzione per convertire coordinate geografiche in posizione sullo schermo
    func coordinateToScreen(_ coordinate: CLLocationCoordinate2D, in geometry: GeometryProxy) -> CGPoint {
        let region = locationManager.region
        
        let x = (coordinate.longitude - (region.center.longitude - region.span.longitudeDelta / 2)) /
                region.span.longitudeDelta * geometry.size.width
        
        let y = ((region.center.latitude + region.span.latitudeDelta / 2) - coordinate.latitude) /
                region.span.latitudeDelta * geometry.size.height
        
        return CGPoint(x: x, y: y)
    }
    
    var destinationView: some View {
        if let loc = liveSelectedLocation {
            let found = manager.allActivities.first(where: { $0.id == loc.id })
            if let act = found {
                return AnyView(ActivityDetailView(activity: act, onLoginRequest: onLoginRequest))
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
                let pixelRadius = (filters.maxDistanceKm / 111.0) * (UIScreen.main.bounds.height / region.span.latitudeDelta)
                Circle().fill(Color.blue.opacity(0.15))
                    .frame(width: pixelRadius * 2, height: pixelRadius * 2)
                Circle().stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    .frame(width: pixelRadius * 2, height: pixelRadius * 2)
            }
            ZStack {
                Circle().fill(Color.white).frame(width: 24, height: 24).shadow(radius: 4)
                Circle().fill(Color.blue).frame(width: 18, height: 18)
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }
        }
    }
}

// --- VIEW PER I CLUSTER ---
struct ClusterPinView: View {
    let cluster: ClusterAnnotation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 4)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                
                Text("\(cluster.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 4. PIN ATTIVITÀ
struct MapPinView: View {
    let location: MapLocation
    @ObservedObject var manager = ActivityManager.shared
    let selectedLocation: MapLocation?
    let onTap: () -> Void
    var isLoggedIn: Bool = true  // Default logged
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Cerchio blu sfocato per guest (stile Airbnb)
                // *** FIX: Aggiungiamo .allowsHitTesting(false) per evitare che catturi i tap ***
                if !isLoggedIn {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 8)
                        .allowsHitTesting(false) // <--- FIX IMPORTANTE
                }
                
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
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .scaleEffect(selectedLocation?.id == location.id ? 1.3 : 1.0)
                .animation(.spring(), value: selectedLocation?.id)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
            .background(Color.white)
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

// --- PREVIEW ---
struct MapScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview per Utente Loggato
            NavigationView {
                MapScreen(
                    searchText: .constant(""),
                    isSearchActive: .constant(false),
                    isLoggedIn: true
                )
            }
            .previewDisplayName("Loggato")

            // Preview per Ospite (Guest)
            NavigationView {
                MapScreen(
                    searchText: .constant(""),
                    isSearchActive: .constant(false),
                    isLoggedIn: false
                )
            }
            .previewDisplayName("Ospite (Guest)")
            
            // Preview in Modalità Ricerca
            NavigationView {
                MapScreen(
                    searchText: .constant("Pizza"),
                    isSearchActive: .constant(true),
                    isLoggedIn: true
                )
            }
            .previewDisplayName("Ricerca Attiva")
        }
    }
}
