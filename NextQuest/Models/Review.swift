//
//  Review.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/26/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct Review: Identifiable,Codable{
    @DocumentID var id: String?
    var title = ""
    var body = ""
    var rating = 0
    var reviewer = ""
    var postedON: Date = Date()
    
    var dictionary: [String: Any] {
        return [
            "title": title,
            "body": body,
            "rating": rating,
            "reviewer": Auth.auth().currentUser?.email ?? "",
            "postedON": Timestamp(date: Date())
        ]
    }
}

