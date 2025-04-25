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
    @State private var shouldReload = false

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
                            Text(box.name)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("Settings tapped")
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheetIsPresented = true
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

                    return Box(id: doc.documentID, items: items, name: name, photoURLs: photoURLs)
                }

                currentUser = User(
                    UserID: uid,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    boxes: boxes
                )
            }
        }
    }
}


#Preview {
    HomePageView()
}
