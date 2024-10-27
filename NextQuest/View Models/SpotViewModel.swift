//
//  SpotViewModel.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import Foundation
import FirebaseFirestore

@MainActor

class SpotViewModel: ObservableObject {
    @Published var spot = Spot()
    
    
    func saveSpot(spot: Spot) async ->Bool {
        let db = Firestore.firestore()
        
        if let id = spot.id {
            do{
                try await db.collection("spots").document(id).setData(spot.dictionary)
                print("Data Update Successful")
                return true
            } catch {
                print("Couldnt Update spot: \(error.localizedDescription)")
                return false
            }
        } else{
            do{
               let documentRef = try await db.collection("spots").addDocument(data: spot.dictionary)
                self.spot = spot
                self.spot.id = documentRef.documentID
                print("Data Save Successful")
                return true
            }catch {
                print("Couldnt Save spot: \(error.localizedDescription)")
                return false
            }
        }
        
    }
}
