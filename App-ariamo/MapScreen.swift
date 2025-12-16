import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id: UUID; let name: String; let coordinate: CLLocationCoordinate2D; let imageName: String; let description: String; let imageData: Data?
}

struct MapScreen: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    @ObservedObject var manager = ActivityManager.shared
    @ObservedObject var userManager = UserManager.shared
    
    @StateObject private var filters = FilterSettings()
    @State private var showFilters = false
    @State private var selectedLocation: MapLocation? = nil
    @State private var navigateToDetail = false
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    var filteredLocations: [MapLocation] {
        let allActs = ActivityManager.defaultActivities + manager.createdActivities
        let filteredActs = filters.apply(to: allActs)
        var locations = filteredActs.map { act in
            MapLocation(id: act.id, name: act.title, coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude), imageName: act.imageName, description: act.description, imageData: act.imageData)
        }
        if !searchText.isEmpty { locations = locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return locations
    }
    
    var liveSelectedLocation: MapLocation? {
        guard let current = selectedLocation else { return nil }
        let liveActivity = manager.createdActivities.first(where: { $0.id == current.id })
            ?? manager.joinedActivities.first(where: { $0.id == current.id })
            ?? ActivityManager.defaultActivities.first(where: { $0.id == current.id })
        
        if let act = liveActivity {
            return MapLocation(id: act.id, name: act.title, coordinate: CLLocationCoordinate2D(latitude: act.latitude, longitude: act.longitude), imageName: act.imageName, description: act.description, imageData: act.imageData)
        }
        return current
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear.contentShape(Rectangle()).onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil); withAnimation { selectedLocation = nil } }
            
            Map(coordinateRegion: $region, annotationItems: filteredLocations + [
                MapLocation(id: UUID(), name: "ME", coordinate: ActivityManager.userLocation.coordinate, imageName: "person.fill", description: "", imageData: nil)
            ]) { location in
                
                MapAnnotation(coordinate: location.coordinate) {
                    if location.name == "ME" {
                        ZStack {
                            if filters.enableDistanceFilter {
                                GeometryReader { geo in
                                    let pixelRadius = (filters.maxDistanceKm / 111.0) * (UIScreen.main.bounds.height / region.span.latitudeDelta)
                                    ZStack {
                                        Circle().fill(Color.blue.opacity(0.15)).frame(width: pixelRadius * 2, height: pixelRadius * 2)
                                        Circle().stroke(Color.blue.opacity(0.4), lineWidth: 1).frame(width: pixelRadius * 2, height: pixelRadius * 2)
                                    }.position(x: 0, y: 0)
                                }.frame(width: 0, height: 0)
                            }
                            Circle().fill(Color.white).frame(width: 20, height: 20).shadow(radius: 3)
                            Circle().fill(Color.blue).frame(width: 14, height: 14)
                        }
                    } else {
                        MapPinView(location: location, manager: manager, selectedLocation: selectedLocation) {
                            withAnimation(.spring()) {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                isSearchActive = false
                                selectedLocation = location
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.all)
            .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil); withAnimation { selectedLocation = nil } }
            
            VStack {
                HStack {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(14).background(Color.themeCard).clipShape(Circle()).shadow(color: .appGreen.opacity(0.4), radius: 8, x: 0, y: 4).overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }.padding(.top, 50).padding(.leading, 20)
                    Spacer()
                }
                Spacer()
            }
            
            if let liveLoc = liveSelectedLocation {
                MapLocationCard(location: liveLoc) { navigateToDetail = true } onClose: { withAnimation { selectedLocation = nil } }.zIndex(2)
            }
        }
        .background(NavigationLink(destination: destinationView, isActive: $navigateToDetail) { EmptyView() })
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) { FilterSheetView(filters: filters, showSortOptions: false) }
    }
    
    var destinationView: some View {
        if let loc = liveSelectedLocation {
            let originalActivity = ActivityManager.defaultActivities.first(where: { $0.id == loc.id }) ?? manager.createdActivities.first(where: { $0.id == loc.id }) ?? manager.joinedActivities.first(where: { $0.id == loc.id })
            let activity = Activity(id: loc.id, title: loc.name, category: originalActivity?.category ?? "General", imageName: loc.imageName, imageData: loc.imageData, color: .appGreen, description: loc.description, date: originalActivity?.date ?? Date(), locationName: originalActivity?.locationName ?? "Naples, IT", lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
            return AnyView(ActivityDetailView(activity: activity))
        } else { return AnyView(EmptyView()) }
    }
}

// --- MAP PIN VIEW AGGIORNATO CON CUORE ---
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
                    // CHECK PREFERITI
                    let isFavorite = manager.favoriteActivities.contains(location.id)
                    
                    // Cerchio principale
                    Circle()
                        .fill(isJoined ? Color.appGreen : Color.red)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 4)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    
                    Image(systemName: "mappin")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    // STELLA (Creatore) - Alto Destra
                    if isCreatedByMe {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .padding(3)
                            .background(Circle().fill(Color.white))
                            .offset(x: 14, y: -14)
                    }
                    
                    // CUORE (Preferito) - Alto Sinistra
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(3)
                            .background(Circle().fill(Color.white))
                            .offset(x: -14, y: -14)
                    }
                }
                
                // Nome
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

// MapLocationCard rimane uguale
struct MapLocationCard: View { let location: MapLocation; let onTap: () -> Void; let onClose: () -> Void; var body: some View { ZStack(alignment: .topTrailing) { HStack(alignment: .center, spacing: 15) { if let data = location.imageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle()).overlay(Circle().stroke(Color.appGreen, lineWidth: 2)) } else { ZStack { Circle().fill(Color.appGreen.opacity(0.15)).frame(width: 60, height: 60); Image(systemName: location.imageName).font(.title).foregroundColor(.appGreen) } }; VStack(alignment: .leading, spacing: 4) { Text(location.name).font(.headline).foregroundColor(.primary); Text(location.description).font(.subheadline).foregroundColor(.secondary).lineLimit(1) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)).padding(.trailing, 20) }.padding(20).background(Color.themeCard).cornerRadius(25).shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5).onTapGesture(perform: onTap); Button(action: onClose) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.4)).padding(10) } }.padding(.horizontal, 20).padding(.bottom, 120).transition(.move(edge: .bottom).combined(with: .opacity)) } }
