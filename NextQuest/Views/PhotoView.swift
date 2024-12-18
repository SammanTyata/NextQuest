//
//  PhotoView.swift
//  NextQuest
//
//  Created by Samman Tyata on 11/14/24.
//

import SwiftUI
import FirebaseAuth

struct PhotoView: View {
    
    @EnvironmentObject var spotVM: SpotViewModel
    @Binding var photo: Photo
    //@State private var photo = Photo()
    var uiImage: UIImage
    var spot: Spot
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                
                Spacer()
                
                TextField("Description", text:$photo.description)
                    .textFieldStyle(.roundedBorder)
                
                Text("by: \(photo.reviewer) on: \(photo.postedOn.formatted(date: .numeric, time: .omitted))")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
            }
            .padding()
            .toolbar {
                if Auth.auth().currentUser?.email == photo.reviewer {
                    // Image was posted by current user
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button("Save") {
                            Task {
                                let success = await spotVM.saveImage(spot: spot, photo: photo, image: uiImage)
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    }
                } else {
                    // Image was NOT posted by current user
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }

            }
        }
    }
}

#Preview {
    PhotoView(photo: .constant(Photo()), uiImage: UIImage(named: "Test") ?? UIImage(), spot: Spot())
        .environmentObject(SpotViewModel())
}
