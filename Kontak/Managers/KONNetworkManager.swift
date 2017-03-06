
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase


// MARK: - KONNetworkManager

class KONNetworkManager: NSObject, KONStateControllable {
    
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
    private var userBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
    private var locationBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
    private var startedUserBasedDatabaseObservers = false
    private var startedLocationBasedDatabaseObservers = false
    private var userIDsInRegion: [String] = []
    private var userIDsNearby: [String] = []
    
    lazy var stateController = KONStateController.sharedInstance

    // MARK: - Init
    override init() {
        super.init()
        // Set Up Database
        databaseRef = FIRDatabase.database().reference()
    }
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {

    }
    
    // MARK: - State Controller
    
    func registerWithStateController() {
        
        let locationAvailableQuery = KONTargetKeyQuery(targetName: KONLocationManager.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: true)
        let meUserAvailableQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.meUser), evaluationValue: true)
        let meUserAndLocationAvailableRule  = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.meUserAndLocationAvailableRule, targetKeyQueries: [locationAvailableQuery, meUserAvailableQuery], condition: .valuesCleared)
        meUserAndLocationAvailableRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
            let locationKey = #keyPath(KONLocationManager.latestLocationHash)
            let userKey = #keyPath(KONUserManager.meUser)

            if !successful {
                if let failedKeys = context?[Constants.StateController.RuleContextKeys.failedKeys] as? [String] {
                    if failedKeys.contains(userKey) {
                        // Remove database observers
                        self.removeUserBasedDatabaseObservers()
                    }
                    if failedKeys.contains(locationKey) {
                        // Remove location based observers
                        self.removeLocationBasedDatabaseObservers()
                    }
                }
            }
            else {
                // Start location and user database observers
                if let context = context, let meUser = context[userKey] as? KONMeUser, let locationHash = context[locationKey] as? String  {
                    self.updateDatabaseWithMeUser(user: meUser)
                    self.startUserBasedDatabaseObservers()
                    self.updateLocationForUser(userID: meUser.userID, locationHash: locationHash)
                    self.updateLocationBasedDatabaseObserversWithLocation(locationHash)
                    
//                    stateController.unreigsterRule(rule: meUserAndLocationAvailableRule)
                }
            }
        }
        
        let metUsersQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.metUsers.recentUserID), evaluationValue: true)
        let metUsersUpdatedRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.updatedMetUsersAvailable, targetKeyQueries: [metUsersQuery])
        metUsersUpdatedRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
//            let usersKey = #keyPath(KONUserManager.metUsers.recentUserID)

            if successful {
                if let context = context {
                    for key in rule.allKeys {
                        if let metUser = context[key] as? String {
                            print(metUser)
                            self.observeDatabaseForUserValueChangesFor(userID: metUser)
                        }
                    }
                }
            }
        }
        
        stateController.registerRules(target: self, rules: [meUserAndLocationAvailableRule, metUsersUpdatedRule])
 
    }
    
    // MARK: - Database Updates
    
    func updateDatabaseWithMeUser(user: KONMeUser) {
        databaseRef.child("users").child(user.userID).setValue(["firstName" : user.name?.firstName, "lastName" : user.name?.lastName])
    }
    
    func updateLocationForUser(userID: String, locationHash: String) {
        databaseRef.child("userLocations/\(userID)").setValue(["location" : locationHash])//, "timestamp" : location.timestamp.description(with: Locale.current)])
    }
    
    func updateDatabaseWithLocationRequestForUsersIDs(userIDs: [String]) {
        var userIDs = userIDs
        if let meUserID = queryForMeUserID() {
            userIDs.append(meUserID)
        }
        
        for userID in userIDs {
            databaseRef.child("locationRequestedUsers/\(userID)").setValue(["locationNeeded" : true])
        }
    }
    
    
    func updateDatabaseWithNearbyUsersIDs() {
        guard let meUserID = queryForMeUserID() else { return }
        
        let lastKnownNearbyUsersQueryRef = databaseRef.child("nearbyUsers/\(meUserID)/nearby")
        lastKnownNearbyUsersQueryRef.observeSingleEvent(of: .value, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else {return}
            
            let nearbyUsers = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            let lastKnownNearbyUserSet: Set<String> = Set(Array(nearbyUsers.keys))
            
            let missingNearbyUsers = lastKnownNearbyUserSet.subtracting(self.userIDsNearby)
            print(missingNearbyUsers)
            
         
            
            
            let timestamp = ["timestamp" : Date().timeIntervalSince1970]
            
            for userID in Set(self.userIDsNearby + missingNearbyUsers).subtracting(self.queryForMetUserIDs()) {
                self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
            }
            
            for userID in missingNearbyUsers {
                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(userID)").removeValue()
            }
        })
    }
    
    
    func updateDatabaseWithMetUsers(userID: String) {
        guard let meUserID = queryForMeUserID() else { return }
        
        databaseRef.child("metUsers/\(meUserID)/met/").updateChildValues([userID : true])
        self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").removeValue()
    }
    
    // MARK: - Database Observing
    
    func startUserBasedDatabaseObservers() {
        if startedUserBasedDatabaseObservers { return }
        observeDatabaseForMetUsers()
        observeDatabaseForNearbyUsers()
        observeDatabaseForLocationRequest()
        startedUserBasedDatabaseObservers = true
    }
    
    func startLocationBasedDatabaseObserversWithLocation(_ locationHash: String) {
        if startedLocationBasedDatabaseObservers { return }
        observeDatabaseForUsersInRegionOfLocation(locationHash)
        observeDatabaseForUsersInNearbyRangeOfLocation(locationHash)
        startedLocationBasedDatabaseObservers = true
    }
    
    func removeUserBasedDatabaseObservers() {
        removeDatabaseObservers(userBasedDatabaseObserverHandles)
        startedUserBasedDatabaseObservers = false
    }
    
    func removeLocationBasedDatabaseObservers() {
        removeDatabaseObservers(locationBasedDatabaseObserverHandles)
        startedLocationBasedDatabaseObservers = false
    }
    
    func removeDatabaseObservers(_ observers: [FIRDatabaseHandle]) {
        for handle in observers {
            databaseRef.removeObserver(withHandle: handle)
        }
    }
    
    func observeDatabaseForLocationRequest() {
        guard let meUserID = queryForMeUserID() else { return }

        let locationRequestQueryRef = databaseRef.child("locationRequestedUsers/\(meUserID)")
        let observeHandle = locationRequestQueryRef.observe(.childAdded, with: {[weak self] (requestSnapshot) in
            guard let `self` = self else { return }
            
            let updateLatestLocationQuery = KONTargetKeyQuery(targetName: KONLocationManager.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: false)
            let updateLatestLocationRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.updateLocationHashRule, targetKeyQueries: [updateLatestLocationQuery])
            
            updateLatestLocationRule.evaluationCallback = { (rule, success, nil) in
                if success {
                    locationRequestQueryRef.removeValue()
                }
            }
            
            self.stateController.registerRules([updateLatestLocationRule])
            
        })
        self.userBasedDatabaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForUsersInRegionOfLocation(_ locationHash: String) {
        observeDatabaseForUsersInRange(range: KONRegionRange, locationHash: locationHash) {[weak self] (successful) in
            if !successful { return }
            guard let `self` = self else { return }
            
            print("Users in Region Range: \(self.userIDsInRegion)")
            self.updateDatabaseWithLocationRequestForUsersIDs(userIDs: self.userIDsInRegion)
            
        }
    }
    
    func observeDatabaseForUsersInNearbyRangeOfLocation(_ locationHash: String) {
        observeDatabaseForUsersInRange(range: KONNearbyRange, locationHash: locationHash) {[weak self] (successful) in
            if !successful { return }
            guard let `self` = self else { return }
            
            print("Users in Nearby Range: \(self.userIDsNearby)")
            self.updateDatabaseWithNearbyUsersIDs()
        }
    }
    
    func observeDatabaseForUsersInRange(range: Int, locationHash: String, completionHandler: @escaping ((Bool) -> Void)) {
        guard let meUserID = queryForMeUserID() else { return }

        let startHash = String(locationHash.characters.prefix(range))
        let endHash = String(locationHash.characters.prefix(range)) + "~"
        
        let locationQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location").queryStarting(atValue: startHash).queryEnding(atValue: endHash)
        let observeHandle = locationQueryRef.observe(.value, with: { (locationSnapshot) in
            
            if let users = locationSnapshot.value as? [String: Any] {
                
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(meUserID)
                
                if range == KONRegionRange {
                    let previousUserIDsInRegion = self.userIDsInRegion
                    self.userIDsInRegion = Array(userIDs)
                    userIDs.subtract(previousUserIDsInRegion)
                    
                    if userIDs.count > 0 {
                        completionHandler(true)
                    }
                }
                else if range == KONNearbyRange {
                    let previousUserIDsNearby = self.userIDsNearby
                    self.userIDsNearby = Array(userIDs)
                    let lostUserIDsNearby = Set(previousUserIDsNearby).subtracting(userIDs)
                    
                    userIDs.subtract(self.queryForMetUserIDs() + previousUserIDsNearby)
                    if userIDs.count > 0 || lostUserIDsNearby.count > 0 {
                        completionHandler(true)
                    }
                }
                completionHandler(false)
            }
        })
        userBasedDatabaseObserverHandles.append(observeHandle)
        locationBasedDatabaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForNearbyUsers() {
        guard let meUserID = queryForMeUserID() else { return }

        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(meUserID)/nearby/").queryOrderedByValue()
        
        let observeHandle = nearbyObserveRef.observe(.childChanged, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else { return }
            
            let deviceTimestamps = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            let timestampArray = Array(deviceTimestamps.values)
            
            if let timestamps = timestampArray.flatMap({ (element: [String : AnyObject]) -> Any in
                return (element.first?.value)!
            }) as? [TimeInterval] {
                if timestamps.count > 1 {
                    self.processTimestampsForUserID(timestamps: timestamps, userID:nearbySnapshot.key)
                }
            }
        })
        userBasedDatabaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForMetUsers() {
        guard let meUserID = queryForMeUserID() else { return }

        let metObserveRef = databaseRef.child("metUsers/\(meUserID)/met/")//.queryOrderedByKey()
        
        let childAddedObserveHandle = metObserveRef.observe(.childAdded, with: {[weak self] (metSnapshot) in
            guard let `self` = self else { return }
            
            let metUserID = metSnapshot.key
            self.stateController.didReceiveTransportEvent(.dataReceived, data: metUserID, targetName: KONUserManager.className)
            
            
        })
        userBasedDatabaseObserverHandles.append(childAddedObserveHandle)
        
        let childRemovedObserveHandle = metObserveRef.observe(.childRemoved, with: {[weak self] (lostSnapshot) in
            guard let `self` = self else { return }
            
            let lostUserID = lostSnapshot.key
            self.stateController.didReceiveTransportEvent(.dataRemoved, data: lostUserID, targetName: KONUserManager.className)
        })
        userBasedDatabaseObserverHandles.append(childRemovedObserveHandle)
    }
    
    func observeDatabaseForUserValueChangesFor(userID: String) {
        let userObserveRef = databaseRef.child("users/\(userID)")
        
        let observeHandle = userObserveRef.observe(.value, with: {[weak self] (userSnapshot) in
            guard let `self` = self else { return }
                        
            let userIDs = [userSnapshot.key : userSnapshot.value as? [String : Any] ?? [:]]
            print(userIDs)
            self.stateController.didReceiveTransportEvent(.dataChanged, data: userIDs, targetName: KONUserManager.className)
            
        })
        userBasedDatabaseObserverHandles.append(observeHandle)
        
    }
    
    // MARK: - Helpers
    
    func queryForMeUserID() -> String? {
        let userIDQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.meUser.userID), evaluationValue: true)
        let (successful, value) = stateController.performTargetKeyQuery(userIDQuery)
        if successful {
            if let userID = value as? String {
                return userID
            }
        }
        return nil
    }
    
    func queryForMetUserIDs() -> [String] {
        let userIDQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.metUsers.userIDs), evaluationValue: true)
        let (successful, value) = stateController.performTargetKeyQuery(userIDQuery)
        if successful {
            if let userIDs = value as? [String] {
                return userIDs
            }
        }
        return []
    }
    
    func updateLocationBasedDatabaseObserversWithLocation(_ locationHash: String) {
        removeLocationBasedDatabaseObservers()
        startLocationBasedDatabaseObserversWithLocation(locationHash)
    }
    
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
    
    /*
    // MARK: - KONStateControllerEvaluationObserver Protocol
    func didEvaluateRule(ruleName: String, successful: Bool, context: [String : Any]?) {
//        print("Rule: \(ruleName), was \(successful ? "" : "not ")successful")
        if !successful { return }
        if ruleName == Constants.StateController.RuleNames.meUserAvailableRule {
            print("MeUser Did Become Available")
            let key = #keyPath(KONUserManager.meUser)
            if let context = context, let user = context[key] as? KONMeUser {
                updateDatabaseWithMeUser(user: user)
                self.startDatabaseObservers()
            }
        }
        else if ruleName == Constants.StateController.RuleNames.locationAvailableRule {
            print("Location Did Become Available")
            
        }
        else if ruleName == Constants.StateController.RuleNames.meUserAndLocationAvailableRule {
            print("Location and Me User Available")
            let locationKey = #keyPath(KONLocationManager.latestLocationHash)
            let userKey = #keyPath(KONUserManager.meUser)
            if let context = context, let locationHash = context[locationKey] as? String, let meUser = context[userKey] as? KONMeUser {
                self.updateLocationForUser(userID: meUser.userID, locationHash: locationHash)
                self.updateLocationBasedDatabaseObserversWithLocation(locationHash)
            }
        }
        
        
    }
 */
}
