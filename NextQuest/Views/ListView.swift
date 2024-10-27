//
//  ListView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ListView: View {
    
    @FirestoreQuery(collectionPath: "spots") var spots: [Spot]
    @State private var sheetIsPresented: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(spots) {
                spot in NavigationLink {
                    SpotDetailView(spot: spot)
                } label: {
                    Text(spot.name)
                        .font(.title2)
                }
                
            }
            .listStyle(.plain)
            //.navigationBarBackButtonHidden() //no more needed
            .navigationTitle("New Quests")
            
            //Testing the wierd animation here
            
            //.navigationBarTitleDisplayMode(.large)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        do
                        {
                            try Auth.auth().signOut()
                            print("Logout Successful")
                            dismiss()
                        }
                        catch{
                            print("Error: Sign Out Error")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        //TODO Add item code here
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }.sheet(isPresented: $sheetIsPresented) {
                NavigationStack{
                    SpotDetailView(spot: Spot())
                }
            }
        }
       
    }
}

#Preview {
    NavigationStack{
        ListView()
    }
}
