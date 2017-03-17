//
//  AppDelegate.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        FIRApp.configure()
        let stateController = KONStateController.sharedInstance
        let userManager = KONUserManager.sharedInstance
        let locationManager = KONLocationManager.sharedInstance
        let networkManager = KONNetworkManager.sharedInstance

        stateController.registerManagers([userManager, locationManager, networkManager])
        stateController.start()
        
        if let window = self.window {
            if let tabBarController = window.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 1;
            }
            
        }
        
        
        /*
        class TestClass: NSObject {
            dynamic var foo = true
            dynamic var bar = false
        }
        
        let testClass = TestClass()
        
        // Test StateController
        let stateController = KONStateController.sharedInstance
//        stateController.registerForObservationOfKeyPaths(target: testClass, keyPaths: [#keyPath(TestClass.foo), #keyPath(TestClass.bar)])
        let testRule = KONStateControllerRule(trueKeys: [#keyPath(TestClass.foo)], falseKeys: [#keyPath(TestClass.bar)])
        stateController.registerRules(target: testClass, rules: [testRule])
        testRule.ruleFailureCallback = { (name, reason) in
            
        }
        testRule.ruleSuccessCallback = { (name) in
            
        }
//        stateController.registerRule(rule: testRule)

        testClass.bar = true
        testClass.bar = false
        stateController.shutdown()
        
        */
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

