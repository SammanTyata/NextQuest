//
//  StarsSelectionView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/26/24.
//

import SwiftUI

struct StarsSelectionView: View {
    
    @Binding var rating: Int
    @State var interactive = true
    let higherRating = 5
    let unselected = Image(systemName: "star")
    let selected = Image(systemName: "star.fill")
    var font: Font = .title // Adjusted font size to make stars smaller
    let fillColor: Color = .red
    let emptyColor: Color = .gray
    
    var body: some View {
        HStack{
            ForEach(1...higherRating, id: \.self) { number in
                showStar(for: number)
                    .foregroundColor(number <= rating ? fillColor : emptyColor)
                    .onTapGesture {
                        if interactive {
                            rating = number
                        }
                    }
            }
            .font(font)
        }
    }
    
    func showStar(for number: Int) -> Image {
        if number > rating {
            return unselected
        } else {
            return selected
        }
    }
}

#Preview {
    StarsSelectionView(rating:.constant(4))
}
