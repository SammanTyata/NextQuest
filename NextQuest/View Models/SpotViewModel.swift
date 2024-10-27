//
//  SpotViewModel.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import Foundation
import FirebaseFirestore

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
               try await db.collection("spots").addDocument(data: spot.dictionary)
                print("Data Save Successful")
                return true
            }catch {
                print("Couldnt Save spot: \(error.localizedDescription)")
                return false
            }
        }
        
    }
}
