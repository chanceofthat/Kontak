
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage


// MARK: - StateController Extension 

extension KONStateController {
    
    func setUserManagerDataSource(_ source: KONUserManagerDataSource) {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            userManager.registerDataSource(source)
        }
    }
    
    func removeUserManagerDataSource() {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            userManager.unregisterDataSource()
        }
    }
    
    func queryForCurrentUserID() -> String? {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            return userManager.currentUser?.userID
        }
        return nil
    }
   
    func notifyUserManagerObservers() {
        KONUserManager.sharedInstance.notifyObserversOfValueChange(#keyPath(KONUserManager.nearbyUsers))
    }
}

// MARK: - KONNetworkManager

class KONNetworkManager: NSObject, KONStateControllable, KONUserManagerDataSource {
    
    // MARK: - Properties
    
    static let sharedInstance: KONNetworkManager = KONNetworkManager()
    
    var databaseRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    
    private var userBasedDatabaseObserverHandles: [FIRDatabaseHandle] = []
    private var locationBasedDatabaseObserverHandles: [FIRDatabaseQuery] = []
    private var startedUserBasedDatabaseObservers = false
    private var startedLocationBasedDatabaseObservers = false
    
    lazy var stateController = KONStateController.sharedInstance
    lazy var userManager = KONUserManager.sharedInstance
    
    // Diagnostic
    var userStateControllerCallbacks = [() -> Void]()
    var allowMet = true
    
    // MARK: - Init
    override init() {
        super.init()
        
        // Set Up Database
        databaseRef = FIRDatabase.database().reference()
    
        // Set Up Storage
        storageRef = FIRStorage.storage().reference()
        
    }
    
    // MARK: - KONStateControllable Protocol
    
    func start() {
        registerWithStateController()
        registerWithUserStateController()
        
        if let currentUser = userManager.currentUser {
            updateDatabaseWithCurrentUser(currentUser)
        }
        else {
        
            userManager.observers.observe(observer: self) {[weak self] (userManager, keyPath) in
                guard let `self` = self else { return }
                if keyPath == #keyPath(KONUserManager.currentUser), let currentUser = userManager.currentUser {
                    self.updateDatabaseWithCurrentUser(currentUser)
                }
            }
        }
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
                    self.startUserBasedDatabaseObservers()
                    self.updateLocationForUser(userRef: currentUser, locationHash: locationHash)
                    self.updateLocationBasedDatabaseObserversWithLocation(locationHash)
                }
            }
        }
        
        // TODO: - Fix met users updating
        
        let metUsersQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.metUsers), evaluationValue: true)
        let metUsersUpdatedRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.updatedMetUsersAvailable, targetKeyQueries: [metUsersQuery])
        metUsersUpdatedRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
            if successful {
                if let context = context {
                    for key in rule.allKeys {
                        if let metUserRefs = context[key] as? [KONUserReference] {
                            for metUserRef in metUserRefs {
                                self.observeDatabaseForProfileValueChangesForUser(userRef: metUserRef)
                            }
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
        stateController.setUserManagerDataSource(self)
    }
    
    func unregisterWithUserStateController() {
        stateController.removeUserManagerDataSource()
    }
    
    // MARK: - KONUserStateControllerDataSource Protocol
    
    func didMoveUsers(_ userRefs: [KONUserReference], toState state: KONUserState) {
//        print("Moved Users: \(userRefs) to State: \(state)")
        
        switch state {
        case .missing:
            // Process Missing Users 
            processMissingUsers(userRefs)
            
            break
        case .inRegion:
            // Update Database
            updateDatabaseWithLocationRequestForUsers(userRefs)
            
            break
        case .nearby:
            // Update Database
            updateDatabaseWithNearbyUsers(userRefs)
            
            // Update UserRefs
            for userRef in userRefs {
                queryDatabaseForUserProfileForUser(userRef, completion: {[weak self] (userRef) in
                    guard let `self` = self else { return }
                    self.stateController.notifyUserManagerObservers()
                })
            }
            
            break
        case .met:
            // Update Database
            updateDatabaseWithMetUsers(userRefs)
            
            break
        default:
            break
        }
        
        
        // DIAGNOSTIC
        for callback in userStateControllerCallbacks {
            callback()
        }
        
    }
    
    
    // MARK: - Database Updates
    
    func updateDatabaseWithCurrentUser(_ userRef: KONUserReference) {
        if let userID = userRef.userID,let firstName = userRef.firstName, let lastName = userRef.lastName, let profileImage = userRef.profilePicture, let bio = userRef.bio {
            
            let profileInfo = ["firstName"      : firstName,
                               "lastName"       : lastName,
                               "bio"            :  bio,
                               "contactMethods" : userRef.contactMethodDictionary] as [String : Any]
            
            databaseRef.child("users").child(userID).setValue(profileInfo)
            
            let profileImageRef = storageRef.child("profileImages").child(userID).child("profileImage.jpg")
            if let profileImageData = UIImageJPEGRepresentation(profileImage, 1.0) {
                
                let _ = profileImageRef.put(profileImageData, metadata: nil, completion: {[weak self] (metadata, error) in
                    guard let `self` = self else { return }
                    guard let metadata = metadata else { return }
                    
                    let downloadURLs = metadata.downloadURLs
                    if let downloadURL = downloadURLs?.first {
                        self.databaseRef.child("users").child(userID).updateChildValues(["profileImageURL" : downloadURL.absoluteString])
                    }
                })
            }
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

//        print("Process missing users: \(userRefs)")
        
        for userRef in userRefs {
            if let userID = userRef.userID {
                
                queryDatabaseForTimestampsForUserID(userID, completion: {[weak self] (timestamps) in
                    guard let `self` = self else { return }
                    
                    // Sort Timestamps
                    var timestamps = timestamps.sorted()
                    
                    if timestamps.count == 1 {
                        let nowStamp = Date().timeIntervalSince1970
                        timestamps.append(nowStamp)
                    }
                    
                    if let firstTime = timestamps.first, let lastTime = timestamps.last {
                        let meetDuration = (lastTime - firstTime) / 60
                        
//                        print("Saw \(userID) for \(meetDuration) minutes")

                        if (meetDuration > KONMeetDuration) {
                            if (self.allowMet) {
                                self.userManager.moveUsers([userRef], toState: .met)
                                
                            }
                        }
                        else {
                            self.databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)").removeValue()
                        }
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
            databaseRef.child("metUsers/\(userID)").removeValue()

        }
    }
    
    // MARK: - Database Observing
    
    func startUserBasedDatabaseObservers() {
        if startedUserBasedDatabaseObservers { return }
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
        for query in locationBasedDatabaseObserverHandles {
            query.removeAllObservers()
        }
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
                
                let userRefs = Set(KONUserReference.userRefsFromUserIDs(Array(userIDs)))
                
                let previouslyMetUsers = self.userManager.metUsers
                let previousUsersInRange = self.userManager.usersInRange
                var newUsersInRange: Set<KONUserReference>
                var missingUsersInRange:Set <KONUserReference>
                
                
                let state: KONUserState = range == KONRegionRange ? .inRegion : .nearby
                
                if state == .inRegion {
                    newUsersInRange = userRefs.subtracting(previousUsersInRange + previouslyMetUsers)
                    missingUsersInRange = Set(previousUsersInRange).subtracting(userRefs)
                }
                else {
                    newUsersInRange = userRefs.subtracting(self.userManager.nearbyUsers + previouslyMetUsers)
                    missingUsersInRange = Set(self.userManager.nearbyUsers).subtracting(userRefs)
                }
                
                if newUsersInRange.count + missingUsersInRange.count == 0 { return }
                
                // Place New Users In Range 
                if newUsersInRange.count > 0 {
                    self.userManager.moveUsers(Array(newUsersInRange), toState: state)
                }
                
                
                /*
                
                print("##########################################")
                print("Range: \(range)")
                print("Previously Met Users: \(previouslyMetUsers)")
                print("Previous Users in Range: \(previousUsersInRange)")
                print("Missing Users: \(missingUsersInRange)")
                print("All Users in Snapshot: \(userRefs)")
                print("New Users: \(newUsersInRange)")
                print("##########################################")
                 */

                // Process Missing Users
                if missingUsersInRange.count > 0 {
                    self.userManager.moveUsers(Array(missingUsersInRange), toState: KONUserState(rawValue: state.rawValue - 1)!)
                }
               
                
            }
        })
        locationBasedDatabaseObserverHandles.append(locationQueryRef)
    }
    
    func observeDatabaseForProfileValueChangesForUser(userRef: KONUserReference) {
        
        if let userID = userRef.userID {
            let userObserveRef = databaseRef.child("users/\(userID)")
            
            let observeHandle = userObserveRef.observe(.value, with: {[weak self] (userSnapshot) in
                guard let `self` = self else { return }
                
                if let profile = userSnapshot.value as? [String : Any] {
                    self.parseProfile(profile: profile, intoUserReference: userRef, completion: { (updatedUserRef) in
                        self.stateController.notifyUserManagerObservers()
                    })
                }
            })
            userBasedDatabaseObserverHandles.append(observeHandle)
        }
    }
    
    // MARK: - Database Queries
    
    func queryDatabaseForTimestampsForUserID(_ userID: String, completion: @escaping ([TimeInterval]) -> Void) {
        guard let currentUserID = stateController.queryForCurrentUserID() else { return }
        
        let nearbyObserveRef = databaseRef.child("nearbyUsers/\(currentUserID)/nearby/\(userID)")
        
        nearbyObserveRef.observeSingleEvent(of: .value, with: { (timestampSnapshot) in
            

            let deviceTimestamps = timestampSnapshot.value as? [String : [String : AnyObject]] ?? [:]
            if let timestampArray = Array(deviceTimestamps.values) as? [[String : TimeInterval]] {
                let timestamps = timestampArray.flatMap({ $0["timestamp"] })
                completion(timestamps)
            }

        })

    }
    
    func queryDatabaseForUserProfileForUser(_ userRef: KONUserReference, completion: @escaping (KONUserReference) -> Void) {
        guard let userID = userRef.userID else { return }
        
        let userProfileRef = databaseRef.child("users/\(userID)")
        
        userProfileRef.observeSingleEvent(of: .value, with: {[weak self] (profileSnapshot) in
            guard let `self` = self else { return }
            if let profile = profileSnapshot.value as? [String : Any] {
                self.parseProfile(profile: profile, intoUserReference: userRef, completion: completion)
            }
            
        })
    }
    
    // MARK: - Helpers
    
    func updateLocationBasedDatabaseObserversWithLocation(_ locationHash: String) {
        removeLocationBasedDatabaseObservers()
        startLocationBasedDatabaseObserversWithLocation(locationHash)
    }
    
    func parseProfile(profile: [String : Any], intoUserReference userRef: KONUserReference, completion: @escaping (KONUserReference) -> Void) {
        guard let userID = userRef.userID else { return }

        if let firstName = profile["firstName"] as? String, let lastName = profile["lastName"] as? String, let bio = profile["bio"] as? String {
            userRef.firstName = firstName
            userRef.lastName = lastName
            userRef.bio = bio
            
            if let contactMethods = profile["contactMethods"] as? [String : String] {
                userRef.contactMethodDictionary = contactMethods
            }
            
            let profileImageRef = self.storageRef.child("profileImages").child(userID).child("profileImage.jpg")
            profileImageRef.data(withMaxSize: Int64(20 * 1024 * 1024), completion: { (imageData, error) in
                if error == nil {
                    if let imageData = imageData {
                        userRef.profilePicture = UIImage(data: imageData)
                    }
                }
                completion(userRef)
            })
        }
    }

}
