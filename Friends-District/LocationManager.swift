//
//  LocationManager.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit // Required for the new MKReverseGeocodingRequest APIs
internal import Combine

final class LocationManager: NSObject, ObservableObject {

    @Published var area = "Fetching..."
    @Published var address = ""

    private let manager = CLLocationManager()

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()

        case .denied, .restricted:
            area = "Location Disabled"
            address = "Enable location in Settings"

        default:
            break
        }
    }
    
    // 1. Handle incoming location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // 2. Wrap the modern async MapKit call inside a Task running on the Main Actor
        Task { @MainActor in
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            
            do {
                let mapItems = try await request.mapItems // Modern async lookup
                
                if let firstItem = mapItems.first, let representations = firstItem.addressRepresentations {
                    // Extract structured properties natively supported by MKAddressRepresentations
                    self.area = representations.cityName ?? "Unknown Area"
                    self.address = representations.fullAddress(includingRegion: true, singleLine: true) ?? ""
                } else {
                    self.area = "Unknown Location"
                    self.address = "No address details available."
                }
            } catch {
                self.area = "Error fetching"
                self.address = error.localizedDescription
            }
        }
    }
    
    // 3. CLLocationManager requires you to implement didFailWithError when using requestLocation()
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
