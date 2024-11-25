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
    @State private var sortedSpots: [Spot] = [] // This will be the array to display the sorted spots
    @State private var sheetIsPresented: Bool = false
    @State private var spotRatings: [String: Double] = [:] // Dictionary to store average ratings for spots
    @State private var favoriteSpots: Set<String> = [] // Set of favorite spot IDs
    @State private var selectedSpot: Spot? // Store selected spot for favoriting
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager // Accessing LocationManager as an environment object
    
    @State private var currentUser: User? = Auth.auth().currentUser // Store current user
    @State private var showFavoritesOnly: Bool = false // Flag to show favorites only

    // Load favorite spots from Firebase on user login
    init() {
        _currentUser = State(initialValue: Auth.auth().currentUser)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // List of spots (either all spots or only favorite spots)
                List(sortedSpots) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot)
                            .onAppear {
                                self.selectedSpot = spot
                            }
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
                    .contextMenu {
                        // Context Menu to add to favorites
                        Button(action: {
                            toggleFavorite(spot)
                        }) {
                            Label("Favorite", systemImage: favoriteSpots.contains(spot.id ?? "") ? "heart.fill" : "heart")
                                .foregroundColor(favoriteSpots.contains(spot.id ?? "") ? .red : .gray)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("New Quests")
                .navigationBarTitleDisplayMode(.inline)

                // Sorting Buttons
                HStack {
                    Button("A-Z") {
                        sortSpotsByName()
                    }
                    .buttonStyle(.bordered)
                    .padding()

                    Button("Proximity") {
                        sortSpotsByProximity()
                    }
                    .buttonStyle(.bordered)
                    .padding()

                    Button("Rating") {
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
                    HStack {
                        Button(action: {
                            showFavoritesOnly.toggle() // Toggle between showing all spots or favorites only
                            sortSpots() // Reapply sorting after toggling favorites
                        }) {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart") // Filled heart if showing favorites
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 10)

                        Button {
                            sheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
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
                if let userId = currentUser?.uid {
                    loadFavorites(userId: userId) // Fetch favorites when the view appears
                }
                sortSpotsByProximity() // Default sorting by proximity
                fetchRatingsForAllSpots() // Update ratings when the view appears
            }
            .onChange(of: spots) {
                sortSpotsByProximity() // Sort whenever the list of spots changes
                fetchRatingsForAllSpots() // Update ratings when spots change
            }
            .onChange(of: favoriteSpots) {
                sortSpots() // Re-sort whenever favorites change
            }
        }
    }

    // Filtered spots that are either all spots or just favorites
    private var filteredSpots: [Spot] {
        if showFavoritesOnly {
            return spots.filter { favoriteSpots.contains($0.id ?? "") }
        } else {
            return spots
        }
    }

    // Sort the spots based on the selected sorting criteria
    private func sortSpots() {
        if let userLocation = locationManager.currentLocation {
            sortedSpots = filteredSpots.sorted {
                let location1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let location2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
        }
        print("Sorted by Proximity:", sortedSpots.map { $0.name })
    }

    // Sort by A-Z (alphabetical order)
    private func sortSpotsByName() {
        sortedSpots = filteredSpots.sorted { $0.name < $1.name }
        print("Sorted by A-Z:", sortedSpots.map { $0.name })
    }

    // Sort by Proximity
    private func sortSpotsByProximity() {
        sortSpots() // Sort by proximity after filtering
    }

    // Sort by Rating
    private func sortSpotsByRating() {
        sortedSpots = filteredSpots.sorted { spot1, spot2 in
            let rating1 = spotRatings[spot1.id ?? ""] ?? 0
            let rating2 = spotRatings[spot2.id ?? ""] ?? 0
            return rating1 > rating2 // Sort descending by rating
        }
        print("Sorted by Rating:", sortedSpots.map { $0.name })
    }

    private func loadFavorites(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let favorites = document.data()?["favoriteSpots"] as? [String] {
                    self.favoriteSpots = Set(favorites)
                }
            } else {
                print("Error loading favorites: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func saveFavorites(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "favoriteSpots": Array(favoriteSpots)
        ], merge: true) { error in
            if let error = error {
                print("Error saving favorites: \(error.localizedDescription)")
            } else {
                print("Favorites saved successfully!")
            }
        }
    }

    private func toggleFavorite(_ spot: Spot) {
        guard let spotId = spot.id else { return }
        
        if favoriteSpots.contains(spotId) {
            favoriteSpots.remove(spotId) // Unmark as favorite
        } else {
            favoriteSpots.insert(spotId) // Mark as favorite
        }

        if let userId = currentUser?.uid {
            saveFavorites(userId: userId) // Save updated favorites to Firestore
        }
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

