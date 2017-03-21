//
//  KONStateControllerRule.swift
//  Kontak
//
//  Created by Chance Daniel on 3/2/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONTargetKeyQuery: NSObject {
    var targetName: String!
    var key: String!
    var evaluationValue: Bool!
    
    /* A evaluationValue of false is mutating and will set the target's value for key to nil */
    init(targetName: String, key: String, evaluationValue: Bool) {
        self.targetName = targetName
        self.key = key
        self.evaluationValue = evaluationValue
        super.init()
    }
}

class KONStateControllerRule: NSObject {
    
    // MARK: - Enums
    
    enum EvaluationCondition {
        case valuesUnchanged
        case valuesChanged
        case valuesSet
        case valuesCleared
    }
    
    // MARK: - Properties
    
    var name: String!
    var ownerClassName: String!
    var targetKeyQueries: [KONTargetKeyQuery]!
    var allKeys: [String] {
        var keys = [String]()
        for query in targetKeyQueries {
            keys.append(query.key)
        }
        return keys
    }
    var associatedKeys: [String] {
        var keys = [String]()
        for query in targetKeyQueries {
            if query.targetName == ownerClassName {
                keys.append(query.key)
            }
        }
        return keys
    }
    var unassociatedKeys: ([String : [String]]) {
        var keysForTarget = [String : [String]]()
        
        for query in targetKeyQueries {
            if query.targetName != ownerClassName {
                if keysForTarget[query.targetName] != nil {
                    keysForTarget[query.targetName]?.append(query.key)
                }
                else {
                    keysForTarget[query.targetName] = [query.key]
                }
            }
        }
        return keysForTarget
    }

    private var _initalSuccess = false
    private var _evaluationCondition: EvaluationCondition!
    var evaluationCondition: EvaluationCondition {
        get {
            if !_initalSuccess {
                return .valuesChanged
            }
            return _evaluationCondition
        }
        set  {
            _evaluationCondition = newValue
        }
    }
    
    var showRuleDebug = false
    
    var evaluationCallback: ((_ rule: KONStateControllerRule, _ result: Bool, _ context: [String : Any]?) -> Void)?
    
    // MARK: - Init
    
   
    
    
    convenience init (owner: NSObject, name: String, targetKeyQueries: [KONTargetKeyQuery]) {
        self.init(owner: owner, name: name, targetKeyQueries: targetKeyQueries, evaluationCallback: nil)
    }
    
    convenience init (owner: NSObject, name: String, targetKeyQueries: [KONTargetKeyQuery], condition: EvaluationCondition) {
        self.init(owner: owner, name: name, targetKeyQueries: targetKeyQueries, condition: condition, evaluationCallback: nil)
    }
    
    convenience init (owner: NSObject, name: String, targetKeyQueries: [KONTargetKeyQuery], evaluationCallback: ((_ rule: KONStateControllerRule, _ result: Bool, _ context: [String : Any]?) -> Void)?) {
        self.init(owner: owner, name: name, targetKeyQueries: targetKeyQueries, condition: .valuesChanged, evaluationCallback: evaluationCallback)
    }
    
    init (owner: NSObject, name: String, targetKeyQueries: [KONTargetKeyQuery], condition: EvaluationCondition, evaluationCallback: ((_ rule: KONStateControllerRule, _ result: Bool, _ context: [String : Any]?) -> Void)?) {
        super.init()
        self.targetKeyQueries = targetKeyQueries
        self.name = [owner.className, name].joined(separator: ".")
        self.ownerClassName = owner.className
        self.evaluationCondition = condition
        self.evaluationCallback = evaluationCallback
    }
    
    func didEvaluateWithResult(_ result: Bool, context: [String : Any]?) {
        if showRuleDebug {
            print("Rule named: \(self.name!) was\(result ? "" : " not") successful \(result ? "✅" : "❌")")
            if let failedKeys = context?[Constants.StateController.RuleContextKeys.failedKeys] as? [String] {
                print("Rule failed on key(s): \(failedKeys)")
            }
        }
        self._initalSuccess = result
        evaluationCallback?(self, result, context)
    }

}
