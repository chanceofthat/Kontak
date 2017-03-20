//
//  KONObservation.swift
//  Kontak
//
//  Created by Chance Daniel on 3/18/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import Foundation

class KONObserverInfo<T> {
    var callback: ((_ data: T) -> Void)?
    weak var observer: AnyObject?
}

class KONObservers<T> {
    private var observers = [KONObserverInfo<T>]()
    
    func observe(observer: AnyObject?, callback: @escaping (_ data: T) -> Void) {
        let observerInfo = KONObserverInfo<T>()
        observerInfo.observer = observer
        observerInfo.callback = callback
        observers.append(observerInfo)
    }
    
    func notify(_ data: T) {
        var invalidObserverIndexes = IndexSet()
        
        for (index, observerInfo) in observers.enumerated() {
            if let _ = observerInfo.observer, let callback = observerInfo.callback {
                callback(data)
            }
            else {
                invalidObserverIndexes.insert(index)
            }
            
            observers = observers.enumerated().flatMap { invalidObserverIndexes.contains($0.0) ? nil : $0.1 }
        }
    }
}
