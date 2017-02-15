//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import CoreLocation

class KONUserManager: NSObject, KONLocationManagerDelegate {

    // MARK: - Properties
    static let sharedInstance: KONUserManager = KONUserManager()
    
    var networkManager: KONNetworkManager!
    var locationManager: KONLocationManager!
    
    var meUser: KONMeUser!
    var nearbyUsers: [KONNearbyUser] = []
    var metUser: [KONMetUser] = []
    
    
    // MARK: - Init
    private override init() {
        super.init()
        
        // Init Me User
        populateMeUser()
        
        // Init Managers 
        networkManager = KONNetworkManager()
        locationManager = KONLocationManager()
        locationManager.delegate = self
        
        
        createDummyNearbyUsers()
        
        
    }
    
    func populateMeUser() {
        meUser = KONMeUser(firstName: "Chance", lastName: "Daniel")
    }
    
    func updateKONMeUserRecord() {
        networkManager.createNewUserDatbaseRecord(user: meUser)
    }
    
    // MARK: - Fake Data
    func createDummyNearbyUsers() {
        for user in 0..<10 {
            nearbyUsers.append(KONNearbyUser(firstName: "Nearby\(user)", lastName: nil))
        }
    }
    
    func queryForMetUsers() {
        networkManager.queryDatabaseForMetUserIDs()
    }
    
    // MARK: - KONLocationManagerDelegate
    func didUpdateCurrentLocation(location: CLLocation) {
        meUser.location = KONUser.KONLocation(location: location)
        networkManager.updateLocationRecordForUser(user: meUser)
    }
    
    
}
