import SwiftUI
import PhotosUI
import MapKit

struct EditActivityView: View {
    let originalActivity: Activity
    @Environment(\.presentationMode) var presentationMode
    
    // Stati modificabili
    @State private var title: String
    @State private var description: String
    @State private var category: String
    @State private var date: Date
    @State private var locationName: String
    @State private var latitude: Double
    @State private var longitude: Double
    @State private var activityImageData: Data?
    
    // Foto & Luogo
    @State private var showCamera = false; @State private var showGallery = false; @State private var showActionSheet = false; @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil
    @StateObject private var locationService = LocationSearchService()
    
    let categories = ["Sports", "Travel & Adventure", "Party", "Holiday", "Food", "Culture"]
    
    init(activity: Activity) {
        self.originalActivity = activity
        _title = State(initialValue: activity.title)
        _description = State(initialValue: activity.description)
        _category = State(initialValue: activity.category)
        _date = State(initialValue: activity.date)
        _locationName = State(initialValue: activity.locationName)
        _latitude = State(initialValue: activity.latitude)
        _longitude = State(initialValue: activity.longitude)
        _activityImageData = State(initialValue: activity.imageData)
    }
    
    var body: some View {
        ZStack {
            // SFONDO ADATTIVO (Light/Dark)
            Color.themeBackground.ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.appGreen).padding(12).background(Color.themeCard).clipShape(Circle()).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer(); Text("Edit Activity").font(.headline).bold().foregroundColor(.themeText); Spacer(); Color.clear.frame(width: 44, height: 44)
                }
                .padding().padding(.top, 40).background(Color.themeBackground)
                .onTapGesture { hideKeyboard() }
                
                Form {
                    Section(header: Text("Activity Photo")) {
                        VStack(alignment: .center, spacing: 20) {
                            ZStack {
                                if let data = activityImageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 200).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 15)) }
                                else { ZStack { RoundedRectangle(cornerRadius: 15).fill(Color.appGreen.opacity(0.1)).frame(height: 200); Image(systemName: "photo").font(.largeTitle).foregroundColor(.appGreen) } }
                                VStack { Spacer(); HStack { Spacer(); Image(systemName: "camera.fill").foregroundColor(.white).padding(10).background(Color.appGreen).clipShape(Circle()).padding(10) } }
                            }.frame(height: 200).onTapGesture { hideKeyboard(); showActionSheet = true }
                            Text("Tap image to change").font(.caption).foregroundColor(.gray)
                        }.padding(.vertical, 10)
                    }
                    
                    Section(header: Text("Details")) {
                        TextField("Title", text: $title)
                        Picker("Category", selection: $category) { ForEach(categories, id: \.self) { cat in Text(cat).tag(cat) } }
                        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Section(header: Text("Description")) { TextEditor(text: $description).frame(height: 100) }
                    
                    Section(header: Text("Location")) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                TextField("Search location...", text: $locationService.searchQuery).submitLabel(.done)
                                if !locationService.searchQuery.isEmpty { Button(action: { locationService.searchQuery = ""; locationService.completions = [] }) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                            }
                            if !locationService.completions.isEmpty {
                                Divider()
                                ForEach(locationService.completions, id: \.self) { completion in
                                    Button(action: {
                                        locationName = completion.title
                                        locationService.getCoordinates(for: completion) { lat, lon in self.latitude = lat; self.longitude = lon }
                                        locationService.searchQuery = ""; locationService.completions = []; hideKeyboard()
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(completion.title).foregroundColor(.primary).font(.body)
                                            Text(completion.subtitle).font(.caption).foregroundColor(.gray)
                                        }.padding(.vertical, 5).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                    }.buttonStyle(PlainButtonStyle())
                                    Divider()
                                }
                            }
                            HStack { Image(systemName: "mappin.and.ellipse").foregroundColor(.red); Text("Selected: ").font(.caption).foregroundColor(.gray); Text(locationName).font(.subheadline).bold().foregroundColor(.primary) }.padding(.vertical, 5)
                        }.padding(.vertical, 5)
                    }
                    Section { Button(action: saveChanges) { Text("Save Changes").bold().frame(maxWidth: .infinity).foregroundColor(.appGreen) } }
                }
                .scrollDismissesKeyboard(.immediately)
                .gesture(DragGesture().onChanged { _ in hideKeyboard() })
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Change Photo", isPresented: $showActionSheet) { Button("Camera") { showCamera = true }; Button("Gallery") { showGallery = true }; if activityImageData != nil { Button("Remove", role: .destructive) { activityImageData = nil } }; Button("Cancel", role: .cancel) { } }
        .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }.photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images).onChange(of: inputImage) { new in if let new = new, let d = new.jpegData(compressionQuality: 0.8) { activityImageData = d } }.onChange(of: selectedItem) { item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { activityImageData = d } } }
    }
    
    func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    
    func saveChanges() {
            // Creiamo l'attività mantenendo l'ID originale dell'attività che stiamo modificando
            let updatedActivity = Activity(
                id: originalActivity.id, // <--- QUESTO EVITA IL DUPLICATO
                title: title,
                category: category,
                imageName: originalActivity.imageName,
                imageData: activityImageData,
                color: .appGreen,
                description: description,
                date: date,
                locationName: locationName,
                lat: latitude,
                lon: longitude
            )
            
            // Chiamiamo la funzione di update, non quella di create!
            ActivityManager.shared.updateActivity(updatedActivity)
            presentationMode.wrappedValue.dismiss()
        }
}
