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
    @State private var spotRatings: [String: Double] = [:] // Dictionary to store average ratings for spots
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
                            if let averageRating = spotRatings[spot.id ?? ""] {
                                HStack {
                                    Text("Rating: \(String(format: "%.1f", averageRating))")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
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
                    }
                    .buttonStyle(.bordered)
                    .padding()

                    Button("Sort by Proximity") {
                        sortSpotsByProximity()
                    }
                    .buttonStyle(.bordered)
                    .padding()

                    Button("Sort by Rating") {
                        sortSpotsByRating()
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
                        .onDisappear {
                            sortSpotsByProximity()
                        }
                }
            }
            .onAppear {
                sortSpotsByProximity()
                fetchRatingsForAllSpots() // Update ratings when the view appears
            }
            .onChange(of: spots) { _ in
                sortSpotsByProximity()
                fetchRatingsForAllSpots() // Update ratings when spots change
            }
        }
    }

    private func sortSpotsByProximity() {
        guard let userLocation = locationManager.currentLocation else {
            print("User location not available")
            return
        }

        sortedSpots = spots.sorted {
            let location1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
            let location2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
            return location1.distance(from: userLocation) < location2.distance(from: userLocation)
        }
        print("Sorted by Proximity:", sortedSpots.map { $0.name })
    }

    private func sortSpotsByRating() {
        sortedSpots = spots.sorted { spot1, spot2 in
            let rating1 = spotRatings[spot1.id ?? ""] ?? 0
            let rating2 = spotRatings[spot2.id ?? ""] ?? 0
            return rating1 > rating2 // Sort descending by rating
        }
        print("Sorted by Rating:", sortedSpots.map { $0.name })
    }

    private func calculateDistance(to spot: Spot) -> Double? {
        guard let userLocation = locationManager.currentLocation else {
            return nil
        }

        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        return distanceInMiles
    }

    private func fetchRatingsForAllSpots() {
        for spot in spots {
            fetchAverageRating(for: spot)
        }
    }

    private func fetchAverageRating(for spot: Spot) {
        let db = Firestore.firestore()

        db.collection("spots").document(spot.id ?? "").collection("reviews")
            .getDocuments { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching reviews: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let ratings = documents.compactMap { document -> Int? in
                    let data = document.data()
                    return data["rating"] as? Int
                }

                guard !ratings.isEmpty else {
                    print("No ratings found for this spot.")
                    return
                }

                let averageRating = Double(ratings.reduce(0, +)) / Double(ratings.count)
                DispatchQueue.main.async {
                    spotRatings[spot.id ?? ""] = averageRating
                }
                print("Average Rating for \(spot.name): \(averageRating)")
            }
    }
}



#Preview {
    NavigationStack {
        ListView()
            .environmentObject(LocationManager()) // Inject LocationManager as an environment object
    }
}




