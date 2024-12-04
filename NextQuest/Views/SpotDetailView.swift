//
//  SpotDetailView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//
import SwiftUI
import MapKit
import FirebaseFirestore
import PhotosUI

struct SpotDetailView: View {
    
    enum ButtonPressed {
        case review, photo
    }
    
    struct Annotation: Identifiable {
        let id = UUID().uuidString
        var name: String
        var address: String
        var coordinate: CLLocationCoordinate2D
    }
    
    @EnvironmentObject var spotVM: SpotViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @FirestoreQuery(collectionPath: "spots") var reviews: [Review]
    @FirestoreQuery(collectionPath: "spots") var photos: [Photo]
    
    @State var spot: Spot
    @State var newPhoto = Photo()
    
    @State private var showPlaceLookupSheet = false
    @State private var showReviewViewSheet = false
    @State private var showPhotoViewSheet = false
    
    @State private var showSaveAlert = false
    @State private var showingAsSheet = false
    @State private var buttonPressed = ButtonPressed.review
   
    @State private var mapRegion = MKCoordinateRegion()
    @State private var cameraPosition = MKCoordinateRegion.self
    
    @State private var annotations: [Annotation] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var uiImageSelected = UIImage()
    
    private let spotTypes: [Spot.SpotType] = [.outdoor, .food] // Spot types as Spot.SpotType enum
    
    var avgRating: String {
        guard reviews.count != 0 else {
            return "-.-"
        }
        let averageValue = Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
        return String(format: "%.1f", averageValue)
    }
    
    @Environment(\.dismiss) private var dismiss
    let regionSize = 500.0 // meters
    var previewRunning = false
    
    var body: some View {
        VStack {
            Group {
                TextField("Name", text: $spot.name)
                    .font(.body)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.blue.opacity(0.5), lineWidth: 1)
                            .opacity(0)
                    )

                TextField("Address", text: $spot.address)
                    .font(.subheadline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.blue.opacity(0.5), lineWidth: 1)
                            .opacity(0)
                    )

                Picker("Type", selection: $spot.type) {
                    ForEach(spotTypes, id: \.self) { type in
                        Text(type.rawValue)
                            .font(.footnote)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)  // Ensures the Picker stretches and aligns to the left
                .padding([.leading, .trailing], 16)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.blue.opacity(0.5), lineWidth: 1)
                        .opacity(0)
                )
            }
            .disabled(spot.id == nil ? false : true)
            .padding(.horizontal)
            
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
            }
            .frame(height: 250)
            .onChange(of: spot) {
                annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
                mapRegion.center = spot.coordinate
            }
            
            HStack {
                Group {
                    Text("Average Rating:")
                        .font(.subheadline)
                        .bold()
                    Text(avgRating)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(Color("NextQuestColor"))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                
                Spacer()
                
                Group {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .automatic) {
                        Image(systemName: "photo")
                        Text("Photo")
                    }
                    .onChange(of: selectedPhoto) {
                        Task{
                            do{
                                if let data = try await selectedPhoto?.loadTransferable(type: Data.self){
                                    if let uiImage = UIImage(data: data){
                                        uiImageSelected = uiImage
                                        print("Successfully selected image!")
                                        buttonPressed = .photo
                                        if spot.id == nil {
                                            showSaveAlert.toggle()
                                        } else{
                                            showPhotoViewSheet.toggle()
                                        }
                                    }
                                }
                            } catch{
                                print("Error loading image: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    Button(action: {
                        buttonPressed = .review
                        if spot.id == nil {
                            showSaveAlert.toggle()
                        } else {
                            showReviewViewSheet.toggle()
                        }
                    }, label: {
                        Image(systemName: "star.fill")
                        Text("Rate")
                    })
                }
                .font(Font.caption)
                .buttonStyle(.borderedProminent)
                .tint(Color("NextQuestColor"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .padding(.horizontal)
            
            SpotDetailPhotosScrollView(photos: photos, spot: spot)
            
            List {
                Section {
                    ForEach(reviews) { review in
                        NavigationLink {
                            ReviewView(spot: spot, review: review)
                        } label: {
                            SpotReviewRowView(review: review)
                        }
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(.plain)
            Spacer()
            
            // "Open in Maps" button only if spot is saved (spot.id != nil)
            if spot.id != nil {
                Button(action: openInMaps) {
                    Label("Open in Maps", systemImage: "map")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            Task {
                if !previewRunning && spot.id != nil {
                    $reviews.path = "spots/\(spot.id ?? "")/reviews"
                    print("reviews.path = \($reviews.path)")
                    
                    $photos.path = "spots/\(spot.id ?? "")/photos"
                    print("photos.path = \($photos.path)")
                } else {
                    showingAsSheet = true
                }
                
                if spot.id != nil {
                    mapRegion = MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
                } else {
                    Task{
                        mapRegion = MKCoordinateRegion(center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(), latitudinalMeters: regionSize, longitudinalMeters: regionSize)
                    }
                }
                annotations = [Annotation(name: spot.name, address: spot.address, coordinate: spot.coordinate)]
            }
        }
        
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(spot.id == nil)
        .toolbar {
            if showingAsSheet {
                if spot.id == nil && showingAsSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                let success = await spotVM.saveSpot(spot: spot)
                                if success {
                                    dismiss()
                                } else {
                                    print("Error saving spot")
                                }
                            }
                        }
                        .disabled(spot.name.isEmpty || spot.address.isEmpty)
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
                } else if showingAsSheet && spot.id != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
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
        .sheet(isPresented: $showPhotoViewSheet) {
            NavigationStack{
                PhotoView(photo: $newPhoto, uiImage: uiImageSelected, spot: spot)
            }
        }
        .alert("Cannot rate unless Saved", isPresented: $showSaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Save", role: .none) {
                Task {
                    let success = await spotVM.saveSpot(spot: spot)
                    spot = spotVM.spot
                    if success {
                        $reviews.path = "spots/\(spot.id ?? "")/reviews"
                        $photos.path = "spots/\(spot.id ?? "")/photos"
                        
                        switch buttonPressed {
                        case .review:
                            showReviewViewSheet.toggle()
                        case .photo:
                            showPhotoViewSheet.toggle()
                        }
                    } else {
                        print("Error saving Spot")
                    }
                }
            }
        } message: {
            Text("Please save the spot before rating")
        }
    }
    
    private func openInMaps() {
        let latitude = spot.coordinate.latitude
        let longitude = spot.coordinate.longitude
        let locationName = spot.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Location"
        let address = spot.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(locationName),\(address)"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
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

