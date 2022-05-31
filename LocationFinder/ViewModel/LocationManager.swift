//
//  LocationManager.swift
//  LocationFinder
//
//  Created by Sopnil Sohan on 22/4/22.
//

import SwiftUI
import CoreLocation
import MapKit
// MARK: Combine Framwork to watch TextFild Change
import Combine

class LocationManager: NSObject,ObservableObject,MKMapViewDelegate,CLLocationManagerDelegate {
    // MARK: - Properties
    @Published var mapView: MKMapView = .init()
    @Published var manager: CLLocationManager = .init()
    
    //MARK: Search bar text
    @Published var searchText: String = ""
    var cancellable: AnyCancellable?
    @Published var fetchedPlaces: [CLPlacemark]?
    
    //MARK: User Location
    @Published var userLocation: CLLocation?
    
    //MARK: Final Location
    @Published var pickedLocation: CLLocation?
    @Published var pickedPlaceMark: CLPlacemark?
    
    override init() {
        super.init()
        //MARK: Setting Deligate
        manager.delegate = self
        mapView.delegate = self
        
        // MARK: Requesting Location Access
        manager.requestWhenInUseAuthorization()
        
        // MARK: Search TextFild Watching
        cancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { value in
                if value != "" {
                    self.fetchPlaces(value: value)
                } else {
                    self.fetchedPlaces = nil
                }
            })
    }
    
    func fetchPlaces(value: String) {
       //MARK: Fetching places using MKLocationSearch & Async/Await
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = value.lowercased()
                
                let response = try await MKLocalSearch(request: request).start()
                
                //WE can also use MainActor to published change in main thread
                await MainActor.run(body: {
                    self.fetchedPlaces = response.mapItems.compactMap({ item -> CLPlacemark? in
                        return item.placemark
                    })
                })
            } catch {
                //HANDLE ERROR
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //Handle Error
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else{return}
        self.userLocation = currentLocation
    }
    
    //MARK: Location Authorization
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways: manager.requestLocation()
        case .authorizedWhenInUse: manager.requestLocation()
        case .denied: handleLocationError()
        case .notDetermined: manager.requestWhenInUseAuthorization()
        default: ()
        }
    }
        
    func handleLocationError() {
        // HANDLE ERROR
    }
    
    //MARK: Add Draggable pin to Map View
    func addDraggablePin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Food will be delivered here"
        
        mapView.addAnnotation(annotation)
        
    }
    
    //MARK: Enabling Dragging
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "DELIVERYPIN")
        marker.isDraggable = true
        marker.canShowCallout = false
        
        return marker
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let newLocation = view.annotation?.coordinate else{return}
        self.pickedLocation = .init(latitude: newLocation.latitude, longitude: newLocation.longitude)
        updatePlacemark(location: .init(latitude: newLocation.latitude, longitude: newLocation.longitude))
    }
    
    func updatePlacemark(location: CLLocation) {
        Task {
            do {
                guard let place = try await reverseLocationCoordinates(location: location) else {return}
                await MainActor.run(body: {
                    self.pickedPlaceMark = place
                })
            } catch {
                //Handle Error
            }
        }
    }
    
    //MARK: Displaying New Location Data
    func reverseLocationCoordinates(location: CLLocation)async throws->CLPlacemark?{
        let place = try await CLGeocoder().reverseGeocodeLocation(location).first
        return place
    }
}


