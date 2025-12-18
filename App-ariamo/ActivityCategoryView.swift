import SwiftUI

struct ActivityCategoryView: View {
    // Riceviamo la categoria scelta (es. "Sports")
    let category: String
    
    @ObservedObject var manager = ActivityManager.shared
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    
    // FILTRI
    @StateObject private var filters = FilterSettings()
    @State private var showFilters = false
    
    // Callback per richiedere il login quando necessario
    var onLoginRequest: ((AuthContext) -> Void)?
    
    // Logica di filtraggio
        var filteredActivities: [Activity] {
            // *** MODIFICA: Solo manager.allActivities (Database) ***
            let rawActivities = manager.allActivities
            
            // Rimuoviamo duplicati
            let allActivities = Array(Dictionary(grouping: rawActivities, by: { $0.id }).compactMap { $0.value.first })
            
            // 2. Filtriamo per Categoria
            var result = allActivities.filter { $0.category == category }
            
            // 3. Applichiamo i Filtri
            result = filters.apply(to: result)
            
            // 4. Filtriamo per Testo
            if !searchText.isEmpty {
                result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
            
            return result
        }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    CustomBackButton() // Tasto Indietro Verde
                    Spacer()
                    Text(category).font(.title2).bold().foregroundColor(.themeText)
                    Spacer()
                    
                    // Tasto Filtri
                    Button(action: { showFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.appGreen)
                            .padding(10)
                            .background(Color.themeCard)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // LISTA ATTIVITÀ
                if filteredActivities.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass").font(.system(size: 50)).foregroundColor(.gray)
                        Text("No activities found.").font(.headline).foregroundColor(.gray)
                        Text("Try changing filters.").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 15) {
                            ForEach(filteredActivities) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity, onLoginRequest: onLoginRequest)) {
                                    DetailedActivityRow(activity: activity)
                                }
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) {
            FilterSheetView(filters: filters)
        }
    }
}

// --- ROW DETTAGLIATA (Necessaria qui perché usata dalla lista) ---
struct DetailedActivityRow: View {
    let activity: Activity
    @ObservedObject var manager = ActivityManager.shared
    
    var body: some View {
        HStack(spacing: 15) {
            // Immagine
            if let data = activity.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appGreen, lineWidth: 2))
            } else {
                Image(systemName: activity.imageName)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(activity.color)
                    .clipShape(Circle())
            }
            
            // Testi
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundColor(.themeText)
                    .lineLimit(1)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.themeSecondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Icone Stato
            HStack(spacing: 8) {
                if manager.isFavorite(activity: activity) {
                    Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                }
                if manager.isJoined(activity: activity) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.appGreen).font(.caption)
                }
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
