import SwiftUI

struct ActivityListScreen: View {
    // Definizione delle categorie
    let categories = [
        ("Sports", "figure.run", Color.blue),
        ("Food", "fork.knife", Color.orange),
        ("Travel & Adventure", "airplane", Color.yellow),
        ("Party", "balloon.2.fill", Color.purple),
        ("Holiday", "sun.max.fill", Color.pink),
        ("Culture", "building.columns.fill", Color.red)
    ]
    
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
    
    // --- STATI NECESSARI PER IL FIX ---
    // ActivityCategoryView ora richiede questi due parametri
    @State private var searchText = ""
    @State private var isSearchActive = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.ignoresSafeArea() // Sfondo Dark Mode compatibile
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Titolo
                        Text("Explore Categories")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.themeText)
                            .padding(.top, 20)
                        
                        // Griglia Categorie
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(categories, id: \.0) { category in
                                NavigationLink(destination: ActivityCategoryView(
                                    category: category.0,
                                    searchText: $searchText,       // <--- FIX: Passiamo la variabile
                                    isSearchActive: $isSearchActive // <--- FIX: Passiamo la variabile
                                )) {
                                    CategoryCard(title: category.0, icon: category.1, color: category.2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 100) // Spazio per la TabBar
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Card Grafica per la Categoria
struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.themeText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.themeCard) // Card colore adattivo
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivityListScreen_Previews: PreviewProvider {
    static var previews: some View {
        ActivityListScreen()
    }
}
