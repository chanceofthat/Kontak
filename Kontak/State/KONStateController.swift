//
//  KONStatusController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/2/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

protocol KONStateControllable {
    func start()
    func stop()
}

// MARK: - Transport

enum TransportEventType {
    case dataReceived
    case dataRemoved
    case dataChanged
}

protocol KONTransportResponder: AnyObject {
    func didReceiveData(_ data: Any)
    func didRemoveData(_ data: Any)
    func didChangeData(_ data: Any)
}

protocol KONTransportObserver: AnyObject {
    func observeTransportEvent(_ event: TransportEventType);
}

// MARK: - KONWeakObject

class KONWeakObject: Hashable, Equatable {
    weak var value : NSObject?
    init (value: NSObject) {
        self.value = value
    }
    var hashValue: Int {
        if let value = value {
            return value.className.hashValue
        }
        return 0
    }
}

func ==(lhs: KONWeakObject, rhs: KONWeakObject) -> Bool {
    if let lhs = lhs.value, let rhs = rhs.value {
        return lhs == rhs
    }
    return false
}

// MARK: - Target Observer

class KONTargetObserver: NSObject {
    weak var owner: KONStateController?
    
    /*private*/ var targets = Set<KONWeakObject>()
    /*private*/ var keyPathsForTarget: [Int : Set<String>] = [:]
    private var observerContext = 0
    
    func addTarget(target: KONWeakObject, keyPaths: [String]) {
        
        targets.insert(target)
        var newKeys: Set<String> = Set(keyPaths)
        if let oldKeys = keyPathsForTarget[ObjectIdentifier(target).hashValue] {
            newKeys = Set(keyPaths).subtracting(oldKeys)
            keyPathsForTarget[ObjectIdentifier(target).hashValue]?.formUnion(keyPaths)
        }
        else {
            keyPathsForTarget[ObjectIdentifier(target).hashValue] = Set(keyPaths)
        }
//        keyPathsForTarget[ObjectIdentifier(target).hashValue] = keyPaths
        if newKeys.count > 0 {
            registerForObservationOfKeyPaths(target: target.value!, keyPaths: Array(newKeys))
        }
        
    }
    
    func removeTarget(_ target: KONWeakObject) {
        if let keyPaths = keyPathsForTarget[ObjectIdentifier(target).hashValue] {
            for keyPath in keyPaths {
                target.value?.removeObserver(self, forKeyPath: keyPath, context: &observerContext)
            }
        }
        keyPathsForTarget.removeValue(forKey: ObjectIdentifier(target).hashValue)
    }
    
    func registerForObservationOfKeyPaths(target: NSObject, keyPaths: [String]) {
        for keyPath in keyPaths {
            target.addObserver(self, forKeyPath: keyPath, options: [.new, .old], context: &observerContext)
        }
    }

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if let keyPath = keyPath, let change = change, let newValue = change[.newKey] as? NSObject, let oldValue = change[.oldKey] as? NSObject {
//            print("Observation of property: \(keyPath)")
//            print("Change Dictionary: \(change)")
            
            var condition: KONStateControllerRule.EvaluationCondition = oldValue != newValue ? .valuesChanged : .valuesUnchanged
            if condition == .valuesChanged {
                if newValue is NSNull {
                    condition = .valuesCleared
                }
                else if oldValue is NSNull {
                    condition = .valuesSet
                }
                owner?.evaluateRulesRegardingKeys([keyPath], condition: condition)
            }
        }
    }

    deinit {
        for target in targets {
            if let keyPaths = keyPathsForTarget[ObjectIdentifier(target).hashValue] {
                for keyPath in keyPaths {
                    target.value?.removeObserver(self, forKeyPath: keyPath, context: &observerContext)
                }
            }
        }
    }
}

// MARK: -

class KONStateController: NSObject {
    
    // MARK: - Properties
    
    static let sharedInstance: KONStateController = KONStateController()
    
    private var targetObserver: KONTargetObserver? = KONTargetObserver()

    private var registeredManagers = [KONStateControllable]()
    var ruleForName = [String: KONStateControllerRule]()
    private var registeredTargetForTargetName = [String : KONWeakObject]()
    private var registeredTransportObserverForTargetName = [String : KONWeakObject]()
    private var evaluationForRuleName = [String : Bool]()
    private var unassociatedKeysForTargetName = [String : [String]]()
    private var rulesForKey = [String : Set<KONStateControllerRule>]()
    private var rulesForTargetName = [String : Set<KONStateControllerRule>]()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        targetObserver?.owner = self
    }
    

    func registerManagers(_ managers: [KONStateControllable]) {
        registeredManagers.append(contentsOf: managers)
    }
    
    func start() {
        for manager in registeredManagers {
            manager.start()
        }
    }
    
    func stop() {
        for manager in registeredManagers {
            manager.stop()
        }
    }
        
    /* For Diagnostic Purposes Only */
    /* Managers should only be interacted with via queries, rules, and transport observation */
    func registeredManagerForTargetName(_ targetName: String) -> KONStateControllable? {
        for manager in registeredManagers {
            if (manager as! NSObject).className.contains(targetName) {
                return manager
            }
        }
        return nil
    }
    
    func shutdown() {
        targetObserver = nil
    }

    // Things that change - My Location, People in Range, People Nearby, My Information, Location Requests
    // Location Manager Available, Exited Region, 
    
    
    // MARK: - Observation
    
    func registerTransportObserver(_ observer: KONTransportObserver, regardingTarget targetName: String) {
        let weakTarget = KONWeakObject(value: observer as! NSObject)
        registeredTransportObserverForTargetName[targetName] = weakTarget
    }
    
    // Things that care - View Controllers, Managers
    
    // MARK: - Query Context
    func performTargetKeyQuery(_ targetKeyQuery: KONTargetKeyQuery) -> (successful: Bool, value: Any?) {
        return performTargetKeyQuery(targetKeyQuery, mutating: false)
    }
    
    private func performTargetKeyQuery(_ targetKeyQuery: KONTargetKeyQuery, mutating: Bool) -> (successful: Bool, value: Any?)  {
        if (!mutating) {
            var value: Any?
            if targetKeyQuery.key.components(separatedBy: ".").count > 0 {
                value = registeredTargetForTargetName[targetKeyQuery.targetName]?.value?.value(forKeyPath: targetKeyQuery.key)
            }
            else {
                value = registeredTargetForTargetName[targetKeyQuery.targetName]?.value?.value(forKey: targetKeyQuery.key)
            }
            
            let boolValue = value is Bool ? value as! Bool : value != nil
            return((boolValue == targetKeyQuery.evaluationValue), value as Any?)
        }
        else if !targetKeyQuery.evaluationValue {
            if targetKeyQuery.key.components(separatedBy: ".").count > 0 {
                registeredTargetForTargetName[targetKeyQuery.targetName]?.value?.setValue(nil, forKeyPath: targetKeyQuery.key)
            }
            else {
                registeredTargetForTargetName[targetKeyQuery.targetName]?.value?.setNilValueForKey(targetKeyQuery.key)
            }
            return (true, nil)
        }
        return (false, nil)
    }
    
    // MARK: - Rules
    
    // Register Target Rules
    func registerRules(target: NSObject, rules: [KONStateControllerRule]) {
        
        // Save Target
        let weakTarget = KONWeakObject(value: target)
        registeredTargetForTargetName[target.className] = weakTarget
        
        // Save Rule
        var associatedKeys: [String] = []
        for rule in rules {
            
            associatedKeys.append(contentsOf: rule.associatedKeys)
            
            for targetName in rule.unassociatedKeys.keys {
                if unassociatedKeysForTargetName[targetName] != nil {
                    if let unassociatedKeys = rule.unassociatedKeys[targetName] {
                        unassociatedKeysForTargetName[targetName]?.append(contentsOf: unassociatedKeys)
                    }
                }
                else {
                    unassociatedKeysForTargetName[targetName] = rule.unassociatedKeys[targetName]
                }
            }
            
            for key in rule.allKeys {
                if rulesForKey[key] != nil {
                    rulesForKey[key]?.insert(rule)
                }
                else {
                    rulesForKey[key] = [rule]
                }
            }
        }
        
        if rulesForTargetName[target.className] != nil {
            rulesForTargetName[target.className]?.formUnion(rules)
        }
        else {
            rulesForTargetName[target.className] = Set(rules)
        }
        
        // Observe keys of caller
        let unassociatedKeys = unassociatedKeysForTargetName[target.className] ?? []
        targetObserver?.addTarget(target: weakTarget, keyPaths: associatedKeys + unassociatedKeys)
        unassociatedKeysForTargetName.removeValue(forKey: target.className)
        
        // Observe keys of previously registered caller
        for targetName in unassociatedKeysForTargetName.keys {
            if let registeredTarget = registeredTargetForTargetName[targetName], let keys = unassociatedKeysForTargetName[targetName] {
                targetObserver?.addTarget(target: registeredTarget, keyPaths: keys)
                unassociatedKeysForTargetName.removeValue(forKey: targetName)
            }
        }
        
        registerRules(rules)
    }
    
    /* Performs rule once and does not register for KVO */
    func registerRules(_ rules: [KONStateControllerRule]) {
        for rule in rules {
            ruleForName[rule.name] = rule
            evaluateRule(rule)
        }
    }
    
    // Unregister Target Rules
    
    func unregisterRulesForTarget(_ target: NSObject) {
        if let weakTarget =  registeredTargetForTargetName[target.className] {
            targetObserver?.removeTarget(weakTarget)
            
            if let rulesToRemove = rulesForTargetName[target.className] {
                for rule in rulesToRemove {
                    unregisterRule(rule)
                    for (key, ruleSet) in rulesForKey {
                        rulesForKey[key] = ruleSet.subtracting(Set([rule]))
                    }
                }
            }
            registeredTargetForTargetName.removeValue(forKey: target.className)
        }
        
        
        
    }
    
    
    func unregisterRule(_ rule: KONStateControllerRule) {
        ruleForName.removeValue(forKey: rule.name)
    }
    
    // Evaluate Rules
    func evaluateRulesRegardingKeys(_ keys: [String], condition: KONStateControllerRule.EvaluationCondition) {
        var rules = [KONStateControllerRule]()
        
        for key in keys {
            if let _rules = rulesForKey[key] {
                rules.append(contentsOf: _rules)
//                print("All Concerning Rules: \(rules.flatMap { return $0.name})")
            }
        }
        evaluateRules(rules, condition: condition)
    }
    
    func evaluateRules(_ rules: [KONStateControllerRule], condition: KONStateControllerRule.EvaluationCondition) {
        for rule in rules {
            if rule.evaluationCondition == .valuesChanged || condition == rule.evaluationCondition {
                evaluateRule(rule)
            }
        }
    }
    
    func evaluateRuleWithName(_ name: String) {
        if let rule = ruleForName[name] {
            evaluateRule(rule)
        }
    }
    
    func evaluateRule(_ rule: KONStateControllerRule) {
        
        var failedKeys = [String]()
        var context = [String : Any]()
        
     

        for query in rule.targetKeyQueries {
            
            let (success, value) = performTargetKeyQuery(query, mutating: !query.evaluationValue)
            if !success {
                failedKeys.append(query.key)
            }
            else {
                context[query.key] = value
                
                /* Queries that set target values to nil only run once */
                if (query.evaluationValue == false) {
                    ruleForName.removeValue(forKey: rule.name)
                }
            }
        }
        
        var evaluationResult = true

        if failedKeys.count > 0 {
            evaluationResult = false
            context[Constants.StateController.RuleContextKeys.failedKeys] = failedKeys
        }
        
        rule.didEvaluateWithResult(evaluationResult, context: context)
    }
    
    // check rules and determine state
    // if MyInformation changes tell network manager to update user profile
    // if MyInformation is available for the first time, start observing database for metusers, nearbyusers, location requests
    // if LocationManager becomes available get my current location
    // if MyLocation becomes avaiable start observing databse for region/nearby users
    
    // MARK: - Transport Events
    
    func didReceiveTransportEvent(_ event: TransportEventType, data: Any, targetName: String) {
        print("Did Respond to transport event")
        
        if let responder = registeredTargetForTargetName[targetName]?.value as? KONTransportResponder {
            if event == .dataReceived {
                responder.didReceiveData(data)
            }
            else if event == .dataRemoved {
                responder.didRemoveData(data)
            }
            else if event == .dataChanged {
                responder.didChangeData(data)
            }
        }
        
        if let observer = registeredTransportObserverForTargetName[targetName]?.value as? KONTransportObserver {
            observer.observeTransportEvent(event)
        }
    }    
}
