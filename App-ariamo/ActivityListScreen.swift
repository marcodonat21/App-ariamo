import SwiftUI

struct ActivityListScreen: View {
    // Uses the global Activity definition (assuming it's defined in AppConstants.swift)
    let activities = [
        // Order MUST be: (title, imageName, color, description)
        Activity(title: "Sports", imageName: "figure.run", color: .red, description: "Group events focused on physical activity."),
        Activity(title: "Travel & Adventure", imageName: "airplane", color: .orange, description: "Trips, excursions, and new discoveries."),
        Activity(title: "Party & Fun", imageName: "party.popper.fill", color: .yellow, description: "Nights out and social gatherings."),
        Activity(title: "Studying & Learning", imageName: "book.fill", color: .appGreen, description: "Study sessions and cultural events.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // SECTION TITLE
                Text("Find an activity type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                ForEach(activities) { activity in
                    // NavigationLink added to make the card clickable
                    NavigationLink(destination: Text("Detail screen for \(activity.title)")) {
                         ActivityCard(activity: activity)
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes the default NavigationLink effect
                }
            }
            .padding()
            .padding(.bottom, 90) // EXTRA PADDING for custom tab bar
        }
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.large)
    }
}

// ActivityCard
struct ActivityCard: View {
    let activity: Activity
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. MAIN BACKGROUND COLOR
            Rectangle()
                .fill(activity.color)
                .frame(height: 180) // Fixed height
                .cornerRadius(25)
            
            // 2. LARGE SEMI-TRANSPARENT ICON (overlay on the entire card)
            Image(systemName: activity.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120) // Larger icon to fill
                .foregroundColor(.white.opacity(0.3)) // Semi-transparent icon
                .offset(x: 100, y: -20)
                .rotationEffect(.degrees(-15)) // A bit of style
            
            // 3. TEXT CONTENT (Bottom Left)
            VStack(alignment: .leading, spacing: 5) {
                // Title
                Text(activity.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .font(.title)
                
                // Description
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding([.leading, .bottom], 25)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: activity.color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
