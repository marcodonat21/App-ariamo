import SwiftUI

struct ContentView: View {
    @Binding var isLoggedIn: Bool
    
    @State private var showCreationWizard = false
    @State private var selectedTab: AppTab = .home
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    // ID per il reset delle pagine
    @State private var homeID = UUID()
    @State private var activitiesID = UUID()
    @State private var profileID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. LIVELLO MAPPA/CONTENUTO
            NavigationView {
                ZStack(alignment: .topTrailing) {
                    
                    // GESTORE CHIUSURA TASTIERA GLOBALE
                    // Questo sfondo invisibile cattura i tap quando la tastiera è aperta
                    if isFocused || isSearchActive {
                        Color.black.opacity(0.001) // Quasi invisibile ma interattivo
                            .ignoresSafeArea()
                            .onTapGesture {
                                hideKeyboard()
                                isFocused = false
                            }
                            .zIndex(1) // Stare sopra al contenuto ma sotto alla UI
                    }
                    
                    Group {
                        switch selectedTab {
                        case .home:
                            MapScreen(searchText: $searchText, isSearchActive: $isSearchActive)
                                .id(homeID)
                        case .activities:
                            ActivityListScreen()
                                .navigationBarHidden(true)
                                .id(activitiesID)
                        case .profile:
                            ProfileScreen(isLoggedIn: $isLoggedIn)
                                .navigationBarHidden(true)
                                .id(profileID)
                        case .search:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // BOTTONE "+" (Solo in Home e se non cerchi)
                    if !isSearchActive && selectedTab == .home {
                        Button(action: { showCreationWizard = true }) {
                            Image(systemName: "plus")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(
                                    Circle()
                                        .fill(Color.appGreen)
                                        .shadow(color: .appGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                                )
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .ignoresSafeArea(.all)
            
            // 2. LIVELLO UI (SEARCH + TAB BAR)
            VStack(spacing: 0) {
                Spacer()
                
                // BARRA DI RICERCA
                if isSearchActive {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                        TextField("Search place...", text: $searchText)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .focused($isFocused)
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 25)
                    .padding(.bottom, 15)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // TAB BAR (Nascondi se tastiera è aperta)
                if !isFocused {
                    HStack(spacing: 20) {
                        // Tasti Sinistra
                        HStack {
                            CustomTabItem(icon: "house.fill", title: "Home", isActive: selectedTab == .home) {
                                if selectedTab == .home {
                                    homeID = UUID(); isSearchActive = false; isFocused = false
                                } else { selectedTab = .home }
                            }
                            Spacer()
                            CustomTabItem(icon: "list.bullet.rectangle.portrait.fill", title: "Activities", isActive: selectedTab == .activities) {
                                if selectedTab == .activities { activitiesID = UUID() } else { selectedTab = .activities }
                                isSearchActive = false
                            }
                            Spacer()
                            CustomTabItem(icon: "person.crop.circle.fill", title: "Profile", isActive: selectedTab == .profile) {
                                if selectedTab == .profile { profileID = UUID() } else { selectedTab = .profile }
                                isSearchActive = false
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(.ultraThinMaterial)
                        .overlay(Capsule().stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                        
                        // Tasto Lente (Destra)
                        Button(action: {
                            // LOGICA MIGLIORATA PER EVITARE PAGINA BIANCA
                            if !isSearchActive {
                                // 1. Prima cambia tab
                                selectedTab = .home
                                // 2. Poi attiva la ricerca con un micro ritardo
                                withAnimation(.spring()) {
                                    isSearchActive = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isFocused = true
                                }
                            } else {
                                withAnimation(.spring()) {
                                    isSearchActive = false
                                    searchText = ""
                                    isFocused = false
                                }
                            }
                        }) {
                            Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(.ultraThinMaterial)
                                .background(isSearchActive ? Color.red.opacity(0.8) : Color.appGreen.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                                .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showCreationWizard) {
            CreationWizardView()
        }
    }
    
    // Helper per chiudere tastiera
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// CustomTabItem
struct CustomTabItem: View {
    let icon: String; let title: String; let isActive: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: { withAnimation(.spring()) { onTap() } }) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 24)).foregroundColor(isActive ? .appGreen : .gray).opacity(isActive ? 1.0 : 0.6)
                if isActive { Text(title).font(.caption2).bold().foregroundColor(.appGreen) }
            }.frame(maxWidth: .infinity)
        }
    }
}
