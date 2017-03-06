//
//  KONMetUser.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMetUser: KONUser {

    // MARK: - Properties
    var bio: String?
    var phoneNumber: String?
    var emailAddress: String?
    var snapchatUsername: String?
    var instagramUsername: String?
    var facebookUsername: String?
    
    init(firstName: String!, lastName: String?, userID: String) {
        super.init()
        self.userID = userID
        name = Name(firstName: firstName, lastName: lastName)
    }
    
    convenience init(userID: String) {
        self.init(firstName: nil, lastName: nil, userID: userID)
    }
}
