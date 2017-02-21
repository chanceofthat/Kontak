//
//  KONStateTransition.swift
//  Kontak
//
//  Created by Chance Daniel on 2/21/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONStateTransition: NSObject {
    
    // MARK: - Properties
    var transitionAction: ()->Void
    
    // MARK: - Init
    init(action: @escaping ()->Void) {
        transitionAction = action
        super.init()
    }
    

}
