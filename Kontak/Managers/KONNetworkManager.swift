
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
    var databaseRef: FIRDatabaseReference!
    private var usersInRange: UsersInRange = UsersInRange()
    weak var delegate: KONNetworkManagerDelegate?

    // MARK: - Init
    override init() {
        super.init()
        databaseRef = FIRDatabase.database().reference()
    }
    
    // MARK: - Database Updates
    func updateDatabaseWithNewUser(user: KONMeUser) {
        databaseRef.child("users").child(user.userID).setValue(["firstName" : user.name.firstName, "lastName" : user.name.lastName])
        
        observeDatabaseForNearbyUsers()
        observeDatabaseForMetUsers()
    }
    
    func updateLocationForUser(user: KONMeUser) {
        if let location = user.location {
            databaseRef.child("userLocations/\(user.userID)/location").setValue(["latitude" : location.latitude, "longitude" : location.longitude, "timestamp" : location.timestamp.timeIntervalSince1970])
        }
    }
    
    func updateDatabaseWithNearbyUsers() {
        let latSet: Set<String> = Set(usersInRange.usersInLatRange)
        let lonSet: Set<String> = Set(usersInRange.usersInLonRange)
        
        let nearbyUserSet = latSet.intersection(lonSet)
        
        let lastKnownNearbyUsersQueryRef = databaseRef.child("nearbyUsers/\(KONUserManager.sharedInstance.meUser.userID)/nearby")
        lastKnownNearbyUsersQueryRef.observeSingleEvent(of: .value, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else {return}
            
            print(nearbySnapshot)
            let nearbyUsers = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            
            print(Array(nearbyUsers.keys))
            
            let lastKnownNearbyUserSet: Set<String> = Set(Array(nearbyUsers.keys))
            
            let missingNearbyUsers = lastKnownNearbyUserSet.subtracting(nearbyUserSet)
            print(missingNearbyUsers)
            
            for userID in missingNearbyUsers {
                // TODO: - Remove Updating of Other Users
                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(KONUserManager.sharedInstance.meUser.userID)").removeValue()
                
                self.databaseRef.child("nearbyUsers/\(KONUserManager.sharedInstance.meUser.userID)/nearby/\(userID)").removeValue()
            }
            
            
            let timestamp = ["timestamp" : Date().timeIntervalSince1970]
            
            for userID in nearbyUserSet {
                // TODO: - Remove Updating of Other Users
                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(KONUserManager.sharedInstance.meUser.userID)").childByAutoId().setValue(timestamp)
                
                self.databaseRef.child("nearbyUsers/\(KONUserManager.sharedInstance.meUser.userID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
            }
        })
        
        usersInRange.usersInLonRange.removeAll()
        usersInRange.usersInLatRange.removeAll()
    }
    
    func updateDatabaseWithMetUsers(userID: String) {
        databaseRef.child("metUsers/\(KONUserManager.sharedInstance.meUser.userID)/met/").updateChildValues([userID : true])
        
        // TODO: - Remove Updating of Other Users
        databaseRef.child("metUsers/\(userID)/met/").updateChildValues([KONUserManager.sharedInstance.meUser.userID : true])
        
        
        self.databaseRef.child("nearbyUsers/\(KONUserManager.sharedInstance.meUser.userID)/nearby/\(userID)").removeValue()
        // TODO: - Remove Updating of Other Users
        self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(KONUserManager.sharedInstance.meUser.userID)").removeValue()

        
    }
    
    // MARK: - Database Observing
    
    func observeDatabaseForPotentialUsersInRange() {
        
        if let myLocation = KONUserManager.sharedInstance.meUser.location {
            let locationRange = KONLocationManager.locationRangeFromLocation(location: myLocation, radius: 0.003)
            
            let latQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/latitude").queryStarting(atValue: locationRange.latMin).queryEnding(atValue: locationRange.latMax)
            
            latQueryRef.observe(.value, with: {[weak self] (snapshot) in
                guard let `self` =  self else {return}
                
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(KONUserManager.sharedInstance.meUser.userID)
                    userIDs.subtract(Set(KONUserManager.sharedInstance.metUsers.userIDs))
                    self.usersInRange.usersInLatRange.append(contentsOf: userIDs)
                }
                if self.usersInRange.hasUsers {
                    self.updateDatabaseWithNearbyUsers()
                }
            })
            
            let lonQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location/longitude").queryStarting(atValue: locationRange.lonMin).queryEnding(atValue: locationRange.lonMax)
            
            lonQueryRef.observe(.value, with: { (snapshot) in
                if let users = snapshot.value as? [String: Any] {
                    var userIDs: Set<String> = Set(users.keys)
                    userIDs.remove(KONUserManager.sharedInstance.meUser.userID)
                    userIDs.subtract(Set(KONUserManager.sharedInstance.metUsers.userIDs))
                    self.usersInRange.usersInLonRange.append(contentsOf: userIDs)
                }
                if self.usersInRange.hasUsers {
                    self.updateDatabaseWithNearbyUsers()
                }
            })
        }
    }
    
    func observeDatabaseForNearbyUsers() {
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(KONUserManager.sharedInstance.meUser.userID)/nearby/").queryOrderedByValue()
        
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
//        KONUserManager.sharedInstance.addNewMetUserForUserID(userID: userID)
        let metObserveRef = databaseRef.child("metUsers/\(KONUserManager.sharedInstance.meUser.userID)/met/").queryOrderedByKey()
        
        metObserveRef.observe(.value, with: { (metSnapshot) in
            print(metSnapshot)
            let metUserIDs = Array((metSnapshot.value as? [String : Bool] ?? [:]).keys)
            KONUserManager.sharedInstance.updateMetUsersWithUserIDs(userIDs: metUserIDs  as [String])
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
    
    
    
    
    
    
    
    

}
