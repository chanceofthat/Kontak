//
//  KONState.swift
//  Kontak
//
//  Created by Chance Daniel on 2/21/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONState: NSObject {
    
    // MARK - Properties
    var name: String!
    var enterAction: (()->Void)?
    var attributes: NSDictionary?
    
    var transitionsForLastStateNames: [String : KONStateTransition] = [String : KONStateTransition]()


    // MARK - Init
    init(name: String, enterAction: (()->Void)?, attributes: NSDictionary?) {
        self.name = name
        self.enterAction = enterAction
        self.attributes = attributes
        super.init()
    }
    
    convenience init(name: String, enterAction: (()->Void)?) {
        self.init(name: name, enterAction: enterAction, attributes: nil)
    }
    
    // MARK: - Add Transitions
    func addTransition(_ transition:KONStateTransition, fromStateName stateName: String) {
        assert(transitionsForLastStateNames[stateName] == nil, "Cannot add duplicate transition from state: \(stateName)")
        transitionsForLastStateNames[stateName] = transition
    }
}
