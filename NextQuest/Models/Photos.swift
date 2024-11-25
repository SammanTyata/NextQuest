//
//  Photos.swift
//  NextQuest
//
//  Created by Samman Tyata on 11/14/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct Photo: Identifiable, Codable {
    @DocumentID var id: String?
    var imageURLString = ""  // Hold URL for the image
    var description: String = ""
    var reviewer = Auth.auth().currentUser?.email ?? ""
    var postedOn = Date()
    
    var dictionary: [String: Any] {
        return [
            "imageURLString": imageURLString,
            "description": description,
            "reviewer": reviewer,
            "postedOn": Timestamp(date: Date())
        ]
    }
    
}
