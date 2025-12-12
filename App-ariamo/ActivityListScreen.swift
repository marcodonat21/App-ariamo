import SwiftUI

struct ActivityListScreen: View {
    // Usa la definizione globale di Activity presente in AppConstants.swift
    let activities = [
        Activity(title: "Sport", imageName: "figure.run"),
        Activity(title: "Travel & Adventure", imageName: "airplane"),
        Activity(title: "Party", imageName: "music.note"),
        Activity(title: "Holiday", imageName: "sun.max.fill")
    ]

    var body: some View {
        // Rimuoviamo NavigationView interna perché c'è già in ContentView
        ScrollView {
            VStack(spacing: 20) {
                ForEach(activities) { activity in
                    ActivityCard(activity: activity)
                }
            }
            .padding()
            .padding(.bottom, 90) // PADDING EXTRA per la barra custom
        }
        .navigationTitle("Activities")
    }
}

// ActivityCard
struct ActivityCard: View {
    let activity: Activity
    var body: some View {
        ZStack(alignment: .bottomLeading) {
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

// --- PREVIEW ---
struct ActivityListScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ActivityListScreen()
        }
    }
}
