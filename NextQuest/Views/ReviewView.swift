//
//  ReviewView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/26/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ReviewView: View {
    
    @State var spot: Spot
    @State var review: Review
    @State var postedByThisUser: Bool = false
    @State var rateOrReviewerString: String = "Click to Rate:"
    @StateObject var reviewVM = ReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            VStack(alignment: .leading) {
                Text(spot.name)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text(spot.address)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(rateOrReviewerString)
                .font(postedByThisUser ? .title2 : .subheadline)
                .bold(postedByThisUser)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal)
            HStack{
                StarsSelectionView(rating: $review.rating)
                    .disabled(!postedByThisUser)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), lineWidth: postedByThisUser ? 2:0)
                    }
            }
            .padding(.bottom)
            
            
            VStack(alignment: .leading) {
                Text("Review Title")
                    .bold()
                
                TextField("title", text:$review.title)
                    .padding(.horizontal, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), lineWidth: postedByThisUser ? 2:0.3)
                    }
                
                Text("Review")
                    .bold()
                
                TextField("review", text: $review.body, axis: .vertical)
                    .padding(.horizontal, 6)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: postedByThisUser ? 2:0.3))
                    }
            }
            .disabled(!postedByThisUser)
            .padding(.horizontal)
            .font(.title2)
            
            Spacer()
        }
        .onAppear{
            if review.reviewer == Auth.auth().currentUser?.email{
                postedByThisUser = true
            } else{
                let reviewPostedOn = review.postedON.formatted(date: .numeric, time: .omitted)
                rateOrReviewerString = "by: \(review.reviewer) on: \(reviewPostedOn)"
            }
        }
        .navigationBarBackButtonHidden(postedByThisUser) // Hide Back button
        .toolbar {
            if postedByThisUser {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancle") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task{
                            let success = await reviewVM.saveReview(spot: spot, review: review)
                            if success {
                                dismiss()
                            } else {
                                print("Error saving data in Review View")
                            }
                        }
                    }
                }
                
                if review.id != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button {
                            Task{
                                let success = await reviewVM.deleteReview(spot: spot, review: review)
                                if success {
                                    dismiss()
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }

                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReviewView(spot: Spot(name: "Test Loc 1", address: "123 Street"), review: Review())
    }
}
