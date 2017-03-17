
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase


// MARK: - KONNetworkManager

class KONNetworkManager: NSObject, KONStateControllable, KONUserStateControllerDataSource {
    
    // MARK: - Properties
    
    static let sharedInstance: KONNetworkManager = KONNetworkManager()
    
    var databaseRef: FIRDatabaseReference!
    private var userBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
    private var locationBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
    private var startedUserBasedDatabaseObservers = false
    private var startedLocationBasedDatabaseObservers = false
    
    lazy var stateController = KONStateController.sharedInstance
    lazy var userStateController = KONUserStateController.sharedInstance
    
    // Diagnostic
    var userStateControllerCallbacks = [() -> Void]()
    var allowMet = true
    
    // MARK: - Init
    override init() {
        super.init()
        
        // Set Up Database
        databaseRef = FIRDatabase.database().reference()
    }
    
    // MARK: - KONStateControllable Protocol
    
    func start() {
        registerWithStateController()
        registerWithUserStateController()
    }
    
    func stop() {
        unregisterWithStateController()
        // TODO: - Stop UserStateController
        unregisterWithUserStateController()
        self.removeUserBasedDatabaseObservers()
        self.removeUserBasedDatabaseObservers()
        
    }
    
    // MARK: - State Controller
    
    func registerWithStateController() {
        
        let locationAvailableQuery = KONTargetKeyQuery(targetName: KONLocationManager.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: true)
        let meUserAvailableQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.meUser), evaluationValue: true)
        let meUserAndLocationAvailableRule  = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.meUserAndLocationAvailableRule, targetKeyQueries: [locationAvailableQuery, meUserAvailableQuery], condition: .valuesChanged)
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
    
    func unregisterWithStateController() {
        stateController.unregisterRulesForTarget(self)
    }
    
    // MARK: - KONUserStateController
    
    func registerWithUserStateController() {
        userStateController.registerDataSource(self)
    }
    
    func unregisterWithUserStateController() {
        userStateController.unregisterDataSource()
    }
    
    // MARK: KONUserStateControllerDataSource Protocol 
    
    func didChangeUserIDs(_ userIDs: [String], toState state: KONUserState) {
        print("Changed UserID: \(userIDs) to state: \(state)")
        if state == .missing {
            userStateController.removeUserIDs(userIDs)
        }
        if state == .inRegion {
            updateDatabaseWithLocationRequestForUsersIDs(userIDs: userStateController.regionUserIDs)
        }
        else if state == .nearby {
            updateDatabaseWithNearbyUsersIDs(userIDs)
        }
        else if state == .met {
            updateDatabaseWithMetUsersIDs(userIDs)
        }
        
        for callback in userStateControllerCallbacks {
            callback()
        }
    }
    
    func didRemoveUserID(_ userID: String) {
        print("Removed UserID: \(userID)")
        for callback in userStateControllerCallbacks {
            callback()
        }
    }
    
    func didLoseUserID(_ userID: String) {
        processMissingUserIDs([userID])
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
    
    
    func updateDatabaseWithNearbyUsersIDs(_ userIDs: [String]) {
        guard let meUserID = queryForMeUserID() else { return }
        
        let timestamp = ["timestamp" : Date().timeIntervalSince1970]
        
        for userID in userIDs {
//            self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").setValue(timestamp)
            
            self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
        }
    }
    
    func processMissingUserIDs(_ userIDs: [String]) {
        guard let meUserID = queryForMeUserID() else { return }

        print("Process missing userIDs: \(userIDs)")
        
        for userID in userIDs {
            queryDatabaseForLastTimestampForUserID(userID, completion: {[weak self] (timestamp) in
                guard let `self` = self else { return }
                
                let nowStamp = Date().timeIntervalSince1970
                let meetDuration = (nowStamp - timestamp) / 60
                
                print("Saw \(userID) for \(meetDuration) minutes")
                
                // TODO: Compare against threshold 
                if (meetDuration > KONMeetDuration) {
                    if (self.allowMet) {
                        self.userStateController.moveUserIDs([userID], toState: .met)
                    }
                }
                else {
                    self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").removeValue()
                }
            })
        }
    }
        
    
    func updateDatabaseWithMetUsersIDs(_ userIDs: [String]) {
        guard let meUserID = queryForMeUserID() else { return }
        
        for userID in userIDs {
            databaseRef.child("metUsers/\(meUserID)/met/").updateChildValues([userID : true])
            self.databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)").removeValue()
        }
    }
    
    func removeUserFromDatabase(userID: String) {
        databaseRef.child("users/\(userID)").removeValue()
        databaseRef.child("userLocations/\(userID)").removeValue()
        databaseRef.child("nearbyUsers/\(userID)").removeValue()
        databaseRef.child("locationRequestedUsers/\(userID)").removeValue()
    }
    
    // MARK: - Database Observing
    
    func startUserBasedDatabaseObservers() {
        if startedUserBasedDatabaseObservers { return }
        observeDatabaseForMetUsers()
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
        userBasedDatabaseObserverHandles.removeAll()
    }
    
    func removeLocationBasedDatabaseObservers() {
        removeDatabaseObservers(locationBasedDatabaseObserverHandles)
        startedLocationBasedDatabaseObservers = false
        locationBasedDatabaseObserverHandles.removeAll()
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
        observeDatabaseForUsersInRange(range: KONRegionRange, locationHash: locationHash)
    }
    
    func observeDatabaseForUsersInNearbyRangeOfLocation(_ locationHash: String) {
        observeDatabaseForUsersInRange(range: KONNearbyRange, locationHash: locationHash)
    }
    
    func observeDatabaseForUsersInRange(range: Int, locationHash: String) {
        guard let meUserID = queryForMeUserID() else { return }

        let startHash = String(locationHash.characters.prefix(range))
        let endHash = String(locationHash.characters.prefix(range)) + "~"
        
        let locationQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location").queryStarting(atValue: startHash).queryEnding(atValue: endHash)
        let observeHandle = locationQueryRef.observe(.value, with: {[weak self] (locationSnapshot) in
            guard let `self` = self else { return }
            
            if let users = locationSnapshot.value as? [String: Any] {
                
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(meUserID)
                
                let previousMetUserIDs = self.userStateController.metUserIDs
                var previousUserIDsInRange = [String]()
                var lostUserIDsInRange = [String]()
                var state: KONUserState = .missing
                
                if range == KONRegionRange {
                    previousUserIDsInRange = self.userStateController.regionUserIDs
                    lostUserIDsInRange = Array(Set(previousUserIDsInRange).subtracting(userIDs))
                    state = .inRegion
                    userIDs.subtract(self.userStateController.nearbyUserIDs)
                }
                else if range == KONNearbyRange {
                    previousUserIDsInRange = self.userStateController.nearbyUserIDs
                    lostUserIDsInRange = Array(Set(previousUserIDsInRange).subtracting(userIDs))
                    state = .nearby
                }
                
                userIDs.subtract(previousUserIDsInRange + previousMetUserIDs)
                
                if userIDs.count > 0 {
                    self.userStateController.moveUserIDs(Array(userIDs), toState: state)
                }
                
                if lostUserIDsInRange.count > 0 {
                    self.userStateController.moveUserIDs(Array(lostUserIDsInRange), toState: KONUserState(rawValue: state.rawValue - 1)!)
                }
            }
        })
        userBasedDatabaseObserverHandles.append(observeHandle)
        locationBasedDatabaseObserverHandles.append(observeHandle)
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
    
    // MARK: - Database Queries
    
    func queryDatabaseForLastTimestampForUserID(_ userID: String, completion: @escaping (Double) -> Void) {
        guard let meUserID = queryForMeUserID() else { return }
        
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(meUserID)/nearby/\(userID)")
//        databaseRef.child("nearbyUsers/\(meUserID)/nearby/").queryOrderedByValue()
        
        nearbyObserveRef.observeSingleEvent(of: .value, with: { (timestampSnapshot) in
            if let timestampDict = timestampSnapshot.value as? [String: Double], let timestamp = timestampDict["timestamp"] {
                completion(timestamp)
            }
        })
        
        
//        nearbyObserveRef.observe(.childChanged, with: {[weak self] (nearbySnapshot) in
//            guard let `self` = self else { return }
//            
//            let deviceTimestamps = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
//            let timestampArray = Array(deviceTimestamps.values)
//            
//            if let timestamps = timestampArray.flatMap({ (element: [String : AnyObject]) -> Any in
//                return (element.first?.value)!
//            }) as? [TimeInterval] {
//                if timestamps.count > 1 {
//                    self.processTimestampsForUserID(timestamps: timestamps, userID:nearbySnapshot.key)
//                }
//            }
//        })

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
    
    func updateLocationBasedDatabaseObserversWithLocation(_ locationHash: String) {
        removeLocationBasedDatabaseObservers()
        startLocationBasedDatabaseObserversWithLocation(locationHash)
    }

}
