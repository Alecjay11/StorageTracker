//
//  ContentView.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignInView: View {
    enum Field {
        case email, password
    }
    
    let Colors = [Color.darkBlue, Color.lightBlue]
    

    @State private var enteredEmail = ""
    @State private var enteredPass = ""
    @State private var signInMessage = ""
    @State private var isAuthenticated = false
    @State private var sheetIsPresented = false
    @State private var currentUser = User()
    @FocusState private var focusField: Field?
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "shippingbox.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundStyle(.lightBlue)
                    .padding(.top, 25.0)
                
                Text("Storage Tracker")
                    .font(.largeTitle)
                    .fontDesign(.monospaced)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                
                TextField("Email", text: $enteredEmail)
                    .textFieldStyle(.roundedBorder)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray, lineWidth: 1)
                    }
                    .frame(width: 300)
                    .padding(.bottom)
                    .padding(.top, 120)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusField, equals: .email)
                    .onSubmit {
                        focusField = .password
                    }
                
                SecureField("Password", text: $enteredPass)
                    .textFieldStyle(.roundedBorder)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray, lineWidth: 1)
                    }
                    .frame(width: 300)
                    .submitLabel(.done)
                    .focused($focusField, equals: .password)
                    .onSubmit {
                        focusField = nil
                    }
                
                Text(signInMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    NavigationLink(destination: {
                        RegisterView()
                    }, label: {
                        Text("Register")
                    })
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button("Sign In") {
                        login()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                
                Spacer()
            }
            .background(Gradient(colors: Colors))
        }
        
        .alert(signInMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            enteredEmail = ""
            enteredPass = ""
            signInMessage = ""
            if Auth.auth().currentUser != nil {
                sheetIsPresented = true
            }
        }
        .onChange(of: sheetIsPresented){
            enteredEmail = ""
            enteredPass = ""
            signInMessage = ""
        }
        .fullScreenCover(isPresented: $sheetIsPresented) {
            HomePageView()
        }
    }
    
    
    func login() {
        Auth.auth().signIn(withEmail: enteredEmail, password: enteredPass) { result, error in
            if let error = error {
                signInMessage = "Login Error: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            guard let uid = result?.user.uid else {
                signInMessage = "Unable to find user ID"
                showingAlert = true
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    signInMessage = "Failed to load user: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                guard let data = snapshot?.data() else {
                    signInMessage = "User data not found"
                    showingAlert = true
                    return
                }
                
                let boxData = data["boxes"] as? [[String: Any]] ?? []
                let decodedBoxes = boxData.compactMap { dict -> Box? in
                    guard
                        let id = dict["id"] as? String,
                        let name = dict["name"] as? String,
                        let items = dict["items"] as? [String]
                    else {
                        return nil
                    }
                    return Box(id: id, items: items, name: name)
                }

                currentUser = User(
                    UserID: uid,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    boxes: decodedBoxes
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    sheetIsPresented = true
                }
                
            }
        }
    }
}


#Preview {
    SignInView()
}
