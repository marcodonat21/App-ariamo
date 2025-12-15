import SwiftUI
import MapKit // Essential for CLLocationCoordinate2D

struct ActivityDetailView: View {
    let location: MapLocation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                Rectangle()
                    .fill(Color.appGreen.opacity(0.1))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: location.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .foregroundColor(.appGreen)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(location.name)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Label("Naples, NA", systemImage: "mappin.and.ellipse") // Tradotto
                        Spacer()
                        Label("Open now", systemImage: "clock") // Tradotto
                            .foregroundColor(.green)
                    }
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    
                    Divider()
                    
                    Text("Information") // Tradotto
                        .font(.title2)
                        .bold()
                    
                    Text(location.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(5)
                    
                    // Testo placeholder (lasciato in Latin/placeholder style)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.")
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 50)
                    
                    Button(action: {}) {
                        Text("Join Event") // Tradotto
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appGreen)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .padding(25)
                .background(Color.white)
                .cornerRadius(30)
                .offset(y: -30) // Overlap effect
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

// --- PREVIEW (Assuming MapLocation is defined elsewhere) ---
struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityDetailView(location: MapLocation(
            name: "Example Pizzeria", // Tradotto
            // FIX: Explicit coordinates
            coordinate: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
            imageName: "fork.knife",
            description: "Sample description for the preview." // Tradotto
        ))
    }
}
