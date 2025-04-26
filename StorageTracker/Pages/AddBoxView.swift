//
//  AddBoxView.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/24/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import PhotosUI
import Foundation

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

                        HStack {
                            TextField("Box Name", text: $boxName)
                                .font(.title)
                                .padding(.vertical, 8)
                                .multilineTextAlignment(.leading)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .padding(.horizontal)
                            Button(action: {
                                    suggestBoxName(from: items.filter { !$0.isEmpty }) { suggestedName in
                                        if let name = suggestedName {
                                            DispatchQueue.main.async {
                                                boxName = name
                                            }
                                        }
                                    }
                                }) {
                                    Image(systemName: "wand.and.sparkles")
                                        .padding(8)
                                }
                        }

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

                            NavigationLink(destination: LocationPickerView(availableLocations: $availableLocations, selectedLocation: $selectedLocation)) {
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
            .navigationBarBackButtonHidden()
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
                fetchAvailableLocations()
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

    func fetchAvailableLocations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching locations: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let locations = data["availableLocations"] as? [String] {
                availableLocations = locations
            } else {
                availableLocations = ["Basement", "Garage", "Attic"]
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
    

    func suggestBoxName(from items: [String], completion: @escaping (String?) -> Void) {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let prompt = "Suggest a short and simple storage box name based on these items: \(items.joined(separator: ", ")). Keep it max 3 words."

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a creative assistant that names storage boxes based on contents."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 20,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

                let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

                completion(cleaned)

            } else {
                print("Failed to parse response")
                completion(nil)
            }
        }.resume()
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
