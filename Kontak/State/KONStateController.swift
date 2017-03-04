//
//  KONStatusController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/2/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONWeakObject<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}

class KONTargetObserver<T>: NSObject {
    weak var owner: KONStateController?
    
    private var targets = [KONWeakObject<NSObject>]()
    private var keyPathsForTarget: [Int : [String]] = [:]
    private var observerContext = 0
    
    func addTarget(target: KONWeakObject<NSObject>, keyPaths: [String]) {
        targets.append(target)
        keyPathsForTarget[ObjectIdentifier(target).hashValue] = keyPaths
        registerForObservationOfKeyPaths(target: target.value!, keyPaths: keyPaths)
    }
    
    func registerForObservationOfKeyPaths(target: NSObject, keyPaths: [String]) {
        for keyPath in keyPaths {
            target.addObserver(self, forKeyPath: keyPath, options: [.new, .old], context: &observerContext)
            updateOwner(keyPath: keyPath, value: target.value(forKey: keyPath) ?? false)
            
        }
        owner?.evaluateRules()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        print("\(String(describing: keyPath)): \(String(describing: change?[.newKey]))")
        if let keyPath = keyPath{
            updateOwner(keyPath: keyPath, value: change?[.newKey] ?? false)
        }
        owner?.evaluateRules()
    }
    
    func updateOwner(keyPath: String, value: Any) {
        owner?.currentValueForKey[keyPath] = value
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

protocol KONStateControllerEvaluationObserver {
    func didEvaluateRule(ruleName: String, successful: Bool, context: [String : Any]?)
}

class KONStateController: NSObject {
    
    // MARK: - Properties
    static let sharedInstance: KONStateController = KONStateController()
    
    lazy var userManager: KONUserManager = KONUserManager.sharedInstance
    lazy var networkManager: KONNetworkManager = KONNetworkManager.sharedInstance
    lazy var locationManager: KONLocationManager = KONLocationManager.sharedInstance
    
    private var targetObserver: KONTargetObserver<KONStateController>? = KONTargetObserver<KONStateController>()

    var currentValueForKey: [String : Any] = [:]
    
    var ruleForName: [String: KONStateControllerRule] = [:]
    private var registeredTargetForTargetName: [String : KONWeakObject<NSObject>] = [:]
    private var evaluationForRuleName: [String : Bool] = [:]
    
    
    // MARK: - Init
    override init() {
        super.init()
        targetObserver?.owner = self
    }
    
    func start() {
        userManager.start()
        locationManager.start()
        networkManager.start()
    }
    
    func shutdown() {
        targetObserver = nil
    }

    // Things that change - My Location, People in Range, People Nearby, My Information, Location Requests
    // Location Manager Available, Exited Region, 
    
    // MARK: - Callbacks
    // Callbacks for responding to state change
    
    // MARK: - Observation
    
    // Things that care - View Controllers, Managers
    
    func didCompleteEvaluation(rule: KONStateControllerRule, successful: Bool, context: [String : Any]?) {
        userManager.didEvaluateRule(ruleName: rule.name, successful: successful, context: context)
        networkManager.didEvaluateRule(ruleName: rule.name, successful: successful, context: context)
        locationManager.didEvaluateRule(ruleName: rule.name, successful: successful, context: context)
    }
    

    // MARK: - Rules
    
    func contextForRule(_ rule: KONStateControllerRule) -> [String : Any] {
        var context: [String : Any] = [:]
        for targetKey in rule.targetKeys {
            context[targetKey.key] = registeredTargetForTargetName[targetKey.targetName]?.value?.value(forKey: targetKey.key)
        }
        return context
    }
    
    // Register Rules 
    func registerRules(target: NSObject, rules: [KONStateControllerRule]) {
        
        // Save Target
        let weakTarget = KONWeakObject<NSObject>(value: target)
        registeredTargetForTargetName[target.className] = weakTarget
        
        
        // Save Rule
        var callerKeys: [String] = []
        var targetNameSet: Set<String> = []
        for rule in rules {
            registerRule(rule: rule)
            
            for targetKey in rule.targetKeys {
                if targetKey.targetName == target.className {
                    callerKeys.append(targetKey.key)
                }
                targetNameSet.insert(targetKey.targetName)
            }
        }
        
        // Observe keys of register caller
        targetObserver?.addTarget(target: weakTarget, keyPaths: callerKeys)
        
    }
    
    func registerRule(rule: KONStateControllerRule) {
        ruleForName[rule.name] = rule
    }
    
    func evaluateRules() {
        for rule in ruleForName.values {
            evaluateRule(rule)
        }
    }
    
    func evaluateRuleWithName(_ name: String) {
        if let rule = ruleForName[name] {
            evaluateRule(rule)
        }
    }
    
    func evaluateRule(_ rule: KONStateControllerRule) {
        let oldEvaluation = evaluationForRuleName[rule.name]

        for targetKey in rule.targetKeys {
            let value = currentValueForKey[targetKey.key]
            let boolValue = value is Bool ? value as! Bool : value != nil
            if boolValue != targetKey.evaluationValue {
                
                evaluationForRuleName[rule.name] = false
                if (oldEvaluation == nil || oldEvaluation!) {
                    rule.fail(failingKey: targetKey.key)
                    didCompleteEvaluation(rule: rule, successful: false, context: nil)
                }
                return
            }
        }
    
        evaluationForRuleName[rule.name] = true
        
        if (oldEvaluation == nil || !oldEvaluation!) {
            rule.succeed()
            didCompleteEvaluation(rule: rule, successful: true, context: contextForRule(rule))
        }
        
        
    }
    
    // check rules and determine state
    // if MyInformation changes tell network manager to update user profile
    // if MyInformation is available for the first time, start observing database for metusers, nearbyusers, location requests
    // if LocationManager becomes available get my current location
    // if MyLocation becomes avaiable start observing databse for region/nearby users
    
    // MARK: - State
    
    // handle state change
    
    
}
