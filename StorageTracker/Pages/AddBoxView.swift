//
//  AddBoxView.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/24/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    var userID: String
    var existingBox: Box? = nil

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var shownImages: [Image] = []
    @State private var imageData: [Data] = []
    @State private var boxName: String = ""
    @State private var items: [String] = [""]
    @State private var expandedImage: Image?
    @State private var showExpandedImage = false
    @State private var hasLoadedImages = false
    @State private var selectedLocation: String = ""
    @State private var locationNotes: String = ""
    @State private var availableLocations: [String] = ["Basement", "Garage", "Attic"]
    @State private var isAddingNewLocation = false
    @State private var newLocationText: String = ""
    @State private var isShowingLocationPicker = false
    var isEditing: Bool {
        existingBox != nil
    }
    

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 4) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.gray.opacity(0.5))

                        TextField("Box Name", text: $boxName)
                            .font(.largeTitle)
                            .padding(.vertical, 8)
                            .multilineTextAlignment(.leading)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .padding(.horizontal)

                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.gray.opacity(0.5))
                        
                    }
                    

                    Text("Photos:")
                        .font(.headline)

                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem(.flexible())], spacing: 10) {
                            ForEach(shownImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    shownImages[index]
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .onTapGesture {
                                            expandedImage = shownImages[index]
                                            showExpandedImage = true
                                        }

                                    Button {
                                        shownImages.remove(at: index)
                                        imageData.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.7)))
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "plus")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                }
                            }
                            .onChange(of: selectedPhoto) {
                                Task {
                                    guard let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                                          let image = UIImage(data: data) else { return }
                                    imageData.append(data)
                                    shownImages.append(Image(uiImage: image))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                    
                    Group {
                        HStack(alignment: .center) {
                            Text("Location:")
                                .font(.headline)

                            Spacer(minLength: 10)

                            NavigationLink(destination: LocationPickerView(
                                availableLocations: $availableLocations,
                                selectedLocation: $selectedLocation
                            )) {
                                HStack {
                                    Text(selectedLocation.isEmpty ? "Select..." : selectedLocation)
                                        .foregroundColor(selectedLocation.isEmpty ? .gray : .blue)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                            }
                        }
                        

                        TextField("Location details (e.g. 'top shelf, under the fan')", text: $locationNotes)
                            .textFieldStyle(.roundedBorder)
                    }



                    Text("Items:")
                        .font(.headline)

                    VStack(spacing: 12) {
                        ForEach(items.indices, id: \.self) { index in
                            HStack {
                                TextField("Item", text: Binding(
                                    get: { items[index] },
                                    set: {
                                        items[index] = $0
                                        if index == items.count - 1 && !$0.isEmpty {
                                            items.append("")
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)

                                if !items[index].isEmpty {
                                    Button(action: {
                                        items.remove(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }

                        if items.isEmpty {
                            TextField("Item", text: Binding(
                                get: { "" },
                                set: { items.append($0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(existingBox == nil ? "Add Box" : "Edit Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveBoxToFirebase() }
                }
            }
            .sheet(isPresented: $showExpandedImage) {
                if let image = expandedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .onTapGesture { showExpandedImage = false }
                }
            }
            .onAppear {
    
                guard !hasLoadedImages, let box = existingBox else { return }
                boxName = box.name
                items = box.items
                selectedLocation = box.location
                locationNotes = box.locationNotes
                hasLoadedImages = true
                if items.last != "" {
                            items.append("")
                        }
                Task {
                    await loadImagesFromURLs(urls: box.photoURLs)
                }
            }
        }
    }

    func saveBoxToFirebase() {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let boxID = existingBox?.id ?? UUID().uuidString
        let boxRef = db.collection("users").document(userID).collection("boxes").document(boxID)

        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()

        for (index, data) in imageData.enumerated() {
            dispatchGroup.enter()
            let path = "users/\(userID)/boxes/\(boxID)/photo_\(index).jpg"
            let storageRef = storage.reference().child(path)

            storageRef.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                storageRef.downloadURL { url, _ in
                    if let url = url {
                        uploadedURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            let boxData: [String: Any] = [
                "name": boxName,
                "items": items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                "photoURLs": uploadedURLs,
                "timestamp": Timestamp(date: Date()),
                "location": selectedLocation,
                "locationNotes": locationNotes,
            ]

            boxRef.setData(boxData) { error in
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                } else {
                    dismiss()
                }
            }
        }
    }

    func loadImagesFromURLs(urls: [String]) async {
        for urlString in urls {
            print("🌐 Attempting to load image from: \(urlString)")
            guard let url = URL(string: urlString) else {
                print("❌ Invalid URL: \(urlString)")
                continue
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                print("📦 Got data from: \(urlString), size: \(data.count)")

                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        print("✅ Converted data into UIImage and added to shownImages")

                        imageData.append(data)
                        shownImages.append(Image(uiImage: uiImage))
                    }
                }else {
                    print("❌ Failed to convert data to UIImage")
                }
            } catch {
                print("Image load error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AddBoxView(userID: "123")
}
