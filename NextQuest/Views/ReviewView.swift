//
//  ReviewView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/26/24.
//

import SwiftUI

struct ReviewView: View {
    
    @State var spot: Spot
    @State var review: Review
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
            
            Text("Click to Rate")
                .font(.title2)
                .bold()
            
            HStack{
                StarsSelectionView(rating: review.rating)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), lineWidth: 2)
                    }
            }
            .padding(.bottom)
            
            
            VStack(alignment: .leading) {
                Text("Review Title")
                    .bold()
                
                TextField("title", text:$review.title)
                    .textFieldStyle(.roundedBorder)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), lineWidth: 2)
                    }
                
                Text("Review")
                    .bold()
                
                TextField("review", text: $review.body, axis: .vertical)
                    .padding(.horizontal, 6)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2))
                    }
            }
            .padding(.horizontal)
            .font(.title2)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancle") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    
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
