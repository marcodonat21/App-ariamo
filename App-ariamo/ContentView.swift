import SwiftUI

struct ContentView: View {
    @State private var showCreationWizard = false
    @State private var selectedTab: Tab = .home
    @State private var isSearchActive = false
    @State private var searchText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            
            NavigationView {
                ZStack(alignment: .topTrailing) {
                    switch selectedTab {
                    case .home:
                        // *** MODIFIED HERE: We pass isSearchActive *** // Translated Comment
                        MapScreen(searchText: $searchText, isSearchActive: $isSearchActive)
                    case .activities:
                        ActivityListScreen().navigationBarHidden(true)
                    case .profile:
                        ProfileScreen().navigationBarHidden(true)
                    case .search:
                        EmptyView()
                    }
                    
                    // PLUS BUTTON (only visible on Home and if search is not active)
                    if !isSearchActive && selectedTab == .home { // Translated Comment
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
            
            VStack(spacing: 15) {
                Spacer()
                
                // SEARCH BAR
                if isSearchActive { // Translated Comment
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
                        TextField("Search...", text: $searchText) // Translated Placeholder
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
                }
                
                // TAB BAR
                HStack(spacing: 20) { // Translated Comment
                    HStack {
                        CustomTabItem(icon: "house.fill", title: "Home", tab: .home, selected: $selectedTab) // Tab Title in English
                        Spacer()
                        CustomTabItem(icon: "list.bullet.rectangle.portrait.fill", title: "Activities", tab: .activities, selected: $selectedTab) // Tab Title in English
                        Spacer()
                        CustomTabItem(icon: "person.crop.circle.fill", title: "Profile", tab: .profile, selected: $selectedTab) // Tab Title in English
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                    .overlay(
                        Capsule().stroke(
                            LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                    )
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            if !isSearchActive {
                                selectedTab = .home
                                isSearchActive = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
                            } else {
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
                            .background(isSearchActive ? Color.red.opacity(0.8) : Color.appGreen.opacity(0.7))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                            .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showCreationWizard) {
            CreationWizardView()
        }
    }
}

// CustomTabItem (Stays the same) // Translated Comment
struct CustomTabItem: View {
    let icon: String; let title: String; let tab: Tab; @Binding var selected: Tab
    var isSelected: Bool { selected == tab }
    var body: some View {
        Button(action: { withAnimation(.spring()) { selected = tab } }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .appGreen : .gray)
                if isSelected {
                    Text(title).font(.caption2).bold().foregroundColor(.appGreen)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
