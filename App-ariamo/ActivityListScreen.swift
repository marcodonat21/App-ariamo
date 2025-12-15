import SwiftUI

struct ActivityListScreen: View {
    // Usa la definizione globale di Activity presente in AppConstants.swift
    let activities = [
        Activity(title: "Sport", imageName: "sport", color: .red),
        Activity(title: "Travel & Adventure", imageName: "airplane", color: .orange),
        Activity(title: "Party", imageName: "party", color: .yellow),
        Activity(title: "Studying", imageName: "sun.max.fill", color: .VERDE)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .font(.title)
                
                Spacer()

                Image(activity.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 380, height: 180, alignment: .leading)
        .background(activity.color)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}


struct ActivityListScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ActivityListScreen()
        }
    }
}
