//
//  KONStateMachine.swift
//  Kontak
//
//  Created by Chance Daniel on 2/21/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONStateMachine: NSObject {
    
    // MARK: - Properites 
    var currentState: KONState?
    var firstState: KONState?
    var started: Bool = false
    
    var statesForName: [String : KONState] = [String : KONState]()
    
    
    // MARK: -
    func addState(state: KONState) {
        if (firstState == nil) {
            firstState = state
        }
        assert(statesForName[state.name] == nil, "Cannot add state with duplicate name: \(state.name).")
        
        statesForName[state.name] = state
    }
    
    func transitionToState(stateName: String) {
        assert(statesForName[stateName] != nil, "Cannot transition to non-exisiting state")
        if let nextState = statesForName[stateName] {
            if let previousState = currentState {
                if let stateTransition = nextState.transitionsForLastStateNames[previousState.name] {
                    stateTransition.transitionAction()
                }
            }
            currentState = nextState
            nextState.enterAction?()
        }
    }
    
    func setFirstState(state: KONState) {
        firstState = state
    }
    
    func start() {
        assert(firstState != nil, "Cannot start state machine without a first state.")
        transitionToState(stateName: firstState!.name)
    }
}
