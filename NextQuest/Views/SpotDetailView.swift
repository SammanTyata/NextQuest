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

    @State var spot: Spot
    @State private var showPlaceLookupSheet = false
    @State private var mapRegion = MKCoordinateRegion()
    @State private var cameraPosition =  MKCoordinateRegion.self
    
    @State private var annotations: [Annotation] = []
    @Environment(\.dismiss) private var dismiss
    let regionSize = 500.0 //meters
    
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
                MapMarker(coordinate: annotation.coordinate)
            }
            .frame(height:250)
            .onChange(of: spot) {
                annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
                mapRegion.center = spot.coordinate
            }

            
//            Map{
//                // Add your map content here
//                ForEach(annotations) { annotation in
//                    Marker(annotation.name, coordinate: annotation.coordinate)
//                }
//            }.onChange(of: spot) {
//                annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
//                mapRegion.center = spot.coordinate
//            }
            
            Spacer()
        }
        .onAppear(){
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
            if spot.id == nil {
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
            }
        }
        .sheet(isPresented: $showPlaceLookupSheet) {
            PlaceLookupView(spot: $spot)
        }
    }
}


#Preview {
    
    NavigationStack {
        SpotDetailView(spot: Spot())
            .environmentObject(SpotViewModel())
            .environmentObject(LocationManager())
    }
   
}
