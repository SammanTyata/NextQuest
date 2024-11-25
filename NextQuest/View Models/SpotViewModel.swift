//
//  SpotViewModel.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import Foundation
import FirebaseFirestore
import UIKit
import FirebaseStorage

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
    
    func saveImage(spot: Spot, photo: Photo, image: UIImage) async -> Bool{
        guard let spotID = spot.id else {
            print("Error: spot.id is nil")
            return false
        }
        
        var photoName = UUID().uuidString // Name of the image file.
        
        if photo.id != nil {
            photoName = photo.id! // I have a photo.id, so use this as the photoName. This happens if we're updating an existing Photo's descriptive info. It'll resave the photo, but that's OK. It'll just overwrite the existing one.
        }
        
        let storage = Storage.storage() // creates a firebase storage instance
        let storageRef = storage.reference().child("spots/\(spotID)/\(photoName).jpeg")
        
        //Compress the image
        guard let resizedImage = image.jpegData(compressionQuality: 0.2) else{
            print("Couldnt resize image")
            return false
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        var imageURLString = ""
        
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return false}
//
//                // Create a unique filename for the image
//                let filename = UUID().uuidString + ".jpg"
//                
//                // Reference to Firebase Storage
//                let storageRef = Storage.storage().reference().child("spots/\(spotID)/\(photoName).jpeg")
//                
//                // Upload image data to Firebase Storage
//                storageRef.putData(imageData, metadata: nil) { metadata, error in
//                    if let error = error {
//                        print("Failed to upload image: \(error)")
//                        return
//                    }
//                    
//                    print("Image uploaded successfully!")
//                    storageRef.downloadURL { url, error in
//                        if let error = error {
//                            print("Failed to get download URL: \(error)")
//                            return
//                        }
//                        
//                        if let url = url {
//                            print("Download URL: \(url.absoluteString)")
//                        }
//                    }
//                }
//        
        do {
            let _ = try await storageRef.putDataAsync(resizedImage, metadata: metadata)
            print("Image uploaded successfully")
            do {
                let imageURL = try await storageRef.downloadURL()
                imageURLString = "\(imageURL)"
            } catch {
                print("Couldnt get imageURL after upload \(error.localizedDescription)")
                      return false
            }
            
        }catch {
            print("Couldnt upload! \(error.localizedDescription)")
            return false
        }
        
        // Now save to the photos collection of the spot document "spotID"
        let db = Firestore.firestore()
        let collectionString = "spots/\(spotID)/photos"
        
        do{
            var newPhoto = photo
            newPhoto.imageURLString = imageURLString
            try await db.collection(collectionString).document(photoName).setData(newPhoto.dictionary)
            print("Photo saved successfully")
            return true
        }catch {
            print("Couldnt update data in 'photos' for spotID: \(spotID) \(error.localizedDescription)")
            return false
        }
        
    }
    
}
