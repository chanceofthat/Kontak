//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit



// MARK: -

class KONUserManager: NSObject, KONTransportResponder, KONStateControllable {
    
    class MetUsers: NSObject {
        dynamic var flag = 0
        dynamic var users: [KONUserReference] = []
        dynamic var recentUserID: String? {
            get {
                return userIDs.last
            }
        }
        dynamic var userIDs: [String] {
            get {
                return users.flatMap({ (user: KONUserReference) -> String? in
                    if let userID = user.userID {
                        return userID
                    }
                    return nil
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
        
        func userForID(userID: String) -> KONUserReference? {
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
    
    dynamic var currentUser: KONUserReference?
    
    var nearbyUsers = [KONUserReference]() {
        didSet {
            observers.notify(self)
        }
    }
    
    dynamic var metUsers: MetUsers = MetUsers() {
        didSet {
           metControllerUpdateCallback?()
        }
    }
    
    // Callbacks
    var metControllerUpdateCallback: (() -> Void)?
    
    // Observers
    var observers = KONObservers<KONUserManager>()
    
    // MARK: - KONStateControllable Protocol
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {
        unregisterWithStateController()
    }
    
    func registerWithStateController() {
        
        let currentUserQuery = KONTargetKeyQuery(targetName: self.className, key: #keyPath(KONUserManager.currentUser), evaluationValue: true)
        let currentUserAvailableRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.currentUserAvailableRule, targetKeyQueries: [currentUserQuery])
        
        currentUserAvailableRule.evaluationCallback = {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }

            if !successful {
            }
        }
        
        stateController.registerRules(target: self, rules: [currentUserAvailableRule])
     
    }
    
    func unregisterWithStateController() {
        stateController.unregisterRulesForTarget(self)
    }
    
    // MARK: - 
    
    func addMetUsersWithUserIDs(userIDs: [String]) {
        
        for userID in userIDs {
            metUsers.users.append(KONUserReference(userID: userID))
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
