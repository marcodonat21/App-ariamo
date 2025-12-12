import SwiftUI

// --- MAIN ENTRY POINT (TAB BAR) ---
struct ContentView: View {
    @State private var showCreationWizard = false

    var body: some View {
        TabView {
            // Tab 1: Mappa
            MapScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Tab 2: Lista Attività
            ActivityListScreen()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                
            // Tab 3: Info
            InfoScreen()
                .tabItem {
                    Label("Info", systemImage: "person.fill")
                }
        }
        .accentColor(.appGreen) // Colore della selezione Tab Bar
        .overlay(
            // Bottone galleggiante
            Button(action: { showCreationWizard = true }) {
                Image(systemName: "plus")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.appGreen)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(),
            alignment: .bottomTrailing // Posizionato in basso a destra sopra la tab bar
        )
        .sheet(isPresented: $showCreationWizard) {
            CreationWizardView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
