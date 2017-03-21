//
//  KONLocationManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import CoreLocation

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

class KONLocationManager: NSObject, CLLocationManagerDelegate, KONStateControllable {
    
    enum LocationManagerStatus {
        case notStarted, started, paused
    }

    // MARK: - Properties
    static let sharedInstance: KONLocationManager = KONLocationManager()
    
    private let stateController = KONStateController.sharedInstance

    dynamic private var locationManager: CLLocationManager?
    private var latestLocation: CLLocation?
    dynamic var latestLocationHash: String?
    
    private var lowPowerMode = false
    
    var status: LocationManagerStatus = .notStarted
    dynamic private var locationManagerStarted: Bool {
        get {
            return status == .started
        }
    }
    
    var updateLocationContinuously = false
    
    // Diagnostic
    var overrideLocationHash: String? {
        didSet {
            self.updateLocation()
        }
    }
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {
        unregisterWithStateController()
    }
    
    // MARK: - State Controller
    
    func registerWithStateController() {
        
        let locationManagerStartedQuery = KONTargetKeyQuery(targetName: self.className, key: #keyPath(KONLocationManager.locationManager), evaluationValue: true)
        let locationAvailableQuery = KONTargetKeyQuery(targetName: self.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: true)
        let locationAvailableRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.locationAvailableRule, targetKeyQueries: [locationManagerStartedQuery, locationAvailableQuery], condition: .valuesCleared)
        
        locationAvailableRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
            if !successful {
                if let failedKeys = context?[Constants.StateController.RuleContextKeys.failedKeys] as? [String] {
                    if failedKeys.contains(#keyPath(KONLocationManager.locationManager)) {
                        self.startLocationManager()
                    }
                    else if (failedKeys.contains(#keyPath(KONLocationManager.latestLocationHash))) {
                        self.updateLocation()
                    }
                }
            }
        }
        
        stateController.registerRules(target: self, rules: [locationAvailableRule])
 
    }
    
    func unregisterWithStateController() {
        stateController.unregisterRulesForTarget(self)
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
    
        status = .started
        updateLocation()
    }
    
    func updateRegion() {
        if let locationManager = locationManager {
            if let currentLocation = locationManager.location {
                let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                let region = CLCircularRegion(center: center, radius: KONRegionRadius, identifier: KONRegionIdentifier)
                locationManager.startMonitoring(for: region)
            }

        }
        else {

        }
    }
    
    // MARK: - Standard Location Services
    func startInStandardMode() {
        print("Starting In Standard Mode")
        status = .started
    }
    
    // MARK: - Helpers
    
    func updateLocation() {
        if locationManager?.delegate == nil { return }
        if let locationManager = locationManager {
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latestLocation = locations.last {
            let lastUpdatedTime = latestLocation.timestamp.timeIntervalSinceNow
            
//            print("Update Time: \(abs(lastUpdatedTime))")
            if abs(lastUpdatedTime) < 1 {
//                print("LAT: \(latestLocation.coordinate.latitude), LONG: \(latestLocation.coordinate.longitude)")
                
                self.latestLocation = latestLocation
                if let overrideLocationHash = overrideLocationHash {
                    self.latestLocationHash = overrideLocationHash
                }
                else {
                    self.latestLocationHash = latestLocation.coordinate.geohash(length: 10)
                }
                if updateLocationContinuously == false {
                    self.locationManager?.stopUpdatingLocation()
                }
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

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did Fail, Error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region Monitoring Did Fail")
    }
    
}
