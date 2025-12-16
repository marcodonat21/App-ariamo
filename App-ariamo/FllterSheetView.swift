import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var filters: FilterSettings
    @Environment(\.presentationMode) var presentationMode
    var showSortOptions: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                if showSortOptions {
                    Section(header: Text("Sort By")) {
                        Picker("Sort by", selection: $filters.sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in Text(option.rawValue).tag(option) }
                        }.pickerStyle(SegmentedPickerStyle())
                        Toggle("Ascending Order", isOn: $filters.isAscending).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    }
                }
                
                Section(header: Text("Participation")) {
                    Picker("Show", selection: $filters.participationStatus) {
                        ForEach(ParticipationFilter.allCases, id: \.self) { status in Text(status.rawValue).tag(status) }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Time Range")) {
                    Toggle("Filter by Time", isOn: $filters.enableTimeFilter).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    if filters.enableTimeFilter {
                        DatePicker("From", selection: $filters.startTime, displayedComponents: .hourAndMinute)
                        DatePicker("To", selection: $filters.endTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("Date Range")) {
                    Toggle("Filter by Date", isOn: $filters.enableDateFilter).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    if filters.enableDateFilter {
                        DatePicker("Start", selection: $filters.startDate, displayedComponents: .date)
                        DatePicker("End", selection: $filters.endDate, displayedComponents: .date)
                    }
                }
                
                // SLIDER DISTANZA (ORA E' QUI E FUNZIONA COME UN FILTRO)
                Section(header: Text("Distance Radius")) {
                    Toggle("Enable Distance Filter", isOn: $filters.enableDistanceFilter).toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    if filters.enableDistanceFilter {
                        VStack {
                            Slider(value: $filters.maxDistanceKm, in: 1...100, step: 1).accentColor(.appGreen)
                            HStack {
                                Text("Max Distance:")
                                Spacer()
                                Text("\(Int(filters.maxDistanceKm)) km").bold().foregroundColor(.appGreen)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) { Text("Apply Filters").bold().frame(maxWidth: .infinity).foregroundColor(.white).padding(.vertical, 5) }.listRowBackground(Color.appGreen)
                    Button(action: {
                        filters.sortOption = .date; filters.isAscending = true
                        filters.enableDateFilter = false; filters.enableTimeFilter = false
                        filters.participationStatus = .all; filters.enableDistanceFilter = false
                        filters.maxDistanceKm = 10.0
                    }) { Text("Reset Defaults").frame(maxWidth: .infinity).foregroundColor(.red) }
                }
            }
            .navigationTitle(showSortOptions ? "Filters & Sort" : "Map Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.appGreen) } }
        }
    }
}
