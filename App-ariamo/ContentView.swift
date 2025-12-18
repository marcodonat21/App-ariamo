import SwiftUI

// --- 1. DEFINIZIONE DEL CONTESTO DI AUTENTICAZIONE ---
enum AuthContext {
    case none
    case profile
    case createActivity
    case joinActivity(Activity)
}

struct ContentView: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject var manager = ActivityManager.shared
    @ObservedObject var userManager = UserManager.shared
    
    @State private var showCreationWizard = false
    @State private var showAuthSheet = false
    @State private var selectedTab: AppTab = .home
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @State private var authContext: AuthContext = .none
    
    // STATES PER GLI AVVISI
    @State private var showAlreadyJoinedAlert = false
    @State private var showCreatorAlert = false
    
    @State private var homeID = UUID()
    @State private var activitiesID = UUID()
    @State private var profileID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            
            NavigationView {
                ZStack(alignment: .topTrailing) {
                    
                    Group {
                        switch selectedTab {
                        case .home:
                            MapScreen(
                                searchText: $searchText,
                                isSearchActive: $isSearchActive,
                                onLoginRequest: { context in
                                    self.authContext = context
                                    self.showAuthSheet = true
                                },
                                onCreateActivity: {
                                    self.showCreationWizard = true
                                },
                                isLoggedIn: isLoggedIn
                            )
                            .id(homeID)
                            
                        case .activities:
                            ActivityListScreen()
                                .navigationBarHidden(true)
                                .id(activitiesID)
                                
                        case .profile:
                            ProfileScreen(isLoggedIn: $isLoggedIn, onLoginRequest: {
                                self.authContext = .profile
                                self.showAuthSheet = true
                            })
                            .navigationBarHidden(true)
                            .id(profileID)
                            
                        case .search:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .ignoresSafeArea(.all)
            
            // TAB BAR & SEARCH
            VStack(spacing: 0) {
                Spacer()
                if isSearchActive { searchBarView }
                if !isFocused { tabBarView }
            }
            
            // --- OVERLAY DI AVVISO ---
            if showAlreadyJoinedAlert {
                WarningOverlay(
                    title: "Attention",
                    message: "You have already joined this activity!",
                    onClose: {
                        showAlreadyJoinedAlert = false
                        authContext = .none
                        // FIX: Non riapriamo più la scheda qui
                    }
                )
                .zIndex(100)
            }
            
            if showCreatorAlert {
                WarningOverlay(
                    title: "Creator",
                    message: "You created this activity!",
                    onClose: {
                        showCreatorAlert = false
                        authContext = .none
                        // FIX: Non riapriamo più la scheda qui
                    }
                )
                .zIndex(100)
            }
        }
        // --- SHEETS ---
        .sheet(isPresented: $showCreationWizard) { CreationWizardView() }
        .sheet(isPresented: $showAuthSheet) { NavigationView { AuthLandingScreen(isLoggedIn: $isLoggedIn) } }
        
        // Questo sheet serve SOLO per le notifiche push esterne, non per la navigazione interna post-login
        .sheet(isPresented: $manager.showDetailFromNotification) {
            if let act = manager.selectedActivityFromNotification {
                ActivityDetailView(activity: act, onLoginRequest: { context in
                    self.authContext = context
                    self.showAuthSheet = true
                })
            }
        }
        .onAppear { LocationManager.shared.enableLocation() }
        .onReceive(userManager.$isLoggedIn) { newValue in
            if newValue == true {
                if self.isLoggedIn != true { self.isLoggedIn = true }
                
                if showAuthSheet {
                    showAuthSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        handlePostLoginNavigation()
                    }
                }
            } else {
                if self.isLoggedIn != false { self.isLoggedIn = false }
            }
        }
    }
    
    // Gestore della navigazione post-login
    private func handlePostLoginNavigation() {
        switch authContext {
        case .createActivity:
            showCreationWizard = true
            authContext = .none
            
        case .profile:
            selectedTab = .profile
            authContext = .none
            
        case .joinActivity(let activity):
            // 1. CHECK: Sei il creatore?
            if manager.isCreator(activity: activity) {
                withAnimation { showCreatorAlert = true }
            }
            // 2. CHECK: Sei già iscritto?
            else if manager.isJoined(activity: activity) {
                withAnimation { showAlreadyJoinedAlert = true }
            }
            // 3. Procedi con il Join
            else {
                manager.joinActivityOnline(activity: activity)
                
                // Segnale per mostrare il popup di successo nella vista sottostante
                manager.shouldShowSuccessAfterLogin = true
                
                // *** FIX IMPORTANTE ***
                // Abbiamo rimosso le righe che impostavano 'showDetailFromNotification = true'.
                // Dato che l'utente era già sulla scheda dettaglio prima del login,
                // quando il login si chiude, si ritrova esattamente lì. Non serve riaprirla.
                
                authContext = .none
            }
            
        case .none:
            break
        }
    }
    
    // Componenti UI
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
            TextField("Search place...", text: $searchText)
                .foregroundColor(.white).accentColor(.white).focused($isFocused).submitLabel(.search).onSubmit { hideKeyboard() }
            if !searchText.isEmpty { Button(action: { searchText = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.7)) } }
        }
        .padding().background(.ultraThinMaterial).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1)).padding(.horizontal, 25).padding(.bottom, 15).transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var tabBarView: some View {
        HStack(spacing: 20) {
            HStack {
                CustomTabItem(icon: "house.fill", title: "Home", isActive: selectedTab == .home) { if selectedTab == .home { homeID = UUID(); isSearchActive = false; isFocused = false } else { selectedTab = .home } }
                Spacer()
                CustomTabItem(icon: "list.bullet.rectangle.portrait.fill", title: "Activities", isActive: selectedTab == .activities) { if selectedTab == .activities { activitiesID = UUID() } else { selectedTab = .activities }; isSearchActive = false }
                Spacer()
                CustomTabItem(icon: "person.crop.circle.fill", title: "Profile", isActive: selectedTab == .profile) { if selectedTab == .profile { profileID = UUID() } else { selectedTab = .profile }; isSearchActive = false }
            }
            .padding(.horizontal, 30).padding(.vertical, 15).background(.ultraThinMaterial).overlay(Capsule().stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)).clipShape(Capsule()).shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            Button(action: { if !isSearchActive { selectedTab = .home; withAnimation(.spring()) { isSearchActive = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true } } else { withAnimation(.spring()) { isSearchActive = false; searchText = ""; isFocused = false } } }) {
                Image(systemName: isSearchActive ? "xmark" : "magnifyingglass").font(.title2).foregroundColor(.white).frame(width: 60, height: 60).background(.ultraThinMaterial).background(isSearchActive ? Color.red.opacity(0.8) : Color.appGreen.opacity(0.8)).clipShape(Circle()).shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5).overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 5) // <--- MODIFICATO DA 30 A 5 PER ABBASSARE LA BARRA
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}

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

struct WarningOverlay: View {
    let title: String
    let message: String
    let onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 70)).foregroundColor(.orange)
                Text(title).font(.title2).bold().foregroundColor(.white)
                Text(message).font(.body).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                Button(action: onClose) { Text("OK").fontWeight(.bold).padding().frame(maxWidth: .infinity).background(Color.white).foregroundColor(.black).cornerRadius(15) }.padding(.horizontal, 20)
            }.padding(30).background(Color.themeCard).cornerRadius(25).padding(40).shadow(radius: 20)
        }
    }
}
