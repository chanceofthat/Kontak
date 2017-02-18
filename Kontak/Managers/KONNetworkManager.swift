
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase

// MARK: - KONNetworkManagerDelegate
protocol KONNetworkManagerDelegate: class {
    func didFindNewMetUsers()
}

// MARK: - KONNetworkManager
class KONNetworkManager: NSObject {
    
    // MARK: - Structs
    private struct UsersInRange {
        
        var usersInLatRange: [String] = []
        var usersInLonRange: [String] = []

        var hasUsers: Bool {
            get {
                return usersInLatRange.count > 0 && usersInLonRange.count > 0
            }
        }
    }
    
    // MARK: - Properties
    static let sharedInstance: KONNetworkManager = KONNetworkManager()

    var databaseRef: FIRDatabaseReference!
    private var startedDatabaseObservers = false
    private var userIDsInRegion: [String] = []
    private var userIDsNearby: [String] = []
    weak var delegate: KONNetworkManagerDelegate?
    
    lazy var userManager: KONUserManager = KONUserManager.sharedInstance
    lazy var locationManager: KONLocationManager = KONLocationManager.sharedInstance


    // MARK: - Init
    private override init() {
        super.init()
        // Set Up Database
        databaseRef = FIRDatabase.database().reference()
        
        
    }
    
    func start() {

        userManager.meUserAvailableCallbacks.append {[weak self ] in
            guard let `self` = self else { return }
            self.startDatabaseObservers()
        }
        locationManager.locationAvailableCallbacks.append {[weak self] in
            guard let `self` = self else { return }
            self.startLocationDependentDatabaseObservers()
        }
        
    }
    
    // MARK: - Database Updates
    func updateDatabaseWithNewUser(user: KONMeUser) {
        databaseRef.child("users").child(user.userID).setValue(["firstName" : user.name?.firstName, "lastName" : user.name?.lastName])
        
    }
    
    func updateLocationForUser(user: KONMeUser) {
        if let location = user.location {
            databaseRef.child("userLocations/\(user.userID)/location").setValue(["latitude" : location.latitude, "longitude" : location.longitude])//, "timestamp" : location.timestamp.description(with: Locale.current)])
        }
    }
    
    func updateDatabaseWithLocationRequestForUsersIDs(userIDs: [String]) {
        let userIDs = userIDs + [userManager.meUser.userID]
        
        for userID in userIDs {
            databaseRef.child("locationRequestedUsers/\(userID)").setValue(["locationNeeded" : true])
        }
        
//        usersInRegion.usersInLonRange.removeAll()
//        usersInRegion.usersInLatRange.removeAll()
    }
    
    
    func updateDatabaseWithNearbyUsersIDs() {
//        let latSet: Set<String> = Set(usersNearby.usersInLatRange)
//        let lonSet: Set<String> = Set(usersNearby.usersInLonRange)
        
//        let nearbyUserSet = latSet.intersection(lonSet)
        
        let lastKnownNearbyUsersQueryRef = databaseRef.child("nearbyUsers/\(userManager.meUser.userID)/nearby")
        lastKnownNearbyUsersQueryRef.observeSingleEvent(of: .value, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else {return}
            
            print(nearbySnapshot)
            let nearbyUsers = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            
            print(Array(nearbyUsers.keys))
            
            let lastKnownNearbyUserSet: Set<String> = Set(Array(nearbyUsers.keys))
            
            let missingNearbyUsers = lastKnownNearbyUserSet.subtracting(self.userIDsNearby)
            print(missingNearbyUsers)
            
            for userID in missingNearbyUsers {
                // TODO: - Remove Updating of Other Users
//                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(self.userManager.meUser.userID)").removeValue()
                
                self.databaseRef.child("nearbyUsers/\(self.userManager.meUser.userID)/nearby/\(userID)").removeValue()
            }
            
            
            let timestamp = ["timestamp" : Date().timeIntervalSince1970]
            
            for userID in self.userIDsNearby {
                // TODO: - Remove Updating of Other Users
//                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(self.userManager.meUser.userID)").childByAutoId().setValue(timestamp)
                
                self.databaseRef.child("nearbyUsers/\(self.userManager.meUser.userID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
            }
        })
        
//        usersNearby.usersInLonRange.removeAll()
//        usersNearby.usersInLatRange.removeAll()
    }
    
    
    func updateDatabaseWithMetUsers(userID: String) {
        databaseRef.child("metUsers/\(userManager.meUser.userID)/met/").updateChildValues([userID : true])
        
        // TODO: - Remove Updating of Other Users
//        databaseRef.child("metUsers/\(userID)/met/").updateChildValues([userManager.meUser.userID : true])
        
        
        self.databaseRef.child("nearbyUsers/\(userManager.meUser.userID)/nearby/\(userID)").removeValue()
        // TODO: - Remove Updating of Other Users
//        self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(userManager.meUser.userID)").removeValue()

        
    }
    
    // MARK: - Database Observing
    func startDatabaseObservers() {
        observeDatabaseForMetUsers()
    }
    
    func startLocationDependentDatabaseObservers() {
        observeDatabaseForLocationRequest()
        observeDatabaseForNearbyUsers()
        observeDatabaseForUsersInRegion()
        observeDatabaseForUserInNearbyRange()
    }
    
    func observeDatabaseForLocationRequest() {
        let locationRequestQueryRef = databaseRef.child("locationRequestedUsers/\(userManager.meUser.userID)")
        locationRequestQueryRef.observe(.childAdded, with: {[weak self] (requestSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.updateMeUserWithNewLocation()
            
            locationRequestQueryRef.removeValue()
        })
    }
    
    /*
    func observeDatabaseForUsersInRegion() {
        
        if let myLocation = userManager.meUser.location {
            let locationRange = KONLocationManager.locationRangeFromLocation(location: myLocation, radius: 0.05)
            
            let latQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/latitude").queryStarting(atValue: locationRange.latMin).queryEnding(atValue: locationRange.latMax)
            
            latQueryRef.observe(.value, with: {[weak self] (snapshot) in
                guard let `self` =  self else {return}
                
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(self.userManager.meUser.userID)
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs))
                    self.usersInRegion.usersInLatRange.append(contentsOf: userIDs)
                }
                if self.usersInRegion.hasUsers {
//                    self.updateDatabaseWithNearbyUsers()
                    self.updateDatabaseWithLocationRequestForUsersInRegion()
                }
            })
            
            let lonQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/longitude").queryStarting(atValue: locationRange.lonMin).queryEnding(atValue: locationRange.lonMax)
            
            lonQueryRef.observe(.value, with: { (snapshot) in
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(self.userManager.meUser.userID)
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs))
                    self.usersInRegion.usersInLonRange.append(contentsOf: userIDs)
                }
                if self.usersInRegion.hasUsers {
//                    self.updateDatabaseWithNearbyUsers()
                    self.updateDatabaseWithLocationRequestForUsersInRegion()
                }
            })
        }
    }
    
    func observeDatabaseForNearbyUsers() {
        if let myLocation = userManager.meUser.location {
            let locationRange = KONLocationManager.locationRangeFromLocation(location: myLocation, radius: 0.003)
            
            let latQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/latitude").queryStarting(atValue: locationRange.latMin).queryEnding(atValue: locationRange.latMax)
            
            latQueryRef.observe(.value, with: {[weak self] (snapshot) in
                guard let `self` =  self else {return}
                
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(self.userManager.meUser.userID)
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs))
                    self.usersNearby.usersInLatRange.append(contentsOf: userIDs)
                }
                if self.usersNearby.hasUsers {
                    self.updateDatabaseWithNearbyUsers()
                }
            })
            
            let lonQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/longitude").queryStarting(atValue: locationRange.lonMin).queryEnding(atValue: locationRange.lonMax)
            
            lonQueryRef.observe(.value, with: { (snapshot) in
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(self.userManager.meUser.userID)
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs))
                    self.usersNearby.usersInLonRange.append(contentsOf: userIDs)
                }
                if self.usersNearby.hasUsers {
                    self.updateDatabaseWithNearbyUsers()
                }
            })
        }
    }
    */
    
    func observeDatabaseForUsersInRegion() {
        observeDatabseForUsersInRange(range: 50) {[weak self] (usersInRange) in
            guard let `self` = self else { return }
            
            print(usersInRange)
            
            let latSet: Set<String> = Set(usersInRange.usersInLatRange)
            let lonSet: Set<String> = Set(usersInRange.usersInLonRange)
            
            self.userIDsInRegion.append(contentsOf: latSet.intersection(lonSet))
            self.updateDatabaseWithLocationRequestForUsersIDs(userIDs: self.userIDsInRegion as [String])
            
        }
    }
    
    func observeDatabaseForUserInNearbyRange() {
        observeDatabseForUsersInRange(range: 3) {[weak self] (usersInRange) in
            guard let `self` = self else { return }
            
            let latSet: Set<String> = Set(usersInRange.usersInLatRange)
            let lonSet: Set<String> = Set(usersInRange.usersInLonRange)
            
            self.userIDsNearby = Array(latSet.intersection(lonSet))
            print("Users In Nearby Range: \(self.userIDsNearby)")
            
            self.updateDatabaseWithNearbyUsersIDs()
            
        }
    }
    
    private func observeDatabseForUsersInRange(range radius: Double, completionHandler: @escaping ((UsersInRange) -> Void)) {
        guard let myLocation = userManager.meUser.location else { return }
        
        var usersInRange: UsersInRange = UsersInRange()

        let locationRange = KONLocationManager.locationRangeFromLocation(location: myLocation, radius: radius)
        
        
        let latQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/latitude").queryStarting(atValue: locationRange.latMin).queryEnding(atValue: locationRange.latMax)
        
        latQueryRef.observe(.value, with: {[weak self] (snapshot) in
            guard let `self` =  self else {return}
            
            if let users = snapshot.value as? [String: Any] {
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(self.userManager.meUser.userID)
                if radius == 50 {
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs + self.userIDsInRegion))
                }
                else {
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs + self.userIDsNearby))
                }
                usersInRange.usersInLatRange = Array(userIDs)
                print("UsersInLATRange: \(usersInRange.usersInLatRange)")
            }
            if usersInRange.hasUsers {
                completionHandler(usersInRange)
            }
        })
        
        let lonQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/longitude").queryStarting(atValue: locationRange.lonMin).queryEnding(atValue: locationRange.lonMax)
        
        
        lonQueryRef.observe(.value, with: { (snapshot) in
            if let users = snapshot.value as? [String: Any] {
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(self.userManager.meUser.userID)
                if radius == 50 {
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs + self.userIDsInRegion))
                }
                else {
                    userIDs.subtract(Set(self.userManager.metUsers.userIDs + self.userIDsNearby))
                }
                usersInRange.usersInLonRange = Array(userIDs)
                print("UsersInLONRange: \(usersInRange.usersInLonRange)")
            }
            
            
            if usersInRange.hasUsers {
                completionHandler(usersInRange)
            }
        })
    }
    
    
    
    
    
    
    
    
    
    func observeDatabaseForNearbyUsers() {
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(userManager.meUser.userID)/nearby/").queryOrderedByValue()
        
        nearbyObserveRef.observe(.childChanged, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else { return }
            
            let deviceTimestamps = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            let timestampArray = Array(deviceTimestamps.values)
            
            if let timestamps = timestampArray.flatMap({ (element: [String : AnyObject]) -> AnyObject in
                return (element.first?.value)!
            }) as? [TimeInterval] {
                if timestamps.count > 1 {
                    self.processTimestampsForUserID(timestamps: timestamps, userID:nearbySnapshot.key)
                }
            }
        })
    }
    
    func observeDatabaseForMetUsers() {
        let metObserveRef = databaseRef.child("metUsers/\(userManager.meUser.userID)/met/").queryOrderedByKey()
        
        metObserveRef.observe(.childAdded, with: {[weak self] (metSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.addMetUsersWithUserIDs(userIDs: [metSnapshot.key])
        })
        
        metObserveRef.observe(.childRemoved, with: {[weak self] (lostSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.removeMetUsersWithUserIDs(userIDs: [lostSnapshot.key])
        })
    }
    
    func observeDatabaseForUserValueChangesFor(userID: String) {
        let userObserveRef = databaseRef.child("users/\(userID)")
        
        userObserveRef.observe(.value, with: {[weak self] (userSnapshot) in
            guard let `self` = self else { return }
            
            print(userSnapshot)
            self.userManager.updateMetUsersWithUserIDs(userIDs: [userSnapshot.key : userSnapshot.value as? [String : Any] ?? [:]])
            
        })
    }
    
    // MARK: - Helpers
    func processTimestampsForUserID(timestamps: [TimeInterval], userID: String) {
        let timestamps = timestamps.sorted(by: { (intervalOne, intervalTwo) -> Bool in
            return intervalOne < intervalTwo
        })
        
        let earliestTime = timestamps.first!
        let lastestTime = timestamps.last!
        
        let meetDuration = (lastestTime - earliestTime) / 60
        
        print("Met \(userID) for \(meetDuration) minutes")
    
        if (meetDuration > KONMeetDuration) {
            updateDatabaseWithMetUsers(userID: userID)
        }
    }
    
    func processUsersInRegion() {
        
    }
    
    
    
    
    
    
    

}
