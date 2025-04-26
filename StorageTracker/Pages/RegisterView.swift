//
//  RegisterView.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "shippingbox.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .foregroundColor(.lightBlue)
                    .padding(.top, 30)

                Text("Create Account")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.bottom)

                Group {
                    
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

                Button(action: {
                    register()
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 10)

                Button(action: {
                    dismiss()
                }) {
                    Text("Already have an account? Sign In")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.top, 5)

                Spacer()
                Spacer()
            }
            
            .alert(errorMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Gradient(colors: [Color.darkBlue, Color.lightBlue])).ignoresSafeArea()
        }
    }

    func register() {
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill out all fields."
            showingAlert = true
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showingAlert = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = "Registration error: \(error.localizedDescription)"
                showingAlert = true
                return
            }

            guard let uid = authResult?.user.uid else { return }
            let db = Firestore.firestore()

            db.collection("users").document(uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "availableLocations": ["Basement", "Garage", "Attic"]
            ]) { error in
                if let error = error {
                    print("Error saving user info: \(error.localizedDescription)")
                } else {
                    print("✅ User registered and saved.")
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}

