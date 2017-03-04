//
//  KONStateControllerRule.swift
//  Kontak
//
//  Created by Chance Daniel on 3/2/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONTargetKeyInfo: NSObject {
    var targetName: String!
    var key: String!
    var evaluationValue: Bool!
    
    init(targetName: String, key: String, evaluationValue: Bool) {
        self.targetName = targetName
        self.key = key
        self.evaluationValue = evaluationValue
        super.init()
    }
}

class KONStateControllerRule: NSObject {
    
    // MARK: - Properties
    
    var name: String!
//    var ruleDescription: String {
//        get {
//            var description = ""
//            if requiredTrueValueKeys.count > 0 {
//                description += "True-"
//                for key in requiredTrueValueKeys {
//                    description += key
//                }
//                description += "-"
//            }
//            if requiredTrueValueKeys.count > 0 {
//                description += "False-"
//                for key in requiredFalseValueKeys {
//                    description += key
//                }
//            }
//            return description
//        }
//    }
//    var requiredTrueValueKeys: [String] = []
//    var requiredFalseValueKeys: [String] = []
//    var allKeys: [String] {
//        get {
//            return requiredTrueValueKeys + requiredFalseValueKeys
//        }
//    }
    
    var targetKeys: [KONTargetKeyInfo]!
    
    var ruleSuccessCallback: (() -> Void)?
    var ruleFailureCallback: ((String) -> Void)?
    
    // MARK: - Init
    
    init (name: String, targetKeys: [KONTargetKeyInfo]) {
        super.init()
        self.targetKeys = targetKeys
        self.name = name
        
    }
    
//    init(name: String, trueKeys: [String]?, falseKeys: [String]?) {
//        super.init()
//        
//        if let trueKeys = trueKeys {
//            requiredTrueValueKeys = trueKeys
//        }
//        if let falseKeys = falseKeys {
//            requiredFalseValueKeys = falseKeys
//        }
//        self.name = name
//    }
//    
    func succeed() {
        ruleSuccessCallback?()
    }
    
    func fail(failingKey: String) {
        ruleFailureCallback?(failingKey)
    }
    

}
