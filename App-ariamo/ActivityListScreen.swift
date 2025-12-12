import SwiftUI

struct ActivityListScreen: View {
    // Dati fittizi (Activity è definito in AppConstants)
    let activities = [
        Activity(title: "Sport", imageName: "figure.run"),
        Activity(title: "Travel & Adventure", imageName: "airplane"),
        Activity(title: "Party", imageName: "music.note"),
        Activity(title: "Holiday", imageName: "sun.max.fill")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(activities) { activity in
                        ActivityCard(activity: activity)
                    }
                }
                .padding()
            }
            .navigationTitle("Activities")
        }
    }
}

// Componente Card Attività
struct ActivityCard: View {
    let activity: Activity
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Immagine di sfondo (simulata)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 150)
                .cornerRadius(15)
                .overlay(
                    Image(systemName: activity.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                        .foregroundColor(.white.opacity(0.5))
                )
            
            // Testo sopra l'immagine
            VStack(alignment: .leading) {
                Text(activity.title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding()
        }
    }
}

struct ActivityListScreen_Previews: PreviewProvider {
    static var previews: some View {
        ActivityListScreen()
    }
}
