//
//  ReviewViewModel.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/26/24.
//

import Foundation
import Foundation
import FirebaseFirestore

class ReviewViewModel: ObservableObject {
    @Published var spot = Review()
    
    
    func saveReview(spot: Spot, review: Review) async ->Bool {
        let db = Firestore.firestore()
        
        guard let spotID = spot.id else {
            print("Error: spot id = nil")
            return false
        }
        
        let collectionString = "spots/\(spotID)/reviews"
        
        if let id = review.id {
            do{
                try await db.collection(collectionString).document(id).setData(review.dictionary)
                print("Review Update Successful")
                return true
            } catch {
                print("Couldnt Update Review: \(error.localizedDescription)")
                return false
            }
        } else{
            do{
                try await db.collection(collectionString).addDocument(data: review.dictionary)
                print("Review Save Successful")
                return true
            }catch {
                print("Couldnt Save Review: \(error.localizedDescription)")
                return false
            }
        }
        
    }
}
