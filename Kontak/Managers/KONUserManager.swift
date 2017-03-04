//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
//import CoreLocation

class KONUserManager: NSObject, KONLocationManagerDelegate, KONStateControllerEvaluationObserver {
    
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
        
    dynamic var meUser: KONMeUser!
    var nearbyUsers: [KONNearbyUser] = []
    
    var metUsers: MetUsers = MetUsers() {
        didSet {
           metControllerUpdateCallback?()
        }
    }
    
    // Callbacks
    var metControllerUpdateCallback: (() -> Void)?
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    

    func start() {
        registerWithStateController()
        
//        createDummyNearbyUsers()
    }
    
    // MARK: - State Controller
    
    func registerWithStateController() {
        let stateController = KONStateController.sharedInstance
        
        let value = true
        let meUserTargetKey = KONTargetKeyInfo(targetName: self.className, key: #keyPath(KONUserManager.meUser), evaluationValue: value)
        let meUserAvailableRule = KONStateControllerRule(name: Constants.StateController.RuleNames.meUserAvailableRule, targetKeys: [meUserTargetKey])
        
        meUserAvailableRule.ruleFailureCallback = {[weak self] (reason) in
            guard let `self` = self else { return }
            self.populateMeUser()
        }
        
        stateController.registerRules(target: self, rules: [meUserAvailableRule])
    }
    
    // MARK: - 
    
    func populateMeUser() {
        meUser = KONMeUser(firstName: "Chance", lastName: "Daniel")
    }
    
    func addMetUsersWithUserIDs(userIDs: [String]) {
        /*
        for userID in userIDs {
            metUsers.users.append(KONMetUser(userID: userID))
            networkManager.observeDatabaseForUserValueChangesFor(userID: userID)
        }
         */
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
        /*
        locationManager.requestLocation()
         */
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
        /*
        networkManager.updateLocationForUser(user: meUser)
         */
    }
    
    // MARK: - KONStateControllerEvaluationObserver Protocol
    func didEvaluateRule(ruleName: String, successful: Bool, context: [String : Any]?) {
//        print("Rule: \(ruleName), was \(successful ? "" : "not ")successful")
        
    }
    
    
}
