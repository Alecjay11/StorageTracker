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
    enum ErrorType: String, CaseIterable {
        case notSamePassword = "Passwords do not match"
        case invalidEmail = "Invalid email format"
        case emptyFields = "All fields must be filled"
        case noError = ""
    }

    @Environment(\.dismiss) private var dismiss
    @State private var fName: String = ""
    @State private var lName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    @State private var errorMessage = ""
    @State private var showingAlert = false

    var body: some View {
        List {
            Group {
                textField(label: "First Name", binding: $fName)
                textField(label: "Last Name", binding: $lName)
                textField(label: "Email", binding: $email)
                secureField(label: "Password", binding: $password)
                secureField(label: "Confirm Password", binding: $passwordConfirm)
            }
            .listRowSeparator(.hidden)

            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(height: 40, alignment: .center)
        }
        .listStyle(.plain)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Create Account") {
                    register()
                }
            }
        }
        .alert("Registration Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    func textField(label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .foregroundStyle(.black.opacity(0.75))
            TextField("", text: binding)
                .textFieldStyle(.roundedBorder)
                .frame(width: 218)
        }
    }

    func secureField(label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .foregroundStyle(.black.opacity(0.75))
            SecureField("", text: binding)
                .textFieldStyle(.roundedBorder)
                .frame(width: 218)
        }
    }

    func register() {
        let error = properReg()
        if error != .noError {
            errorMessage = error.rawValue
            showingAlert = true
            return
        }

        // 🔐 Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { result, authError in
            if let authError = authError {
                errorMessage = "Auth Error: \(authError.localizedDescription)"
                showingAlert = true
                return
            }

            guard let userID = result?.user.uid else {
                errorMessage = "User ID not found"
                showingAlert = true
                return
            }

            // 🧠 Firebase Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "firstName": fName,
                "lastName": lName,
                "email": email
            ]

            db.collection("users").document(userID).setData(userData) { firestoreError in
                if let firestoreError = firestoreError {
                    errorMessage = "Firestore Error: \(firestoreError.localizedDescription)"
                    showingAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }

    func properReg() -> ErrorType {
        if fName.isEmpty || lName.isEmpty || email.isEmpty || password.isEmpty || passwordConfirm.isEmpty {
            return .emptyFields
        } else if password != passwordConfirm {
            return .notSamePassword
        } else if !email.contains("@") {
            return .invalidEmail
        }
        return .noError
    }
}


#Preview {
    RegisterView()
}
