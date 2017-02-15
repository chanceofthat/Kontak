//
//  KONNearbyUser.swift
//  Kontak
//
//  Created by Chance Daniel on 2/11/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONNearbyUser: KONUser {
    
    // MARK: - Properties
    
    
    // MARK: - Init
    init(firstName: String!, lastName: String?) {
        super.init()
        
        name = Name(firstName: firstName, lastName: lastName)
    }

}
