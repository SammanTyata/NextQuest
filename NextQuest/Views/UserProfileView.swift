//
//  UserProfileView.swift
//  NextQuest
//
//  Created by Samman Tyata on 12/3/24.
//

import SwiftUI
import FirebaseAuth

// User Profile View
struct UserProfileView: View {
    @State private var currentUser = Auth.auth().currentUser
    
    var body: some View {
        VStack {
            if let user = currentUser {
                Text("Welcome, \(user.displayName ?? "User")")
                    .font(.title)
                    .padding()
                
                Text("Email: \(user.email ?? "No email")")
                    .font(.subheadline)
                    .padding()
                
                // Additional user profile info can be displayed here
            } else {
                Text("User not logged in.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

#Preview {
    UserProfileView()
}
