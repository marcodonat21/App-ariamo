import SwiftUI

struct ActivityListScreen: View {
    // Dati fittizi (Activity è definito in AppConstants)
    let activities = [
        Activity(title: "Sport", imageName: "sport", color: .red),
        Activity(title: "Travel & Adventure", imageName: "airplane", color: .orange),
        Activity(title: "Party", imageName: "party", color: .yellow),
        Activity(title: "Studying", imageName: "sun.max.fill", color: .VERDE)
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
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
        ActivityListScreen()
    }
}
