//
//  PlaceLookupView.swift
//  PlaceLookupDemo
//
//  Created by Samman Tyata on 10/25/24.
//

import SwiftUI
import MapKit

struct PlaceLookupView: View {
    
    @EnvironmentObject var locationManager: LocationManager
    @StateObject var placeVM = PlaceViewModel()
    @State private var searchText = ""
    @Binding var spot: Spot
    @Environment(\.dismiss) private var dismiss
    
    //dummy data to work with
    //var places = ["Here", "There", "Everywhere"]
    var body: some View {
        NavigationStack {
            List(placeVM.places) { place in
                VStack(alignment: .leading) {
                    Text(place.name)
                        .font(.title2)
                    Text(place.address)
                        .font(.callout)
                }
                .onTapGesture {
                    spot.name = place.name
                    spot.address = place.address
                    spot.latitude = place.latitude
                    spot.longitude = place.longitude
                    dismiss()
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                if !searchText.isEmpty {
                    placeVM.search(text: searchText, region: locationManager.region)
                } else {
                    placeVM.places = []
                }
            }
            .toolbar{
                ToolbarItem(placement: .automatic) {
                    Button("Dismiss"){
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlaceLookupView(spot: .constant(Spot()))
        .environmentObject(LocationManager())
}
