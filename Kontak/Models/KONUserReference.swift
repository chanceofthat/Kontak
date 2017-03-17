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
    
    var firstName: String!
    var lastName: String?
    var fullName: String {
        var _fullName = firstName!
        if let lastName = lastName {
            _fullName.append(" \(lastName)")
        }
        return _fullName
    }
    
    var userID: String?
    
    var bio: String?
    
    // MARK: - Init 
    
    init(firstName: String, lastName: String?) {
        super.init()
        
        self.firstName = firstName
        self.lastName = lastName
        self.userID = UIDevice.current.identifierForVendor?.uuidString
    }
    

}
