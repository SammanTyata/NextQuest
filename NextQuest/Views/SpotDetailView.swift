//
//  SpotDetailView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//

import SwiftUI
import MapKit
import FirebaseFirestore


struct SpotDetailView: View {
    struct Annotation: Identifiable{
        let id = UUID().uuidString
        var name: String
        var address: String
        var coordinate: CLLocationCoordinate2D
    }
    
    @EnvironmentObject var spotVM: SpotViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @FirestoreQuery(collectionPath: "spots") var reviews: [Review]

    @State var spot: Spot
    @State private var showPlaceLookupSheet = false
    @State private var showReviewViewSheet = false
    @State private var showingAsSheet = false
    @State private var showSaveAlert = false
    @State private var mapRegion = MKCoordinateRegion()
    @State private var cameraPosition =  MKCoordinateRegion.self
    
    @State private var annotations: [Annotation] = []
    var avgRating: String {
        guard reviews.count != 0 else
        {
            return "-.-"
        }
        let averageValue = Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
        return String(format: "%.1f", averageValue)
    }
    
    @Environment(\.dismiss) private var dismiss
    let regionSize = 500.0 //meters
    var previewRunning = false
    
    var body: some View {
        VStack{
            Group {
                TextField("Name", text: $spot.name)
                    .font(.title)
                
                TextField("Address", text: $spot.address)
                    .font(.title2)
            }
            .disabled(spot.id == nil ? false: true)
            .textFieldStyle(.roundedBorder)
            .overlay{
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.gray.opacity(0.5), lineWidth: spot.id == nil ? 2: 0)
                    
            }
            .padding(.horizontal)
            
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate){
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
                //MapMarker(coordinate: annotation.coordinate)
            }
            .frame(height:250)
            .onChange(of: spot) {
                annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
                mapRegion.center = spot.coordinate
            }
            
            List{
                Section{
                    ForEach(reviews){ review in
                        NavigationLink {
                            ReviewView(spot: spot, review: review)
                        } label: {
                            SpotReviewRowView(review: review)
                        }

                    }
                }header:{
                    HStack{
                        Text("Average Rating:")
                            .font(.title2)
                            .bold()
                        Text(avgRating) // Need to change to a computed value later
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(Color("NextQuestColor"))
                        Spacer()
                        Button("Rate it"){
                            // Add coode heere later
                            if spot.id == nil{
                                showSaveAlert.toggle()
                            }else{
                                showReviewViewSheet.toggle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .bold()
                        .tint(Color("NextQuestColor"))
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(.plain)
            Spacer()
        }
        .onAppear(){
            if !previewRunning && spot.id != nil{
                $reviews.path = "spots/\(spot.id ?? "")/reviews"
                print("reviews.path = \($reviews.path)")
            } else{
                showingAsSheet = true
            }
           
            if spot.id != nil { // If we have a spot, center map on the spot
                mapRegion = MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
            } else { //otherwise center the map on device location
                Task { // If not embedded in a Task, the map update wont show
                    mapRegion = MKCoordinateRegion(center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(), latitudinalMeters: regionSize, longitudinalMeters: regionSize)
                }
            }
            annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
        }
        .navigationBarTitleDisplayMode(.inline)
        
        .navigationBarBackButtonHidden(spot.id == nil)
        .toolbar {
            if showingAsSheet { // New Spot so show Cancle and Save buttons
                if spot.id == nil && showingAsSheet{
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            //add Save code Here
                            Task{
                                let success = await spotVM.saveSpot(spot: spot)
                                if success{
                                    dismiss()
                                } else{
                                    print("Error saving spot")
                                }
                            }
                            dismiss()
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button {
                            showPlaceLookupSheet.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                            Text("Search Place")
                        }
                    }
                } else if showingAsSheet && spot.id != nil{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button ("Done"){
                            dismiss()
                        }
                    }
                    
                }
            
            }
        }
        .sheet(isPresented: $showPlaceLookupSheet) {
            PlaceLookupView(spot: $spot)
        }
        .sheet(isPresented: $showReviewViewSheet) {
            NavigationStack {
                ReviewView(spot: spot, review: Review())
            }
        }

        .alert("Cannot rate unless Saved", isPresented: $showSaveAlert) {
            Button("Cancle", role: .cancel){}
            Button("Save", role: .none){
                Task{
                    let success = await spotVM.saveSpot(spot: spot)
                    spot = spotVM.spot
                    if success{
                        // if not updated after saving the spot, wont be able to show new reviews
                        $reviews.path = "spots/\(spot.id ?? "")/reviews"
                        showReviewViewSheet.toggle()
                    }else{
                        print("Error saving Spot")
                    }
                }
            }
        } message: {
            Text("Please save the spot before rating")
        }

    }
}


#Preview {
    
    NavigationStack {
        SpotDetailView(spot: Spot(), previewRunning: true)
            .environmentObject(SpotViewModel())
            .environmentObject(LocationManager())
    }
   
}
