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
        ScrollView {
            VStack(spacing: 20) {
                
                // Spot Information Section
                VStack(alignment: .leading, spacing: 10) {
                    Text(spot.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(spot.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.leading, 0)

                
                Divider()
                    .padding(.horizontal, 20)
                
                // Rating Section
                Text(rateOrReviewerString)
                    .font(postedByThisUser ? .title3 : .body)
                    .fontWeight(.medium)
                    .foregroundColor(postedByThisUser ? .primary : .secondary)
                    .padding(.horizontal)
                
                HStack {
                    StarsSelectionView(rating: $review.rating)
                        .disabled(!postedByThisUser)
                        .padding(.horizontal)
                        .background(
                            postedByThisUser ?
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2) :
                            nil
                        )
                        .padding(.bottom, 10)
                }


                
                Divider()
                    .padding(.horizontal, 20)
                
                // Review Title Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Title")
                        .font(.headline)
                        .fontWeight(.medium)
                        .padding(.leading, 16)
                    
                    TextField("Enter review title", text: $review.title)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(postedByThisUser ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Add more space between Review Title and Body
                Spacer().frame(height: 24) // Add extra spacing here
                
                // Review Body Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review")
                        .font(.headline)
                        .fontWeight(.medium)
                        .padding(.leading, 16)
                    
                    TextEditor(text: $review.body)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .frame(minHeight: 150)
                        .shadow(radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(postedByThisUser ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .disabled(!postedByThisUser)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .onAppear {
                if review.reviewer == Auth.auth().currentUser?.email {
                    postedByThisUser = true
                } else {
                    let reviewPostedOn = review.postedON.formatted(date: .numeric, time: .omitted)
                    rateOrReviewerString = "by: \(review.reviewer) on: \(reviewPostedOn)"
                }
            }
        }
        .background(Color(UIColor.systemGray6)) // Slightly off-white background for modern touch
        .navigationTitle("Review")
        .navigationBarBackButtonHidden(postedByThisUser)
        .toolbar {
            if postedByThisUser {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveReview) {
                        Text("Save")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                if review.id != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button(action: deleteReview) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func saveReview() {
        Task {
            let success = await reviewVM.saveReview(spot: spot, review: review)
            if success {
                dismiss()
            } else {
                showError("Error saving data in Review View")
            }
        }
    }
    
    private func deleteReview() {
        Task {
            let success = await reviewVM.deleteReview(spot: spot, review: review)
            if success {
                dismiss()
            } else {
                showError("Error deleting review")
            }
        }
    }
    
    private func showError(_ message: String) {
        // Using an alert for error messages
        // Here you can add alert logic to inform the user of any errors.
        print(message)
    }
}

#Preview {
    NavigationStack {
        ReviewView(spot: Spot(name: "Test Loc 1", address: "123 Street"), review: Review())
    }
}
