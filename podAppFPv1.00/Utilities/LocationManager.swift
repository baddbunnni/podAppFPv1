//
//  LocationManager.swift
//  podAppFPv1.00
//
//  Created by S R on 5/22/26.
//


import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    @Published var latitude: String = "0"
    @Published var longitude: String = "0"
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        
        latitude = String(location.coordinate.latitude)
        longitude = String(location.coordinate.longitude)
    }
}
