//
//  LocationPickerView.swift
//  StorageTracker
//
//  Created by Alec Newman on 4/25/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
                    let trimmed = newLocationName.trimmingCharacters(in: .whitespaces)

                    if !trimmed.isEmpty {
                        if !availableLocations.contains(trimmed) {
                            availableLocations.append(trimmed)
                            availableLocations.sort()
                            saveAvailableLocations() 
                        }

                        selectedLocation = trimmed
                        newLocationName = ""
                        isAddingNewLocation = false
                    }
                }

                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    func saveAvailableLocations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "availableLocations": availableLocations
        ]) { error in
            if let error = error {
                print("Error saving available locations: \(error.localizedDescription)")
            } else {
                print("✅ Available locations updated in Firestore")
            }
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
