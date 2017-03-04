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

class KONLocationManager: NSObject, CLLocationManagerDelegate, KONStateControllerEvaluationObserver {
    
    enum LocationManagerStatus {
        case notStarted, started, paused
    }

    // MARK: - Properties
    static let sharedInstance: KONLocationManager = KONLocationManager()
    
    weak var delegate: KONLocationManagerDelegate?
    dynamic private var locationManager: CLLocationManager?
    private var latestLocation: CLLocation?
    dynamic var latestLocationHash: String?
    
    private var lowPowerMode = false
    private var didRecentlyUpdateLocation = false
    
    var status: LocationManagerStatus = .notStarted
    dynamic private var locationManagerStarted: Bool {
        get {
            return status == .started
        }
    }
    
    var locationOverrideEnabled = false
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {

    }
    
    // MARK: - State Controller
    
    func registerWithStateController() {
        let stateController = KONStateController.sharedInstance
        
        let locationManagerStartedTargetKey = KONTargetKeyInfo(targetName: self.className, key: #keyPath(KONLocationManager.locationManager), evaluationValue: true)
        let locationAvailableTargetKey = KONTargetKeyInfo(targetName: self.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: true)
        let locationAvailableRule = KONStateControllerRule(name: Constants.StateController.RuleNames.locationAvailableRule, targetKeys: [locationManagerStartedTargetKey, locationAvailableTargetKey])
        locationAvailableRule.ruleFailureCallback = {[weak self] (failingKey) in
            guard let `self` = self else { return }
            if failingKey == #keyPath(KONLocationManager.locationManager) {
                self.startLocationManager()
            }
            else {
                self.updateLocation()
            }
        }
        
        let meUserAvailableTargetKey = KONTargetKeyInfo(targetName: KONUserManager.className, key: #keyPath(KONUserManager.meUser), evaluationValue: true)
        let meUserAndLocationAvailableRule  = KONStateControllerRule(name: Constants.StateController.RuleNames.meUserAndLocationAvailableRule, targetKeys: [locationAvailableTargetKey, meUserAvailableTargetKey])
        
        meUserAndLocationAvailableRule.ruleSuccessCallback = {
            
        }
        
        stateController.registerRules(target: self, rules: [locationAvailableRule, meUserAndLocationAvailableRule])
 
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
    
    func manuallySetLocationToHash(hash: String) {
        self.delegate?.didUpdateCurrentLocation(locationHash: hash)
//        updateLocation()
    }
    
    func updateLocation() {
        if locationManager?.delegate == nil { return }
        if let locationManager = locationManager {
            didRecentlyUpdateLocation = false
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    //                let locationTimestamp = latestLocation.timestamp
    
    //                if (abs(Int32(locationTimestamp.timeIntervalSinceNow)) < 15) {

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !didRecentlyUpdateLocation {
            if let latestLocation = locations.last {
                print("LAT: \(latestLocation.coordinate.latitude), LONG: \(latestLocation.coordinate.longitude)")
                if locationOverrideEnabled == false {
                }
                self.latestLocation = latestLocation
                self.latestLocationHash = latestLocation.coordinate.geohash(length: 10)
                self.didRecentlyUpdateLocation = true
                self.locationManager?.stopUpdatingLocation()
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
    
    // MARK: - KONStateControllerEvaluationObserver Protocol
    func didEvaluateRule(ruleName: String, successful: Bool, context: [String : Any]?) {
//        print("Rule: \(ruleName), was \(successful ? "" : "not ")successful")
        
    }
}
