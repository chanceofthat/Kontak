//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
//import CoreLocation

class KONUserManager: NSObject, KONLocationManagerDelegate {
    
    struct MetUsers {
        var users: [KONMetUser] = []
        var userIDs: [String] {
            get {
                return users.flatMap({ (user: KONMetUser) -> String in
                    return user.userID
                })
            }
        }
        
        var count: Int {
            get {
                return users.count
            }
        }
        
        func userForID(userID: String) -> KONMetUser? {
            for user in users {
                if user.userID == userID {
                    return user
                }
            }
            return nil
        }
        
        func userIndexForUserID(userID: String) -> Int? {
            if let user = userForID(userID: userID) {
                return users.index(of: user)
            }
            return nil
        }
    }

    // MARK: - Properties
    static let sharedInstance: KONUserManager = KONUserManager()
    
    lazy var networkManager: KONNetworkManager = KONNetworkManager.sharedInstance
    lazy var locationManager: KONLocationManager = KONLocationManager.sharedInstance
    
    var meUser: KONMeUser!
    var nearbyUsers: [KONNearbyUser] = []
    
    var metUsers: MetUsers = MetUsers() {
        didSet {
           metControllerUpdateCallback?()
        }
    }
    
    // Callbacks
    var metControllerUpdateCallback: (() -> Void)?
    var meUserAvailableCallbacks: [(() -> Void)] = [] {
        didSet {
            if meUserAvailableCallbacks.count > 0 {
                updateMeUserRecord()
            }
        }
    }
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    func start() {
        locationManager.delegate = KONUserManager.sharedInstance

        // Init Me User
        populateMeUser()
        
        createDummyNearbyUsers()
    }
    
    func populateMeUser() {
        meUser = KONMeUser(firstName: "Chance", lastName: "Daniel")
    }
    
    func updateMeUserRecord() {
        networkManager.updateDatabaseWithNewUser(user: meUser)
        for callback in meUserAvailableCallbacks {
            callback()
        }
        meUserAvailableCallbacks.removeAll()
    }
    
    func addMetUsersWithUserIDs(userIDs: [String]) {
        for userID in userIDs {
            metUsers.users.append(KONMetUser(userID: userID))
            networkManager.observeDatabaseForUserValueChangesFor(userID: userID)
        }
    }
    
    func removeMetUsersWithUserIDs(userIDs: [String]) {
        for userID in userIDs {
            if let index = metUsers.userIndexForUserID(userID: userID) {
                metUsers.users.remove(at: index)
            }
        }
    }
    
    func updateMetUsersWithUserIDs(userIDs: [String : [String : Any]]) {
        for (userID, infoDict) in userIDs {
            if let user = metUsers.userForID(userID: userID) {
                user.setValuesForKeys(infoDict)
                metControllerUpdateCallback?()
            }
        }
    }
    
    func updateMeUserWithNewLocation() {

        locationManager.requestLocation()
    }
    
    // MARK: - Fake Data
    func createDummyNearbyUsers() {
        for user in 0..<10 {
            nearbyUsers.append(KONNearbyUser(firstName: "Nearby\(user)", lastName: nil))
        }
    }
    
    
    // MARK: - KONLocationManagerDelegate
    
    func didUpdateCurrentLocation(locationHash: String) {
      
        meUser.locationHash = locationHash
        
        networkManager.updateLocationForUser(user: meUser)
    }
    
    
}
