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
    func didChangeUserIDs(_ userIDs: [String], toState state: KONUserState)
    func didRemoveUserID(_ userID: String)
    func didLoseUserID(_ userID: String)
}

class KONUserStateController: NSObject {
    
    
    // MARK: - Properties
    static let sharedInstance = KONUserStateController()
    
    private var dataSource: KONUserStateControllerDataSource?
    var regionUserIDs = [String]()
    var nearbyUserIDs = [String]()
    var metUserIDs = [String]()
    var missingUserIDs = [String]()
    
    
    
    // MARK: -
    private override init() {}
    
    func registerDataSource(_ dataSource: KONUserStateControllerDataSource) {
        self.dataSource = dataSource
    }
    
    func unregisterDataSource() {
        dataSource = nil
        regionUserIDs.removeAll()
        nearbyUserIDs.removeAll()
        metUserIDs.removeAll()
//        missingUserIDs.removeAll()
    }
    
    func addUserIDs(_ userIDs: [String], forState state: KONUserState) {
        switch state {
        case .inRegion:
            regionUserIDs.append(contentsOf: userIDs)
            break
        case .nearby:
            nearbyUserIDs.append(contentsOf: userIDs)
            break
        case .met:
            metUserIDs.append(contentsOf: userIDs)
            break
//        case .missing:
//            missingUserIDs.append(contentsOf: userIDs)
        default:
            break
        }
        
        dataSource?.didChangeUserIDs(userIDs, toState: state)
    }
    
    func moveUserIDs(_ userIDs: [String], toState state: KONUserState) {
        
        removeUserIDs(userIDs)
        addUserIDs(userIDs, forState: state)
    }
    
    func removeUserIDs(_ userIDs: [String]) {
        for userID in userIDs {
            if let index = regionUserIDs.index(of: userID) {
                dataSource?.didLoseUserID(userID)
                regionUserIDs.remove(at: index)
            }
            
            if let index = nearbyUserIDs.index(of: userID) {
                nearbyUserIDs.remove(at: index)
            }
            
            if let index = metUserIDs.index(of: userID) {
                metUserIDs.remove(at: index)
            }
            
            if let index = missingUserIDs.index(of: userID) {
                missingUserIDs.remove(at: index)
            }
            dataSource?.didRemoveUserID(userID)
        }
    }
    
    func stateForUserID(_ userID: String) -> KONUserState {
        if regionUserIDs.contains(userID) { return .inRegion }
        if nearbyUserIDs.contains(userID) { return .nearby }
        if metUserIDs.contains(userID) { return .met }
//        if missingUserIDs.contains(userID) { return .missing }
        
        return .missing
    }
    
    

}
