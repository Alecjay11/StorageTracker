//
//  SettingsSidebarView.swift
//  StorageTracker
//
//  Created by Alec Newman on 4/25/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsSidebarView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: ProfileView()) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Profile")
                            .font(.title3)
                    }
                    .padding()
                }
                Spacer()

                Button(action: {
                    signOut()
                }) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                    .padding()
                }
                .padding(.bottom, 40)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            dismissAll()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func dismissAll() {
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.rootViewController?.dismiss(animated: true)
            }
        }
    }
}


#Preview {
    SettingsSidebarView(onDismiss: {})
}
