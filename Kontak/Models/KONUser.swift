//
//  KONUser.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import CoreLocation

class KONUser: NSObject {
    
    struct Name {
        let firstName: String!
        var lastName: String?
        
        init(firstName: String!, lastName: String?) {
            self.firstName = firstName
            self.lastName = lastName
        }
        
        var fullName: String {
            get {
                var name: String = firstName
                if let lastName = lastName {
                    name += (" " + lastName)
                }
                return name
            }
        }
    }
    
    struct KONLocation {
        private let location: CLLocation!
        
        init(location: CLLocation) {
            self.location = location
        }
        
        var longitude: Double {
            get {
                return location.coordinate.longitude
            }
        }
        
        var latitude: Double {
            get {
                return location.coordinate.latitude
            }
        }
        
        var timestamp: Date {
            get {
                return location.timestamp
            }
        }
    }
    
    // MARK: - Properties
    private var _userID: String!
    var userID: String {
        get {
            if (_userID != nil) {
                return _userID
            }
            
            //TESTING ONLY
            _userID = "Device3"
            return _userID
            //

            let defaults = UserDefaults.standard
            if let id = defaults.value(forKey: KONDefaultsUserIDKey) as? String {
                _userID = id
            }
            else {
                _userID = UUID().uuidString
                defaults.setValue(self.userID, forKey: KONDefaultsUserIDKey)
            }
            return _userID
        }
        set(userID) {
            if _userID == nil {
                _userID = userID
            }
        }
    }
    var name: Name!
    var profilePicture: UIImage?
    var location: KONLocation? {
        didSet {
            KONUserManager.sharedInstance.networkManager.observeDatabaseForPotentialUsersInRange()
        }
    }

    

}
