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
    @State private var spotRatings: [String: Double] = [:]
    @State private var favoriteSpots: Set<String> = []
    @State private var selectedSpot: Spot?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @State private var currentUser: User? = Auth.auth().currentUser
    @State private var showFavoritesOnly: Bool = false

    init() {
        _currentUser = State(initialValue: Auth.auth().currentUser)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // List to display sorted spots
                List(sortedSpots) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot)
                            .onAppear {
                                self.selectedSpot = spot
                            }
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            // Spot Name with subtle styling
                            Text(spot.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            // Proximity and Rating in a smaller font
                            HStack {
                                if let distance = calculateDistance(to: spot) {
                                    Text("\(String(format: "%.2f", distance)) miles away")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let averageRating = spotRatings[spot.id ?? ""] {
                                    Text(String(format: "Avg Rating: %.1f", averageRating))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Avg Rating: NA")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 2)  // Half the usual left padding (16 -> 8)
                        .padding(.trailing)    // Keep full padding on the right
                        .background(Color.white)
                        .cornerRadius(4)
                        .listRowInsets(EdgeInsets()) // Removes default row padding
                    }
                    .contextMenu {
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
                
                VStack {
                    // Sorting Buttons at the bottom
                    HStack(spacing: 8) {
                        Button(action: { sortSpotsByName() }) {
                            Label("A-Z", systemImage: "a.circle.fill")
                                .lineLimit(1)  // Ensure text doesn't wrap
                                .minimumScaleFactor(0.8)  // Allow text to shrink to fit if necessary
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 120)  // Adjusted width to fit bigger text
                        .padding(.vertical)

                        Button(action: { sortSpotsByProximity() }) {
                            Label("Proximity", systemImage: "location.fill")
                                .lineLimit(1)  // Ensure text doesn't wrap
                                .minimumScaleFactor(0.8)  // Allow text to shrink to fit if necessary
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 120)  // Adjusted width to fit bigger text
                        .padding(.vertical)

                        Button(action: { sortSpotsByRating() }) {
                            Label("Rating", systemImage: "star.fill")
                                .lineLimit(1)  // Ensure text doesn't wrap
                                .minimumScaleFactor(0.8)  // Allow text to shrink to fit if necessary
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 120)  // Adjusted width to fit bigger text
                        .padding(.vertical)
                    }
                    .padding(.top,4)
                }



            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                            dismiss()
                        } catch {
                            print("Error: Sign Out Error")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showFavoritesOnly.toggle()
                            sortSpots()
                        }) {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 10)

                        Button(action: {
                            sheetIsPresented.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
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
                    loadFavorites(userId: userId)
                }
                sortSpotsByProximity()
                fetchRatingsForAllSpots()
            }
            .onChange(of: spots) {
                sortSpotsByProximity()
                fetchRatingsForAllSpots()
            }
            .onChange(of: favoriteSpots) {
                sortSpots()
            }
        }
    }

    private var filteredSpots: [Spot] {
        if showFavoritesOnly {
            return spots.filter { favoriteSpots.contains($0.id ?? "") }
        } else {
            return spots
        }
    }

    private func sortSpots() {
        if let userLocation = locationManager.currentLocation {
            sortedSpots = filteredSpots.sorted {
                let location1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let location2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
        }
    }

    private func sortSpotsByName() {
        sortedSpots = filteredSpots.sorted { $0.name < $1.name }
    }

    private func sortSpotsByProximity() {
        sortSpots()
    }

    private func sortSpotsByRating() {
        sortedSpots = filteredSpots.sorted { spot1, spot2 in
            let rating1 = spotRatings[spot1.id ?? ""] ?? 0
            let rating2 = spotRatings[spot2.id ?? ""] ?? 0
            return rating1 > rating2
        }
    }

    private func loadFavorites(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let favorites = document.data()?["favoriteSpots"] as? [String] {
                    self.favoriteSpots = Set(favorites)
                }
            }
        }
    }

    private func saveFavorites(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "favoriteSpots": Array(favoriteSpots)
        ], merge: true)
    }

    private func toggleFavorite(_ spot: Spot) {
        guard let spotId = spot.id else { return }
        
        if favoriteSpots.contains(spotId) {
            favoriteSpots.remove(spotId)
        } else {
            favoriteSpots.insert(spotId)
        }

        if let userId = currentUser?.uid {
            saveFavorites(userId: userId)
        }
    }

    private func calculateDistance(to spot: Spot) -> Double? {
        guard let userLocation = locationManager.currentLocation else {
            return nil
        }

        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        return distanceInMeters / 1609.34 // miles
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
                guard let documents = querySnapshot?.documents else { return }

                let ratings = documents.compactMap { document -> Int? in
                    let data = document.data()
                    return data["rating"] as? Int
                }

                guard !ratings.isEmpty else { return }

                let averageRating = Double(ratings.reduce(0, +)) / Double(ratings.count)
                DispatchQueue.main.async {
                    spotRatings[spot.id ?? ""] = averageRating
                }
            }
    }
}



#Preview {
    NavigationStack {
        ListView()
            .environmentObject(LocationManager())
    }
}
