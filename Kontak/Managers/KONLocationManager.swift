//
//  KONLocationManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import CoreLocation

protocol KONLocationManagerDelegate: class {
    func didUpdateCurrentLocation(locationHash: String)
}

private extension Double {
    var radians: Double {
        get {
            return (self * .pi / 180)
        }
    }
}

extension KONLocationManager {
    static func coordinatesFromLocationHash(hash: String) -> (Double, Double) {
        let coordinates = CLLocationCoordinate2D(geohash: hash)
        return (coordinates.latitude, coordinates.longitude)
    }
    
    static func adjustedCoordinatesForDelta(lat: Double, Lon: Double, delta: Double) -> (Double, Double) {
        let delta = delta/1000
        return((lat + (delta / 111.12)), (Lon + delta / fabs(cos(lat.radians) * 111.12)))
    }
}

class KONLocationManager: NSObject, CLLocationManagerDelegate {
    
    enum LocationManagerStatus {
        case notStarted, started, paused
    }

    // MARK: - Properties
    static let sharedInstance: KONLocationManager = KONLocationManager()
    
    var stateMachine = KONStateMachine()

    weak var delegate: KONLocationManagerDelegate?
    private var locationManager: CLLocationManager?
    private var lowPowerMode = false
    private var didRecentlyUpdateLocation = false
    var status: LocationManagerStatus = .notStarted
    
    var locationOverrideEnabled = false
    
    // Callbacks
//    var locationAvailableCallbacks: [(() -> Void)] = []
    var locationUpdatedCallbacks: [(() -> Void)] = []

    
    // MARK: - Init
    private override init() {
        super.init()
        
        // Set Up States
        
        // Not Started
        let stoppedState = KONState(name: "StoppedState", enterAction: nil)
        stoppedState.addTransition(KONStateTransition(action: stopLocationManager), fromStateName: "IdleState")
        stoppedState.addTransition(KONStateTransition(action: stopLocationManager), fromStateName: "UpdatingRegionState")
        stoppedState.addTransition(KONStateTransition(action: stopLocationManager), fromStateName: "UpdatingLocationState")
        stoppedState.addTransition(KONStateTransition(action: stopLocationManager), fromStateName: "PausedState")

        stateMachine.addState(state: stoppedState)
        
        // Idle State
        let idleState = KONState(name: "IdleState", enterAction: nil)
        idleState.addTransition(KONStateTransition(action: startLocationManager), fromStateName: "StoppedState")
        idleState.addTransition(KONStateTransition(action: requestLocation), fromStateName: "UpdatingRegionState")
        stateMachine.addState(state: idleState)
        
        // Updating Region
        let updatingRegionState = KONState(name: "UpdatingRegionState", enterAction: updateRegion)
        stateMachine.addState(state: updatingRegionState)
        
        // Updating Location
        let updatingLocationState = KONState(name: "UpdatingLocationState", enterAction: updateLocation)
        stateMachine.addState(state: updatingLocationState)
        
        // Paused
        
    }
    
    func start() {
        stateMachine.start()
        stateMachine.transitionToState(stateName: "IdleState")
    }
    
    func stop() {
        stateMachine.transitionToState(stateName: "StoppedState")
    }
    
    // MARK: Starting and Stopping Location Services
    func startLocationManager() {
        print("Starting Location Manager....")

        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        
        // Configure Location Manager
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager!.delegate = self
            locationManager?.pausesLocationUpdatesAutomatically = true
            locationManager?.activityType = CLActivityType.other

            if (CLLocationManager.authorizationStatus() == .notDetermined) {
                locationManager!.requestAlwaysAuthorization()
            }
            
            let currentAuthStatus = CLLocationManager.authorizationStatus()
            
            if currentAuthStatus == .authorizedAlways {
                print("Location Services Authorized Always")
                
                // If Significant Change Mode
                if lowPowerMode {
                    startInSigChangeMode()
                }
                else {
                    startInRegMonitorMode()
                }

            }
            else if currentAuthStatus == .authorizedWhenInUse {
                print("Location Serviecs Authorized When In Use")
                startInStandardMode()
            }
            else {
                print("Location Services Not Authorized")
                return
            }
            
        }
        else {
            // TODO: - Handle LocServices not enabled.
            print("Location Services Not Enabled")
        }
    }
    
    func stopLocationManager() {
        print("Stopping Location Manager....")

        status = .notStarted
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager?.stopUpdatingLocation()
        locationManager = nil
        
    }
    
    // MARK:- Sigificant Change Location Serivces
    func startInSigChangeMode() {
        print("Starting In Significant Change Mode")
        locationManager!.startMonitoringSignificantLocationChanges()
        if CLLocationManager.deferredLocationUpdatesAvailable() {
            locationManager?.allowDeferredLocationUpdates(untilTraveled: KONRegionRadius, timeout: TimeInterval(60))
        }
        status = .started
    }
    
    // MARK:- Region Monitoring Location Services
    func startInRegMonitorMode() {
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            startInSigChangeMode()
            return
        }
        
        print("Starting In Region Monitoring Mode")
        
        stateMachine.transitionToState(stateName: "UpdatingRegionState")

        status = .started
    }
    
    func updateRegion() {
        if let locationManager = locationManager {
            if let currentLocation = locationManager.location {
                let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                let region = CLCircularRegion(center: center, radius: KONRegionRadius, identifier: KONRegionIdentifier)
                locationManager.startMonitoring(for: region)
            }
            self.stateMachine.transitionToState(stateName: "IdleState")
        }
        else {
            stateMachine.transitionToState(stateName: "StoppedState")
        }
    }
    
    // MARK: - Standard Location Services
    func startInStandardMode() {
        print("Starting In Standard Mode")
        status = .started
    }
    
    // MARK: - Helpers
    func requestLocation() {
        if let locationManager = locationManager {
            didRecentlyUpdateLocation = false
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        }
    }
    
    func manuallySetLocationToHash(hash: String) {
        self.delegate?.didUpdateCurrentLocation(locationHash: hash)
        updateLocation()
    }
    
    func updateLocation() {
        didRecentlyUpdateLocation = true
        for callback in locationUpdatedCallbacks {
            callback()
        }
        locationManager?.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !didRecentlyUpdateLocation {
            if let latestLocation = locations.last {
//                let locationTimestamp = latestLocation.timestamp
                
//                if (abs(Int32(locationTimestamp.timeIntervalSinceNow)) < 15) {
                    print("LAT: \(latestLocation.coordinate.latitude), LONG: \(latestLocation.coordinate.longitude)")
                if locationOverrideEnabled == false {
                    self.delegate?.didUpdateCurrentLocation(locationHash: latestLocation.coordinate.geohash(length: 10))
                }

                
                    self.stateMachine.transitionToState(stateName: "UpdatingLocationState")
                
            
//                }
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        // TODO: - Handle pausing
        print("Did Pause Location Updates")
        status = .paused
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        // TODO: - Handle resuming
        print("Did Resume Location Updates")
        status = .started
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .denied && status != .restricted {
            if self.status == .notStarted {
                startLocationManager()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Did Start Monitoring Region: \(region)")
    }

    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did Exit Region")
        if let locationManager = locationManager {
            locationManager.stopMonitoring(for: region)
            stateMachine.transitionToState(stateName: "UpdatingRegionState")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did Fail, Error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region Monitoring Did Fail")
    }
}
