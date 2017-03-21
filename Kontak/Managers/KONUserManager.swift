//
//  KONUserManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit


enum KONUserState: Int {
    case missing = 0, inRegion, nearby, met
}

protocol KONUserManagerDataSource {
    func didMoveUsers(_ userRefs: [KONUserReference], toState state: KONUserState)
}

// MARK: -

class KONUserManager: NSObject, KONStateControllable {
    

    // MARK: - Properties
    static let sharedInstance: KONUserManager = KONUserManager()
    
    private var dataSource: KONUserManagerDataSource?
    
    private let stateController = KONStateController.sharedInstance
    
    dynamic var currentUser: KONUserReference? {
        didSet {
            notifyObserversOfValueChange(#keyPath(KONUserManager.currentUser))
        }
    }
    
    var regionUsers = [KONUserReference]()
    var nearbyUsers = [KONUserReference]()
    dynamic var metUsers = [KONUserReference]() {
        didSet {
            notifyObserversOfValueChange(#keyPath(KONUserManager.metUsers))
        }
    }
    var missingUsers = [KONUserReference]() {
        didSet {
            notifyObserversOfValueChange(#keyPath(KONUserManager.missingUsers))
        }
    }
    
    var usersInRange: [KONUserReference] {
        return regionUsers + nearbyUsers
    }
   
    // Callbacks
    var metControllerUpdateCallback: (() -> Void)?
    
    // Observers
    var observers = KONObservers<KONUserManager>()
    
    func notifyObserversOfValueChange(_ keyPath: String) {
        observers.notify(self, keyPath: keyPath)
    }
    
    // MARK: - 
    
    func registerDataSource(_ dataSource: KONUserManagerDataSource) {
        self.dataSource = dataSource
    }
    
    func unregisterDataSource() {
        dataSource = nil
        regionUsers.removeAll()
        nearbyUsers.removeAll()
        metUsers.removeAll()
    }

    
    // MARK: - KONStateControllable Protocol
    
    func start() {
        registerWithStateController()
    }
    
    func stop() {
        unregisterWithStateController()
        nearbyUsers.removeAll()
        metUsers.removeAll()
    }
    
    func registerWithStateController() {
        
        let currentUserQuery = KONTargetKeyQuery(targetName: self.className, key: #keyPath(KONUserManager.currentUser), evaluationValue: true)
        let currentUserAvailableRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.currentUserAvailableRule, targetKeyQueries: [currentUserQuery])
        
        currentUserAvailableRule.evaluationCallback = { (rule, successful, context) in
            
        }
        
        stateController.registerRules(target: self, rules: [currentUserAvailableRule])
     
    }
    
    func unregisterWithStateController() {
        stateController.unregisterRulesForTarget(self)
    }
    
    // MARK: - Manipulate Users
    
    func addUsers(_ userRefs: [KONUserReference], toState state: KONUserState) {
        switch state {
        case .inRegion:
            regionUsers.append(contentsOf: userRefs)
            break
        case .nearby:
            nearbyUsers.append(contentsOf: userRefs)
            break
        case .met:
            metUsers.append(contentsOf: userRefs)
            break
        case .missing:
            missingUsers.append(contentsOf: userRefs)
            break
        default:
            break
        }
    }
    
    func removeUsers(_ userRefs: [KONUserReference]) {
        
        regionUsers = regionUsers.flatMap { userRefs.contains($0) ? nil : $0 }
        nearbyUsers = nearbyUsers.flatMap { userRefs.contains($0) ? nil : $0 }
        metUsers = metUsers.flatMap { userRefs.contains($0) ? nil : $0 }
        missingUsers = missingUsers.flatMap { userRefs.contains($0) ? nil : $0 }
    }
    
    func moveUsers(_ userRefs: [KONUserReference], toState state: KONUserState) {
        removeUsers(userRefs)
        addUsers(userRefs, toState: state)
        dataSource?.didMoveUsers(userRefs, toState: state)
    }
    
}
