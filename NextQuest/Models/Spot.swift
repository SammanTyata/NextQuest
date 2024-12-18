//
//  Spot.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct Spot: Identifiable, Codable, Equatable {
    enum SpotType: String, Codable {
        case outdoor = "Outdoor"
        case food = "Food"
    }
    
    @DocumentID var id: String?
    var name = ""
    var address = ""
    var latitude = 0.0
    var longitude = 0.0
    var type: SpotType = .outdoor  // Default type is Outdoor
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "address": address,
            "latitude": latitude,
            "longitude": longitude,
            "type": type.rawValue
        ]
    }
}
