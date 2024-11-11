//
//  SpotReviewRowView.swift
//  NextQuest
//
//  Created by Samman Tyata on 11/6/24.
//

import SwiftUI

struct SpotReviewRowView: View {
    @State var review: Review
    var body: some View {
        VStack(alignment: .leading){
            Text(review.title)
                .font(.title2)
            HStack{
                StarsSelectionView(rating: $review.rating, interactive: false, font: .callout)
                Text(review.body)
                    .font(.callout)
                    .lineLimit(1)
            }
            
        }
    }
}

#Preview {
    SpotReviewRowView(review: Review(title: "Test", body: "Test", rating: 5))
}
