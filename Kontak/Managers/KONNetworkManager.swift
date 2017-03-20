
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase


// MARK: - StateController Extension 

extension KONStateController {
    func queryForCurrentUserID() -> String? {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            return userManager.currentUser?.userID
        }
        return nil
    }
    
    func addNearbyUser(_ userRef: KONUserReference) {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            if !userManager.nearbyUsers.contains(userRef) {
                userManager.nearbyUsers.append(userRef)
            }
        }
    }
    
    func removeNearbyUser(_ userRef: KONUserReference) {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            if let userIndex = userManager.nearbyUsers.index(of: userRef) {
                userManager.nearbyUsers.remove(at: userIndex)
            }
        }
    }
}

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
        let currentUserAvailableQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.currentUser), evaluationValue: true)
        let currentUserAndLocationAvailableRule  = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.currentUserAndLocationAvailableRule, targetKeyQueries: [locationAvailableQuery, currentUserAvailableQuery], condition: .valuesChanged)
        currentUserAndLocationAvailableRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
            let locationKey = #keyPath(KONLocationManager.latestLocationHash)
            let userKey = #keyPath(KONUserManager.currentUser)

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
                if let context = context, let currentUser = context[userKey] as? KONUserReference, let locationHash = context[locationKey] as? String  {
                    self.updateDatabaseWithCurrentUser(currentUser)
                    self.startUserBasedDatabaseObservers()
                    self.updateLocationForUser(userRef: currentUser, locationHash: locationHash)
                    self.updateLocationBasedDatabaseObserversWithLocation(locationHash)
                }
            }
        }
        
        let metUsersQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.metUsers.recentUserID), evaluationValue: true)
        let metUsersUpdatedRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.updatedMetUsersAvailable, targetKeyQueries: [metUsersQuery])
        metUsersUpdatedRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
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
        
        stateController.registerRules(target: self, rules: [currentUserAndLocationAvailableRule, metUsersUpdatedRule])
 
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
    
    // MARK: - KONUserStateControllerDataSource Protocol
    
    func didChangeUsers(_ userRefs: [KONUserReference], toState state: KONUserState) {
        print("Changed Users: \(userRefs)) to state: \(state)")
        
        if state == .missing {
            userStateController.removeUsers(userRefs)
        }
        else if state == .inRegion {
            updateDatabaseWithLocationRequestForUsers(userStateController.regionUsers)
        }
        else if state == .nearby {
            updateDatabaseWithNearbyUsers(userRefs)
            for userRef in userRefs {
                queryDatabaseForUserProfileForUser(userRef, completion: {[weak self] (userRef) in
                    guard let `self` = self else { return }
                    self.stateController.addNearbyUser(userRef)
                })
            }
        }
        else if state == .met {
            updateDatabaseWithMetUsers(userRefs)
        }
        
        for callback in userStateControllerCallbacks {
            callback()
        }
    }

    func didRemoveUser(_ userRef: KONUserReference) {
        print("Removed User: \(userRef)")
        for callback in userStateControllerCallbacks {
            callback()
        }
    }

    
    func didLoseUser(_ userRef: KONUserReference) {
        processMissingUsers([userRef])
    }
    
    
    // MARK: - Database Updates
    
    func updateDatabaseWithCurrentUser(_ userRef: KONUserReference) {
        if let userID = userRef.userID, let lastName = userRef.lastName {
            databaseRef.child("users").child(userID).setValue(["firstName" : userRef.firstName, "lastName" : lastName])
        }
    }
    
    func updateLocationForUser(userRef: KONUserReference, locationHash: String) {
        if let userID = userRef.userID {
            databaseRef.child("userLocations/\(userID)").setValue(["location" : locationHash])
        }
    }
    
    func updateDatabaseWithLocationRequestForUsers(_ userRefs: [KONUserReference]) {
        
        var userIDs = userRefs.flatMap{$0.userID}
        
        if let currentUserID = stateController.queryForCurrentUserID() {
            userIDs.append(currentUserID)
        }
        
        for userID in userIDs {
            databaseRef.child("locationRequestedUsers/\(userID)").setValue(["locationNeeded" : true])
        }
    }
    
    
    func updateDatabaseWithNearbyUsers(_ userRefs: [KONUserReference]) {
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }
        
        let timestamp = ["timestamp" : Date().timeIntervalSince1970]
        
        for userID in userRefs.flatMap({$0.userID}) {
            self.databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
        }
    }
    
    func processMissingUsers(_ userRefs: [KONUserReference]) {
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }

        print("Process missing users: \(userRefs)")
        
        for userRef in userRefs {
            if let userID = userRef.userID {
                queryDatabaseForLastTimestampForUserID(userID, completion: {[weak self] (timestamp) in
                    guard let `self` = self else { return }
                    
                    let nowStamp = Date().timeIntervalSince1970
                    let meetDuration = (nowStamp - timestamp) / 60
                    
                    print("Saw \(userID) for \(meetDuration) minutes")
                    
                    // TODO: Compare against threshold 
                    if (meetDuration > KONMeetDuration) {
                        if (self.allowMet) {
                            // TODO: - Change to userRefs
                            self.userStateController.moveUsers([userRef], toState: .met)
                        }
                    }
                    else {
                        self.databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)").removeValue()
                    }
                })
            }
        }
    }
        
    
    func updateDatabaseWithMetUsers(_ userRefs: [KONUserReference]) {
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }
        
        for userID in userRefs.flatMap({$0.userID}) {
            databaseRef.child("metUsers/\(currentUserID)/met/").updateChildValues([userID : true])
            self.databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)").removeValue()
        }
    }
    
    func removeUserFromDatabase(userRef: KONUserReference) {
        if let userID = userRef.userID {
            databaseRef.child("users/\(userID)").removeValue()
            databaseRef.child("userLocations/\(userID)").removeValue()
            databaseRef.child("nearbyUsers/\(userID)").removeValue()
            databaseRef.child("locationRequestedUsers/\(userID)").removeValue()
        }
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
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }

        let locationRequestQueryRef = databaseRef.child("locationRequestedUsers/\(currentUserID)")
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
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }

        let startHash = String(locationHash.characters.prefix(range))
        let endHash = String(locationHash.characters.prefix(range)) + "~"
        
        let locationQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location").queryStarting(atValue: startHash).queryEnding(atValue: endHash)
        let observeHandle = locationQueryRef.observe(.value, with: {[weak self] (locationSnapshot) in
            guard let `self` = self else { return }
            
            if let users = locationSnapshot.value as? [String: Any] {
                
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(currentUserID)
                
                var userRefs = Set(KONUserReference.userRefsFromUserIDs(Array(userIDs)))
                
                let previouslyMetUsers = self.userStateController.metUsers
                var previousUsersInRange = [KONUserReference]()
                var missingUsersInRange = [KONUserReference]()

                var state: KONUserState = .missing
                
                if range == KONRegionRange {
                
                    previousUsersInRange = self.userStateController.regionUsers
                    missingUsersInRange = Array(Set(previousUsersInRange).subtracting(userRefs))
                    state = .inRegion
                    userRefs.subtract(self.userStateController.nearbyUsers)

                    
                }
                else if range == KONNearbyRange {
                    previousUsersInRange = self.userStateController.nearbyUsers
                    missingUsersInRange = Array(Set(previousUsersInRange).subtracting(userRefs))
                    state = .nearby
                   
                }
                
                userRefs.subtract(previousUsersInRange + previouslyMetUsers)
                if userRefs.count > 0 {
                    self.userStateController.moveUsers(Array(userRefs), toState: state)
                }
                if missingUsersInRange.count > 0 {
                    self.userStateController.moveUsers(Array(missingUsersInRange), toState: KONUserState(rawValue: state.rawValue - 1)!)
                }
            }
        })
        userBasedDatabaseObserverHandles.append(observeHandle)
        locationBasedDatabaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForMetUsers() {
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }

        let metObserveRef = databaseRef.child("metUsers/\(currentUserID)/met/")//.queryOrderedByKey()
        
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
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }
        
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)")
        
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
    
    func queryDatabaseForUserProfileForUser(_ userRef: KONUserReference, completion: @escaping (KONUserReference) -> Void) {
        guard let userID = userRef.userID else { return }
        
        let userProfileRef = databaseRef.child("users/\(userID)")
        
        userProfileRef.observeSingleEvent(of: .value, with: { (profileSnapshot) in
            if let profile = profileSnapshot.value as? [String : String], let firstName = profile["firstName"], let lastName = profile["lastName"] {
                userRef.firstName = firstName
                userRef.lastName = lastName
                completion(userRef)
            }
        })
    }
    
    // MARK: - Helpers
    
    func updateLocationBasedDatabaseObserversWithLocation(_ locationHash: String) {
        removeLocationBasedDatabaseObservers()
        startLocationBasedDatabaseObserversWithLocation(locationHash)
    }

}
