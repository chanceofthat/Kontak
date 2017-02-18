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
        var firstName: String?
        var lastName: String?
        
        init(firstName: String!, lastName: String?) {
            self.firstName = firstName
            self.lastName = lastName
        }
        
        var fullName: String? {
            get {
                if var name: String = firstName {
                    if let lastName = lastName {
                        name += (" " + lastName)
                    }
                    return name
                }
                return nil
            }
        }
    }
    
    /*
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
    */

    
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
    var name: Name?
    var profilePicture: UIImage?
//    var location: KONLocation?
    var locationHash: String?

    override func setValue(_ value: Any?, forKey key: String) {
        if let string = value as? String {
            switch key {
            case "firstName":
                if name == nil {
                    name = Name(firstName: string, lastName: nil)
                }
                else {
                    name?.firstName = string
                }

                break
            case "lastName":
                if name == nil {
                    name = Name(firstName: nil, lastName: string)
                }
                else {
                    name?.lastName = string
                }
            default:
                break
            }
        }
    }
    

}
