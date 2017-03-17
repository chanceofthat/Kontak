//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
//import CoreLocation

class KONUserManager: NSObject, KONTransportResponder, KONStateControllable {
    
    class MetUsers: NSObject {
        dynamic var flag = 0
        dynamic var users: [KONMetUser] = []
        dynamic var recentUserID: String? {
            get {
                return userIDs.last
            }
        }
        dynamic var userIDs: [String] {
            get {
                return users.flatMap({ (user: KONMetUser) -> String in
                    return user.userID
                })
            }
        }
        
        dynamic class func keyPathsForValuesAffectingRecentUserID() -> Set<String> {
            return ["users"]
        }
        
        dynamic class func keyPathsForValuesAffectingUserIDs() -> Set<String> {
            return ["users"]
        }
        
        dynamic class func keyPathsForValuesAffectingUsers() -> Set<String> {
            return ["flag"]
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
    
    private let stateController = KONStateController.sharedInstance

    dynamic var meUser: KONMeUser!
    var nearbyUsers: [KONNearbyUser] = []
    
    dynamic var metUsers: MetUsers = MetUsers() {
        didSet {
           metControllerUpdateCallback?()
        }
    }
    
    // Callbacks
    var metControllerUpdateCallback: (() -> Void)?
    
    // MARK: - KONStateControllable Protocol
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {
        unregisterWithStateController()
    }
    
    func registerWithStateController() {
        
        let value = true
        let meUserQuery = KONTargetKeyQuery(targetName: self.className, key: #keyPath(KONUserManager.meUser), evaluationValue: value)
        let meUserAvailableRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.meUserAvailableRule, targetKeyQueries: [meUserQuery])
        
        meUserAvailableRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }

            if !successful {
                self.populateMeUser()
            }
        }
        
        stateController.registerRules(target: self, rules: [meUserAvailableRule])
    }
    
    func unregisterWithStateController() {
        stateController.unregisterRulesForTarget(self)
    }
    
    // MARK: - 
    
    func populateMeUser() {
        meUser = KONMeUser(firstName: "Chance", lastName: "Daniel")
    }
    
    func addMetUsersWithUserIDs(userIDs: [String]) {
        
        for userID in userIDs {
            metUsers.users.append(KONMetUser(userID: userID))
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
            metUsers.flag += 1
            if let user = metUsers.userForID(userID: userID) {
                user.setValuesForKeys(infoDict)
                metControllerUpdateCallback?()
            }
        }
    }

    
    // MARK: - Fake Data
    func createDummyNearbyUsers() {
        for user in 0..<10 {
            nearbyUsers.append(KONNearbyUser(firstName: "Nearby\(user)", lastName: nil))
        }
    }
    
    
    /* MARK: - KONLocationManagerDelegate
    
    func didUpdateCurrentLocation(locationHash: String) {
      
        meUser.locationHash = locationHash
        /*
        networkManager.updateLocationForUser(user: meUser)
         */
    }
 */
    
    // MARK: - KONTransportObserver Protocol 
    
    func didReceiveData(_ data: Any) {
        if let userID = data as? String {
            self.addMetUsersWithUserIDs(userIDs: [userID])
        }
    }
    
    func didRemoveData(_ data: Any) {
        if let userID = data as? String {
            self.removeMetUsersWithUserIDs(userIDs: [userID])
        }
    }
    
    func didChangeData(_ data: Any) {
        if let updatedUserIDs = data as? [String : [String : Any]] {
            updateMetUsersWithUserIDs(userIDs: updatedUserIDs)
        }
        
    }
}
