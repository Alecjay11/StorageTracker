//
//  LocationPickerView.swift
//  StorageTracker
//
//  Created by Alec Newman on 4/25/25.
//

import SwiftUI

struct LocationPickerView: View {
    @Binding var availableLocations: [String]
    @Binding var selectedLocation: String
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingNewLocation = false
    @State private var newLocationName = ""

    var body: some View {
        List {
            Section(header: Text("Select a Location")) {
                ForEach(availableLocations, id: \.self) { location in
                    Button {
                        selectedLocation = location
                        dismiss()
                    } label: {
                        HStack {
                            Text(location)
                            if selectedLocation == location {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            Section {
                Button("➕ Add New Location") {
                    isAddingNewLocation = true
                }
            }
        }
        .navigationTitle("Choose Location")
        .sheet(isPresented: $isAddingNewLocation) {
            VStack(spacing: 20) {
                Text("Add a New Location")
                    .font(.title2)
                TextField("Location Name", text: $newLocationName)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Add Location") {
                    if !newLocationName.trimmingCharacters(in: .whitespaces).isEmpty {
                        availableLocations.append(newLocationName)
                        selectedLocation = newLocationName
                        newLocationName = ""
                        isAddingNewLocation = false
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}


#Preview {
    NavigationStack {
            LocationPickerView(
                availableLocations: .constant(["Basement", "Garage", "Attic"]),
                selectedLocation: .constant("Garage")
            )
        }
}
