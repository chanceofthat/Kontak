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
    
    struct MetUsers {
        var metUsers: [KONMetUser] = []
        var userIDs: [String] {
            get {
                return metUsers.flatMap({ (user: KONMetUser) -> String in
                    return user.userID
                })
            }
        }
        
        var count: Int {
            get {
                return metUsers.count
            }
        }
        
        func userForID(userID: String) -> KONMetUser? {
            for user in metUsers {
                if user.userID == userID {
                    return user
                }
            }
            return nil
        }
        
        func userIndexForUserID(userID: String) -> Int? {
            if let user = userForID(userID: userID) {
                return metUsers.index(of: user)
            }
            return nil
        }
    }

    // MARK: - Properties
    static let sharedInstance: KONUserManager = KONUserManager()
    
    var networkManager: KONNetworkManager!
    var locationManager: KONLocationManager!
    
    var meUser: KONMeUser!
    var nearbyUsers: [KONNearbyUser] = []
    
    var metUsers: MetUsers = MetUsers() {
        didSet {
           metControllerUpdateCallback?()
        }
    }
    
    var metControllerUpdateCallback: (() -> Void)?
    
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
        networkManager.updateDatabaseWithNewUser(user: meUser)
    }
    
    func updateMetUsersWithUserIDs(userIDs: [String]) {
        let newMetUserIDSet = Set(userIDs).subtracting(metUsers.userIDs)
        let deletedMetUserIDSet = Set(metUsers.userIDs).subtracting(userIDs)
        
        for userID in newMetUserIDSet {
            metUsers.metUsers.append(KONMetUser(userID: userID))
        }
        
        for userID in deletedMetUserIDSet {
            if let index = metUsers.userIndexForUserID(userID: userID) {
                metUsers.metUsers.remove(at: index)
            }
        }
    }
    
    // MARK: - Fake Data
    func createDummyNearbyUsers() {
        for user in 0..<10 {
            nearbyUsers.append(KONNearbyUser(firstName: "Nearby\(user)", lastName: nil))
        }
    }
    
    
    // MARK: - KONLocationManagerDelegate
    func didUpdateCurrentLocation(location: CLLocation) {
        meUser.location = KONUser.KONLocation(location: location)
        networkManager.updateLocationForUser(user: meUser)
    }
    
    
}
