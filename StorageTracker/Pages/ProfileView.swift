//
//  ProfileView.swift
//  StorageTracker
//
//  Created by Alec Newman on 4/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var loading = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPasswordFields = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 20) {
            if loading {
                ProgressView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("First Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)

                    Text("Last Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)

                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                }
                .padding()

                Button(action: {
                    saveChanges()
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        showingPasswordFields.toggle()
                    }
                }) {
                    Text(showingPasswordFields ? "Cancel Password Change" : "Change Password")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showingPasswordFields ? Color.gray : Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 5)

                if showingPasswordFields {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(.roundedBorder)

                        Text("Confirm New Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)

                        Button(action: {
                            saveNewPassword()
                        }) {
                            Text("Save New Password")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal)
                }
                
            }

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchProfile()
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    func fetchProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                email = data["email"] as? String ?? ""
                loading = false
            } else {
                alertMessage = "Failed to load profile."
                showingAlert = true
            }
        }
    }
    func saveNewPassword() {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please fill out both password fields."
            showingAlert = true
            return
        }

        guard newPassword == confirmPassword else {
            alertMessage = "Passwords do not match."
            showingAlert = true
            return
        }

        guard newPassword.count >= 6 else {
            alertMessage = "Password must be at least 6 characters."
            showingAlert = true
            return
        }

        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                alertMessage = "Error updating password: \(error.localizedDescription)"
            } else {
                alertMessage = "Password successfully updated!"
                newPassword = ""
                confirmPassword = ""
                showingPasswordFields = false
            }
            showingAlert = true
        }
    }


    func saveChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "firstName": firstName,
            "lastName": lastName,
            "email": email
        ]) { error in
            if let error = error {
                alertMessage = "Failed to save changes: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Profile updated!"
                showingAlert = true
            }
        }
    }
}
#Preview {
    ProfileView()
}
