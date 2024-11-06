//
//  ListView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct ListView: View {
    
    @FirestoreQuery(collectionPath: "spots") var spots: [Spot]
    @State private var sortedSpots: [Spot] = []
    @State private var sheetIsPresented: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager // Accessing LocationManager as an environment object
    
    var body: some View {
        NavigationStack {
            VStack {
                List(sortedSpots) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(spot.name)
                                .font(.title2)
                            if let distance = calculateDistance(to: spot) {
                                Text("\(String(format: "%.2f", distance)) miles away")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("New Quests")
                .navigationBarTitleDisplayMode(.inline)
                
                // Sorting Buttons
                HStack {
                    Button("Sort Alphabetically") {
                        sortedSpots = spots.sorted { $0.name < $1.name }
                        print("Sorted Alphabetically:", sortedSpots.map { $0.name })
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    
                    Button("Sort by Proximity") {
                        sortSpotsByProximity()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                            print("Logout Successful")
                            dismiss()
                        } catch {
                            print("Error: Sign Out Error")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                NavigationStack {
                    SpotDetailView(spot: Spot())
                }
            }
            .onAppear {
                sortSpotsByProximity() // Automatically sort by proximity when the view appears
            }
            .onChange(of: spots) { 
                sortSpotsByProximity() // Update sortedSpots when spots changes
            }
        }
    }
    
    private func sortSpotsByProximity() {
        guard let userLocation = locationManager.currentLocation else {
            print("User location not available")
            return
        }
        
        // Sort spots array based on proximity to user location
        sortedSpots = spots.sorted {
            let location1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
            let location2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
            return location1.distance(from: userLocation) < location2.distance(from: userLocation)
        }
        print("Sorted by Proximity:", sortedSpots.map { $0.name })
    }
    
    // Calculate distance from user location to a given spot in miles
    private func calculateDistance(to spot: Spot) -> Double? {
        guard let userLocation = locationManager.currentLocation else {
            return nil
        }
        
        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        return distanceInMiles
    }
}

#Preview {
    NavigationStack {
        ListView()
            .environmentObject(LocationManager()) // Inject LocationManager as an environment object
    }
}



