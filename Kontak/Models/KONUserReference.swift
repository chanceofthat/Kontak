//
//  KONUserReference.swift
//  Kontak
//
//  Created by Chance Daniel on 3/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONUserReference: NSObject {
    
    // MARK: - Properties
    
    var firstName: String?
    var lastName: String?
    var fullName: String? {
        var _fullName: String? = firstName
        
        if lastName != nil {
            if _fullName != nil {
                _fullName!.append(" \(lastName!)")
            }
            else {
                _fullName = lastName!
            }
        }
        return _fullName
    }
    
    var userID: String?
    
    var profilePicture: UIImage?
    var bio: String?
    var contactMethodDictionary = [String : String]()
    
    // MARK: - Init 
    
    convenience init(userID: String) {
        self.init(firstName: nil, lastName: nil, userID: userID)
    }
    
    convenience init(firstName: String, lastName: String?) {
        self.init(firstName: firstName, lastName: lastName, userID: UIDevice.current.identifierForVendor?.uuidString)
    }
    
    init(firstName: String?, lastName: String?, userID: String?) {
        super.init()

        self.firstName = firstName
        self.lastName = lastName
        self.userID = userID
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let userRef = object as? KONUserReference {
            return self.userID == userRef.userID
        }
        return false
    }
    
    static func userRefsFromUserIDs(_ userIDs: [String]) -> [KONUserReference] {
        var userRefs = [KONUserReference]()
        for userID in userIDs {
            userRefs.append(KONUserReference(userID: userID))
        }
        return userRefs
    }
    
    override var description: String {
        var description: String = ""
        
        if let fullName = fullName {
            description = "Name: \(fullName) "
        }
        if let userID = userID {
            description.append("UserID: \(userID)")
        }
        
        return description
    }

}


