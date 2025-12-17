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
    @ObservedObject var userManager = UserManager.shared // Monitoriamo il manager per la memoria
    
    @State private var showCreationWizard = false
    @State private var showAuthSheet = false
    @State private var selectedTab: AppTab = .home
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    // TRACCIAMENTO AZIONE SOSPESA
    @State private var authContext: AuthContext = .none
    
    // Banner di successo post-join
    @State private var showJoinSuccess = false
    @State private var joinedActivityTitle = ""
    
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
                            ActivityListScreen(onLoginRequest: { context in
                                self.authContext = context
                                self.showAuthSheet = true
                            })
                            .navigationBarHidden(true)
                            .id(activitiesID)
                        case .profile:
                            // Passiamo isLoggedIn e la closure per il login dal profilo
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
                
                if isSearchActive {
                    searchBarView
                }
                
                if !isFocused {
                    tabBarView
                }
            }
        }
        // --- SHEETS ---
        .sheet(isPresented: $showCreationWizard) {
            CreationWizardView()
        }
        .sheet(isPresented: $showAuthSheet) {
            NavigationView {
                AuthLandingScreen(isLoggedIn: $isLoggedIn)
            }
        }
        .sheet(isPresented: $manager.showDetailFromNotification) {
            if let act = manager.selectedActivityFromNotification {
                // Passiamo la richiesta di login dal dettaglio alla ContentView
                ActivityDetailView(activity: act, onLoginRequest: { context in
                    self.authContext = context
                    self.showAuthSheet = true
                })
            }
        }
        // --- OVERLAY BANNER SUCCESSO ---
        .overlay(
            Group {
                if showJoinSuccess {
                    JoinSuccessBanner(
                        activityTitle: joinedActivityTitle,
                        onDismiss: {
                            withAnimation {
                                showJoinSuccess = false
                            }
                        }
                    )
                    .zIndex(999)
                }
            }
        )
        .onAppear {
            LocationManager.shared.enableLocation()
        }
        // --- LOGICA DI RE-INDIRIZZAMENTO INTELLIGENTE (FIX MEMORIA) ---
        .onReceive(userManager.$isLoggedIn) { newValue in
            // Se il login passa a true tramite UserManager (Login/FaceID/Register)
            if newValue == true {
                // Sincronizziamo il binding locale della AppRootView
                if self.isLoggedIn != true { self.isLoggedIn = true }
                
                // Se lo sheet è aperto, chiudiamolo e navighiamo
                if showAuthSheet {
                    showAuthSheet = false
                    // Aspettiamo che lo sheet si chiuda prima di eseguire l'azione sospesa
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        handlePostLoginNavigation()
                    }
                }
            } else {
                // Se scatta il logout
                if self.isLoggedIn != false { self.isLoggedIn = false }
            }
        }
    }
    
    // Gestore della navigazione post-login
    private func handlePostLoginNavigation() {
        switch authContext {
        case .createActivity:
            showCreationWizard = true
        case .profile:
            selectedTab = .profile
        case .joinActivity(let activity):
            // Join automatico post-login
            manager.joinActivityOnline(activity: activity)
            // Mostra banner di successo
            joinedActivityTitle = activity.title
            withAnimation {
                showJoinSuccess = true
            }
        case .none:
            break
        }
        // Resetta il contesto per la prossima volta
        authContext = .none
    }
    
    // --- COMPONENTI UI ---
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
            TextField("Search place...", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.white)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit { hideKeyboard() }
            
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
    
    private var tabBarView: some View {
        HStack(spacing: 20) {
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
            
            Button(action: {
                if !isSearchActive {
                    selectedTab = .home
                    withAnimation(.spring()) { isSearchActive = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }
                } else {
                    withAnimation(.spring()) { isSearchActive = false; searchText = ""; isFocused = false }
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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// --- BANNER DI SUCCESSO POST-JOIN ---
struct JoinSuccessBanner: View {
    let activityTitle: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appGreen)
                
                Text("Success!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Text("You joined \(activityTitle)!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("OK") {
                    onDismiss()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appGreen)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding(.horizontal)
            }
            .padding(30)
            .background(Color.themeCard)
            .cornerRadius(20)
            .padding(40)
        }
    }
}

// Elemento singolo della Tab Bar
struct CustomTabItem: View {
    let icon: String; let title: String; let isActive: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: { withAnimation(.spring()) { onTap() } }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? .appGreen : .gray)
                    .opacity(isActive ? 1.0 : 0.6)
                if isActive {
                    Text(title).font(.caption2).bold().foregroundColor(.appGreen)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
