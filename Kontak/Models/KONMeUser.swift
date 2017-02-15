//
//  KONMeUser.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMeUser: KONUser {
    
    // MARK: - Properties
    var bio: String?
    var phoneNumber: String?
    var emailAddress: String?
    var snapchatUsername: String?
    var instagramUsername: String?
    var facebookUsername: String?
    
    init(firstName: String!, lastName: String?) {
        super.init()
        
        name = Name(firstName: firstName, lastName: lastName)
    }
    

}
