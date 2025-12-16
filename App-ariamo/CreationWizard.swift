import SwiftUI
import PhotosUI
import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest
        cancellable = $searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main).sink { [weak self] query in
            if query.isEmpty { self?.completions = [] } else { self?.completer.queryFragment = query }
        }
    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) { self.completions = completer.results }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) { print("Error: \(error.localizedDescription)") }
    func getCoordinates(for completion: MKLocalSearchCompletion, result: @escaping (Double, Double) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: searchRequest).start { response, _ in
            if let item = response?.mapItems.first { let c = item.placemark.coordinate; result(c.latitude, c.longitude) }
        }
    }
}

struct CreationWizardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var step = 1
    @State private var nuovoEvento = DatiEvento()
    
    var body: some View {
        ZStack {
            Color.appGreen.opacity(0.1).ignoresSafeArea()
            Color.clear.contentShape(Rectangle()).onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            
            VStack {
                // HEADER CON STILE BACK BUTTON UNIFORMATO
                HStack {
                    if step > 1 && step < 7 {
                        Button(action: { withAnimation { step -= 1 } }) {
                            // *** NUOVO STILE ***
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.appGreen)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        // Spacer per mantenere allineamento se non c'è back
                        Color.clear.frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // Tasto Chiudi (X)
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                }.padding()
                
                Group {
                    if step == 1 { StepCategoryView(data: $nuovoEvento, nextAction: nextStep) }
                    else if step == 2 { StepNameView(data: $nuovoEvento, nextAction: nextStep) }
                    else if step == 3 { StepDescriptionView(data: $nuovoEvento, nextAction: nextStep) }
                    else if step == 4 { StepDateView(data: $nuovoEvento, nextAction: nextStep) }
                    else if step == 5 { StepLocationView(data: $nuovoEvento, nextAction: nextStep) }
                    else if step == 6 { StepPhotoView(data: $nuovoEvento, nextAction: nextStep) }
                    else {
                        EventSummaryView(event: nuovoEvento, closeAction: {
                            let finalLat = nuovoEvento.lat ?? (40.8518 + Double.random(in: -0.02...0.02))
                            let finalLon = nuovoEvento.lon ?? (14.2681 + Double.random(in: -0.02...0.02))
                            let desc = nuovoEvento.descrizione.isEmpty ? "\(nuovoEvento.tipo) at \(nuovoEvento.luogo)" : nuovoEvento.descrizione
                            let newActivity = Activity(
                                title: nuovoEvento.titolo.isEmpty ? nuovoEvento.tipo : nuovoEvento.titolo,
                                category: nuovoEvento.tipo,
                                imageName: "star.fill",
                                imageData: nuovoEvento.imageData,
                                color: .appGreen,
                                description: desc,
                                date: nuovoEvento.data,
                                lat: finalLat,
                                lon: finalLon
                            )
                            ActivityManager.shared.create(activity: newActivity)
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                Spacer()
            }
        }
    }
    func nextStep() { withAnimation { step += 1 } }
    
    // STEP 1: CATEGORIA (AGGIORNATA)
    struct StepCategoryView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        // AGGIUNTE LE CATEGORIE MANCANTI
        let options = ["Sports", "Travel & Adventure", "Party", "Holiday", "Food", "Culture"]
        
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)
                    Image(systemName: "flag.2.crossed.fill").font(.system(size: 40)).foregroundColor(.appGreen)
                    Text("Select Category").font(.title2).bold().foregroundColor(.appGreen)
                    ForEach(options, id: \.self) { option in
                        Button(action: { data.tipo = option; nextAction() }) {
                            Text(option).font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(25).shadow(color: .black.opacity(0.05), radius: 5)
                        }.padding(.horizontal, 40)
                    }
                }
            }
        }
    }
    
    // STEP 2: NOME
    struct StepNameView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    Spacer().frame(height: 20)
                    Image(systemName: "pencil.and.outline").font(.system(size: 40)).foregroundColor(.appGreen)
                    Text("Name your activity").font(.title2).bold().foregroundColor(.appGreen)
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        TextField("E.g. Football match...", text: $data.titolo).padding().font(.headline)
                    }.frame(height: 60).padding(.horizontal, 40)
                    Button(action: nextAction) { Text("Next").bold().foregroundColor(.white).padding().frame(width: 200).background(data.titolo.isEmpty ? Color.gray : Color.appGreen).cornerRadius(25) }.disabled(data.titolo.isEmpty)
                    Spacer().frame(height: 300)
                }.padding(.vertical)
            }.onTapGesture { endEditing() }
        }
    }
    
    // STEP 3: DESCRIZIONE
    struct StepDescriptionView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    Spacer().frame(height: 20)
                    Image(systemName: "text.quote").font(.system(size: 40)).foregroundColor(.appGreen)
                    Text("Describe your activity").font(.title2).bold().foregroundColor(.appGreen)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        TextField("E.g. The Temple of Football...", text: $data.descrizione).padding().font(.headline)
                    }.frame(height: 80).padding(.horizontal, 40)
                    Button(action: nextAction) { Text("Next").bold().foregroundColor(.white).padding().frame(width: 200).background(data.descrizione.isEmpty ? Color.gray : Color.appGreen).cornerRadius(25) }.disabled(data.descrizione.isEmpty)
                    Spacer().frame(height: 300)
                }.padding(.vertical)
            }.onTapGesture { endEditing() }
        }
    }
    
    // STEP 4: DATA
    struct StepDateView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        var body: some View {
            VStack(spacing: 20) {
                Text("When are you joining?").font(.title2).bold().foregroundColor(.appGreen)
                DatePicker("", selection: $data.data, displayedComponents: [.date, .hourAndMinute]).datePickerStyle(WheelDatePickerStyle()).labelsHidden()
                Button(action: nextAction) { Text("Next").foregroundColor(.white).padding().frame(width: 200).background(Color.appGreen).cornerRadius(25) }
            }
        }
    }
    
    // STEP 5: LUOGO
    struct StepLocationView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        @StateObject private var locationService = LocationSearchService()
        var body: some View {
            VStack(spacing: 20) {
                Text("Where are you joining?").font(.title2).bold().foregroundColor(.appGreen).padding(.top, 20)
                ZStack {
                    RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    HStack { Image(systemName: "magnifyingglass").foregroundColor(.appGreen); TextField("Search place...", text: $locationService.searchQuery).font(.headline).foregroundColor(.primary).submitLabel(.done) }.padding()
                }.frame(height: 60).padding(.horizontal, 40)
                if !locationService.completions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(locationService.completions, id: \.self) { completion in
                                Button(action: {
                                    data.luogo = completion.title + ", " + completion.subtitle
                                    locationService.searchQuery = completion.title
                                    locationService.completions = []; endEditing()
                                    locationService.getCoordinates(for: completion) { lat, lon in data.lat = lat; data.lon = lon }
                                }) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(completion.title).font(.headline).foregroundColor(.black)
                                        if !completion.subtitle.isEmpty { Text(completion.subtitle).font(.caption).foregroundColor(.gray) }
                                        Divider()
                                    }.padding(.horizontal).padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }.background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal, 40).shadow(color: .black.opacity(0.1), radius: 5)
                    }.frame(maxHeight: 250)
                }
                Spacer()
                Button(action: { if data.luogo.isEmpty { data.luogo = locationService.searchQuery }; nextAction() }) { Text("Next").bold().foregroundColor(.white).padding().frame(width: 200).background(locationService.searchQuery.isEmpty ? Color.gray : Color.appGreen).cornerRadius(25) }.disabled(locationService.searchQuery.isEmpty).padding(.bottom, 20)
            }.onTapGesture { endEditing() }
        }
    }
    
    // STEP 6: FOTO
    struct StepPhotoView: View {
        @Binding var data: DatiEvento; var nextAction: () -> Void
        @State private var selectedItem: PhotosPickerItem? = nil; @State private var inputImage: UIImage? = nil; @State private var showCamera = false
        var body: some View {
            VStack(spacing: 30) {
                Spacer().frame(height: 20)
                Text("Add a cover photo").font(.title2).bold().foregroundColor(.appGreen)
                ZStack {
                    if let imageData = data.imageData, let uiImage = UIImage(data: imageData) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 200, height: 200).clipShape(RoundedRectangle(cornerRadius: 30)).shadow(radius: 10) }
                    else { RoundedRectangle(cornerRadius: 30).fill(Color.white).frame(width: 200, height: 200).shadow(color: .black.opacity(0.05), radius: 10).overlay(VStack { Image(systemName: "camera.fill").font(.largeTitle).foregroundColor(.gray); Text("No Image").font(.caption).foregroundColor(.gray) }) }
                }
                HStack(spacing: 20) { PhotosPicker(selection: $selectedItem, matching: .images) { Label("Gallery", systemImage: "photo.on.rectangle").padding().background(Color.white).cornerRadius(15).shadow(radius: 2) }; Button(action: { showCamera = true }) { Label("Camera", systemImage: "camera").padding().background(Color.white).cornerRadius(15).shadow(radius: 2) } }
                Button(action: nextAction) { Text(data.imageData == nil ? "Skip Photo" : "Next").bold().foregroundColor(.white).padding().frame(width: 200).background(Color.appGreen).cornerRadius(25) }
                Spacer()
            }
            .sheet(isPresented: $showCamera) { CameraPicker(selectedImage: $inputImage) }
            .onChange(of: inputImage) { new in if let new = new, let d = new.jpegData(compressionQuality: 0.7) { data.imageData = d } }
            .onChange(of: selectedItem) { item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { data.imageData = d } } }
        }
    }
    
    // STEP 7: RIEPILOGO
    struct EventSummaryView: View {
        let event: DatiEvento
        var closeAction: () -> Void
        
        var body: some View {
            VStack(spacing: 25) {
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundColor(.appGreen)
                Text("Activity Created!").font(.title).bold()
                
                Divider().padding()
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack { Image(systemName: "star.fill"); Text(event.titolo).bold() }
                    HStack { Image(systemName: "text.quote"); Text(event.descrizione).italic().lineLimit(1) }
                    HStack { Image(systemName: "calendar"); Text(event.data.formatted(date: .numeric, time: .shortened)) }
                    HStack { Image(systemName: "mappin.and.ellipse"); Text(event.luogo).bold() } // Mostra luogo
                }
                .padding().background(Color.white).cornerRadius(15).shadow(radius: 5).padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    let finalLat = event.lat ?? (40.8518 + Double.random(in: -0.02...0.02))
                    let finalLon = event.lon ?? (14.2681 + Double.random(in: -0.02...0.02))
                    
                    let newActivity = Activity(
                        title: event.titolo.isEmpty ? event.tipo : event.titolo,
                        category: event.tipo,
                        imageName: "star.fill",
                        imageData: event.imageData,
                        color: .appGreen,
                        description: event.descrizione,
                        date: event.data,
                        locationName: event.luogo, // <--- ORA SALVIAMO IL NOME DEL LUOGO!
                        lat: finalLat,
                        lon: finalLon
                    )
                    ActivityManager.shared.create(activity: newActivity)
                    closeAction()
                }) {
                    Text("Confirm").bold().foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.appGreen).cornerRadius(15)
                }
                .padding(.horizontal, 40)
                Spacer()
            }.transition(.scale)
        }
    }
}
