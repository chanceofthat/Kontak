
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
    
    var stateMachine = KONStateMachine()

    var databaseRef: FIRDatabaseReference!
    private var databaseObserverHandles: [FIRDatabaseHandle] = []
    private var locationBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
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
        
        setupStateMachine()
        
    }
    
    func setupStateMachine() {
        
        // Stopped
        let stoppedState = KONState(name: "StoppedState", enterAction: nil)
        stoppedState.addTransition(KONStateTransition(action: removeDatabaseObservers), fromStateName: "AwaitingMeUserAvailabilityState")
        stoppedState.addTransition(KONStateTransition(action: removeDatabaseObservers), fromStateName: "AwaitingInitialLocationUpdateState")
        stoppedState.addTransition(KONStateTransition(action: removeDatabaseObservers), fromStateName: "IdleObservingState")
        stateMachine.addState(state: stoppedState)
    
        // Idle Not Observing
        let idleNotObservingState = KONState(name: "IdleNotObservingState", enterAction: nil)
        stateMachine.addState(state: idleNotObservingState)
        
        // Idle Database Observing
        let idleObservingState = KONState(name: "IdleObservingState", enterAction: nil)
        stateMachine.addState(state: idleObservingState)
        
        
        stateMachine.start()

    }
    

    
    func start() {
        
        stateMachine.transitionToState(stateName: "IdleNotObservingState")
        
        userManager.meUserAvailableCallbacks.append {[weak self ] in
            guard let `self` = self else { return }
            self.startDatabaseObservers()
        }
        locationManager.locationUpdatedCallbacks.append {[weak self] in
            guard let `self` = self else { return }
//            self.startLocationDependentDatabaseObservers()
            self.updateLocationBasedDatabaseObservers()
        }
        
    }
    
    func stop() {
        stateMachine.transitionToState(stateName: "StoppedState")
    }
    
    func removeDatabaseObservers() {
        for handle in databaseObserverHandles {
            databaseRef.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: - Database Updates
    func updateDatabaseWithNewUser(user: KONMeUser) {
        databaseRef.child("users").child(user.userID).setValue(["firstName" : user.name?.firstName, "lastName" : user.name?.lastName])
        
    }
    
    func updateLocationForUser(user: KONMeUser) {
        if let location = user.locationHash {
            databaseRef.child("userLocations/\(user.userID)").setValue(["location" : location])//, "timestamp" : location.timestamp.description(with: Locale.current)])
        }
    }
    
    func updateDatabaseWithLocationRequestForUsersIDs(userIDs: [String]) {
        let userIDs = userIDs + [userManager.meUser.userID]
        
        for userID in userIDs {
            databaseRef.child("locationRequestedUsers/\(userID)").setValue(["locationNeeded" : true])
        }
    }
    
    
    func updateDatabaseWithNearbyUsersIDs() {
        
        let lastKnownNearbyUsersQueryRef = databaseRef.child("nearbyUsers/\(userManager.meUser.userID)/nearby")
        lastKnownNearbyUsersQueryRef.observeSingleEvent(of: .value, with: {[weak self] (nearbySnapshot) in
            guard let `self` = self else {return}
            
            let nearbyUsers = nearbySnapshot.value as? [String : [String : AnyObject]] ?? [:]
            let lastKnownNearbyUserSet: Set<String> = Set(Array(nearbyUsers.keys))
            
            let missingNearbyUsers = lastKnownNearbyUserSet.subtracting(self.userIDsNearby)
            print(missingNearbyUsers)
            
         
            
            
            let timestamp = ["timestamp" : Date().timeIntervalSince1970]
            
            for userID in Set(self.userIDsNearby + missingNearbyUsers).subtracting(self.userManager.metUsers.userIDs) {
                // TODO: - Remove Updating of Other Users
//                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(self.userManager.meUser.userID)").childByAutoId().setValue(timestamp)
                
                self.databaseRef.child("nearbyUsers/\(self.userManager.meUser.userID)/nearby/\(userID)").childByAutoId().setValue(timestamp)
            }
            
            for userID in missingNearbyUsers {
                // TODO: - Remove Updating of Other Users
                //                self.databaseRef.child("nearbyUsers/\(userID)/nearby/\(self.userManager.meUser.userID)").removeValue()
                
                self.databaseRef.child("nearbyUsers/\(self.userManager.meUser.userID)/nearby/\(userID)").removeValue()
            }
        })
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
        observeDatabaseForNearbyUsers()
        observeDatabaseForLocationRequest()
    }
    
    func startLocationDependentDatabaseObservers() {
        observeDatabaseForUsersInRegion()
        observeDatabaseForUsersInNearbyRange()
        
        stateMachine.transitionToState(stateName: "IdleObservingState")
    }
    
    func observeDatabaseForLocationRequest() {
        let locationRequestQueryRef = databaseRef.child("locationRequestedUsers/\(userManager.meUser.userID)")
        let observeHandle = locationRequestQueryRef.observe(.childAdded, with: {[weak self] (requestSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.updateMeUserWithNewLocation()
            
            locationRequestQueryRef.removeValue()
        })
        self.databaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForUsersInRegion() {
        observeDatabaseForUsersInRange(range: KONRegionRange) {[weak self] (successful) in
            if !successful { return }
            guard let `self` = self else { return }
            
            print("Users in Region Range: \(self.userIDsInRegion)")
            self.updateDatabaseWithLocationRequestForUsersIDs(userIDs: self.userIDsInRegion)
            
        }
    }
    
    func observeDatabaseForUsersInNearbyRange() {
        observeDatabaseForUsersInRange(range: KONNearbyRange) {[weak self] (successful) in
            if !successful { return }
            guard let `self` = self else { return }
            
            print("Users in Nearby Range: \(self.userIDsNearby)")
            self.updateDatabaseWithNearbyUsersIDs()
        }
    }
    
    func observeDatabaseForUsersInRange(range: Int, completionHandler: @escaping ((Bool) -> Void)) {
        guard let myLocation = userManager.meUser.locationHash else { return }
        
        let startHash = String(myLocation.characters.prefix(range))
        let endHash = String(myLocation.characters.prefix(range)) + "~"
        
        let locationQueryRef = databaseRef.child("userLocations").queryOrdered(byChild: "location").queryStarting(atValue: startHash).queryEnding(atValue: endHash)
        let observeHandle = locationQueryRef.observe(.value, with: { (locationSnapshot) in
            
            if let users = locationSnapshot.value as? [String: Any] {
                
                var userIDs: Set<String> = Set(users.keys)
                userIDs.remove(self.userManager.meUser.userID)
                
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
                    
                    
                    userIDs.subtract(self.userManager.metUsers.userIDs + previousUserIDsNearby)
                    if userIDs.count > 0 || lostUserIDsNearby.count > 0 {
                        completionHandler(true)
                    }
                }
                completionHandler(false)
            }
        })
        databaseObserverHandles.append(observeHandle)
        locationBasedDatabaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForNearbyUsers() {
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(userManager.meUser.userID)/nearby/").queryOrderedByValue()
        
        let observeHandle = nearbyObserveRef.observe(.childChanged, with: {[weak self] (nearbySnapshot) in
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
        databaseObserverHandles.append(observeHandle)
    }
    
    func observeDatabaseForMetUsers() {
        let metObserveRef = databaseRef.child("metUsers/\(userManager.meUser.userID)/met/").queryOrderedByKey()
        
        let childAddedObserveHandle = metObserveRef.observe(.childAdded, with: {[weak self] (metSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.addMetUsersWithUserIDs(userIDs: [metSnapshot.key])
        })
        databaseObserverHandles.append(childAddedObserveHandle)
        
        let childRemovedObserveHandle = metObserveRef.observe(.childRemoved, with: {[weak self] (lostSnapshot) in
            guard let `self` = self else { return }
            
            self.userManager.removeMetUsersWithUserIDs(userIDs: [lostSnapshot.key])
        })
        databaseObserverHandles.append(childRemovedObserveHandle)
    }
    
    func observeDatabaseForUserValueChangesFor(userID: String) {
        let userObserveRef = databaseRef.child("users/\(userID)")
        
        let observeHandle = userObserveRef.observe(.value, with: {[weak self] (userSnapshot) in
            guard let `self` = self else { return }
            
            print(userSnapshot)
            self.userManager.updateMetUsersWithUserIDs(userIDs: [userSnapshot.key : userSnapshot.value as? [String : Any] ?? [:]])
            
        })
        databaseObserverHandles.append(observeHandle)
        
    }
    
    // MARK: - Helpers
    func updateLocationBasedDatabaseObservers() {
        for observeHandle in locationBasedDatabaseObserverHandles {
            databaseRef.removeObserver(withHandle: observeHandle)
        }
        startLocationDependentDatabaseObservers()
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
}
