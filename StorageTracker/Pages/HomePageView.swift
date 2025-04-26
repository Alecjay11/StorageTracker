//
//  HomePageView.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/17/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomePageView: View {
    @State private var currentUser: User = User()
    @State private var sheetIsPresented = false
    @State private var searchQuery: String = ""
    @State private var showingSettingsSidebar = false
    
    var filteredBoxes: [Box] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return currentUser.boxes
        } else {
            return currentUser.boxes.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.items.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hello, \(currentUser.firstName)")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 10)
                        .padding(.horizontal)
                    
                    TextField("Search boxes or items...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Text("Boxes")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(filteredBoxes, id: \.id) { box in
                            NavigationLink(destination: AddBoxView(userID: currentUser.UserID, existingBox: box)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(box.name)
                                        .font(.headline)
                                    
                                    if !box.location.isEmpty || !box.locationNotes.isEmpty {
                                        Text("📍 \(box.location)\(box.locationNotes.isEmpty ? "" : " — \(box.locationNotes)")")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .disabled(showingSettingsSidebar)
                .blur(radius: showingSettingsSidebar ? 3 : 0)
                
                if showingSettingsSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingSettingsSidebar = false
                            }
                        }
                    
                    SettingsSidebarView( onDismiss:  {
                        withAnimation {
                            showingSettingsSidebar = false
                        }
                    })
                    
                    .frame(width: UIScreen.main.bounds.width * 0.4)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .leading))
                    .zIndex(1)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            showingSettingsSidebar = true
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !showingSettingsSidebar{
                            sheetIsPresented = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $sheetIsPresented, onDismiss: {
                fetchCurrentUser()
            }) {
                AddBoxView(userID: currentUser.UserID)
            }
            .onAppear {
                fetchCurrentUser()
            }
        }
    }
    
    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching user info: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            
            var availableLocations = data["availableLocations"] as? [String] ?? ["Basement", "Garage", "Attic"]
            
            if data["availableLocations"] == nil {
                userRef.updateData([
                    "availableLocations": availableLocations
                ]) { error in
                    if let error = error {
                        print("Failed to save default locations: \(error.localizedDescription)")
                    } else {
                        print("✅ Default locations added to Firestore")
                    }
                }
            }
            
            userRef.collection("boxes").getDocuments { boxSnapshot, boxError in
                guard let boxDocs = boxSnapshot?.documents, boxError == nil else {
                    print("Error fetching boxes: \(boxError?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let boxes: [Box] = boxDocs.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let items = data["items"] as? [String] else { return nil }
                    
                    let photoURLs = data["photoURLs"] as? [String] ?? []
                    let location = data["location"] as? String ?? ""
                    let locationNotes = data["locationNotes"] as? String ?? ""
                    
                    return Box(
                        id: doc.documentID,
                        items: items,
                        name: name,
                        photoURLs: photoURLs,
                        location: location,
                        locationNotes: locationNotes
                    )
                }
                
                currentUser = User(
                    UserID: uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    boxes: boxes,
                    availableLocations: availableLocations
                )
            }
        }
    }
    
}


#Preview {
    HomePageView()
}
