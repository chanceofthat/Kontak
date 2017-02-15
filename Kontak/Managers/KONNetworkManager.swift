
//  KONNetworkManager.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase

protocol KONNetworkManagerDelegate: class {
    func didFindNewMetUsers()
}

class KONNetworkManager: NSObject {
    
    private struct UsersInRange {
        
        var usersInLatRange: [String] = []
//        {
//            didSet {
//                if usersInLonRange.count > 0 {
//                    KONNetworkManager.instanceMethod(for: #selector(KONNetworkManager.queryDatabaseForMetUserRecords))
//                }
//            }
//        }
        var usersInLonRange: [String] = []
//        {
//            didSet {
//                if usersInLatRange.count > 0 {
//                    KONNetworkManager.instanceMethod(for: #selector(KONNetworkManager.queryDatabaseForMetUserRecords))
//                }
//            }
//        }
        var hasUsers: Bool {
            get {
                return usersInLatRange.count > 0 && usersInLonRange.count > 0
            }
        }

    }
    
    // MARK: - Properties
    var ref: FIRDatabaseReference!
    private var usersInRange: UsersInRange = UsersInRange()
    weak var delegate: KONNetworkManagerDelegate?


    override init() {
        super.init()
        ref = FIRDatabase.database().reference()
    }
    
    func createNewUserDatbaseRecord(user: KONMeUser) {
        ref.child("users").child(user.userID).setValue(["firstName" : user.name.firstName, "lastName" : user.name.lastName])
    }
    
    func createMetUserFromDatabaseRecord() {
        
    }
    
    func updateLocationRecordForUser(user: KONMeUser) {
        
//        ref.child("locations/location").setValue(["latitude" : coordinate.latitude, "longitude" : coordinate.longitude, "timestamp" : timestamp.timeIntervalSince1970, "user" : user.userID])
        if let location = user.location {
            ref.child("users/\(user.userID)/location").setValue(["latitude" : location.latitude, "longitude" : location.longitude, "timestamp" : location.timestamp.timeIntervalSince1970])
        }
        
    }
    
    
    
    func queryDatabaseForMetUserIDs() {
        
        if let myLocation = KONUserManager.sharedInstance.meUser.location {
            let locationRange = KONLocationManager.locationRangeFromLocation(location: myLocation, radius: 0.003)
            
            let latQueryRef = ref.child("users").queryOrdered(byChild: "location/latitude").queryStarting(atValue: locationRange.latMin).queryEnding(atValue: locationRange.latMax)
            

            latQueryRef.observeSingleEvent(of: .value, with: {[weak self] (snapshot) in
//                print(snapshot)
                
                guard let `self` =  self else {return}
                
                if let users = snapshot.value as? [String: Any] {
                    for user in users {
                        if (user.key != KONUserManager.sharedInstance.meUser.userID) {
                            self.usersInRange.usersInLatRange.append(user.key)
                        }
                    }
                }
                if self.usersInRange.hasUsers {
                    self.queryDatabaseForMetUserRecords()
                }
            })
            
            let lonQueryRef = ref.child("users").queryOrdered(byChild: "location/longitude").queryStarting(atValue: locationRange.lonMin).queryEnding(atValue: locationRange.lonMax)
            
            lonQueryRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                print(snapshot)
                if let users = snapshot.value as? [String: Any] {
                    for user in users {
                        if (user.key != KONUserManager.sharedInstance.meUser.userID) {
                            self.usersInRange.usersInLonRange.append(user.key)
                        }
                    }
                }
                if self.usersInRange.hasUsers {
                    self.queryDatabaseForMetUserRecords()
                }
            })
        }
    }
    
    func queryDatabaseForMetUserRecords() {
        let latSet:Set<String> = Set(usersInRange.usersInLatRange)
        let lonSet:Set<String> = Set(usersInRange.usersInLonRange)
        
        let commonUsers = latSet.intersection(lonSet)
        
        for userID in commonUsers {
            let metUserQueryRef = ref.child("users/\(userID)")
            metUserQueryRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                print(snapshot)
                if let firstName = snapshot.childSnapshot(forPath: "firstName").value as? String {
                    print(firstName)
                }
            })
        }
        
        usersInRange.usersInLonRange.removeAll()
        usersInRange.usersInLatRange.removeAll()
        
    }
    
    
    

}
