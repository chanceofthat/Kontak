//
//  KONUserStateController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/7/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

enum KONUserState: Int {
    case missing = 0, inRegion, nearby, met
}

protocol KONUserStateControllerDataSource {
    func didChangeUsers(_ userRefs: [KONUserReference], toState state: KONUserState)
    func didRemoveUser(_ userRef: KONUserReference)
    func didLoseUser(_ userRef: KONUserReference)
}

class KONUserStateController: NSObject {
    
    
    // MARK: - Properties
    static let sharedInstance = KONUserStateController()
    
    private var dataSource: KONUserStateControllerDataSource?
    
    var regionUsers = [KONUserReference]()
    var nearbyUsers = [KONUserReference]()
    var metUsers = [KONUserReference]()
    var missingUsers = [KONUserReference]()
    
//    var regionUserIDs = [String]()
//    var nearbyUserIDs = [String]()
//    var metUserIDs = [String]()
//    var missingUserIDs = [String]()
    
    // MARK: -
    private override init() {}
    
    func registerDataSource(_ dataSource: KONUserStateControllerDataSource) {
        self.dataSource = dataSource
    }
    
    func unregisterDataSource() {
        dataSource = nil
        regionUsers.removeAll()
        nearbyUsers.removeAll()
        metUsers.removeAll()
    }
    
    func addUsers(_ userRefs: [KONUserReference], forState state: KONUserState) {
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
//        case .missing:
//            missingUserIDs.append(contentsOf: userIDs)
        default:
            break
        }
        
        dataSource?.didChangeUsers(userRefs, toState: state)
    }
    
    func moveUsers(_ userRefs: [KONUserReference], toState state: KONUserState) {
        
        removeUsers(userRefs)
        addUsers(userRefs, forState: state)
    }
    
    func removeUsers(_ userRefs: [KONUserReference]) {
        for userRef in userRefs {
            if let index = regionUsers.index(of: userRef) {
                dataSource?.didLoseUser(userRef)
                regionUsers.remove(at: index)
            }
            
            if let index = nearbyUsers.index(of: userRef) {
                nearbyUsers.remove(at: index)
            }
            
            if let index = metUsers.index(of: userRef) {
                metUsers.remove(at: index)
            }
            
            if let index = missingUsers.index(of: userRef) {
                missingUsers.remove(at: index)
            }
            dataSource?.didRemoveUser(userRef)
        }
    }
    
    func stateForUser(_ userRef: KONUserReference) -> KONUserState {
        if regionUsers.contains(userRef) { return .inRegion }
        if nearbyUsers.contains(userRef) { return .nearby }
        if metUsers.contains(userRef) { return .met }
//        if missingUserIDs.contains(userID) { return .missing }
        
        return .missing
    }
    
    

}
