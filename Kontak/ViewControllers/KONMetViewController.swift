//
//  KONMetViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, KONTransportObserver {

    // MARK: - Properties
    @IBOutlet var backgroundView: KONBackgroundView!
    @IBOutlet weak var backgroundCardView: KONBackgroundCardView!
    @IBOutlet weak var tableView: UITableView!
    
//    var userManager: KONUserManager!
    var users = [KONUserReference]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get User Manager Singleton
//        userManager = KONUserManager.sharedInstance
        
//        userManager.metControllerUpdateCallback = {[weak self] in
//            guard let `self` = self else { return }
//            
//            self.tableView.reloadData()
//        }
        registerWithStateController()

        // Set Up BackgroundView
        backgroundView.setBackgroundImage(image: #imageLiteral(resourceName: "MetBackgroundFill"))
        
        // Set Up BackgroundCardView
        backgroundCardView.roundCorner(corners: .topRight)
        
        // Set Up TabBarItem
        tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.konRed], for: .selected)
        
        // Set Up TableView
        tableView.dataSource = self
        tableView.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - State Controller
    
    func registerWithStateController() {
        let stateController = KONStateController.sharedInstance
        
        let metUsersUpdatedQuery = KONTargetKeyQuery(targetName: KONUserManager.className, key: #keyPath(KONUserManager.metUsers.users), evaluationValue: true)
        let metUsersUpdatedRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.updatedMetUsersAvailable, targetKeyQueries: [metUsersUpdatedQuery]) {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            
            if successful {
                for key in rule.allKeys {
                    if let users = context?[key] as? [KONUserReference] {
                        self.users = users
                        self.tableView.reloadData()
                    }
                }
            }
        
        }
       
        
        stateController.registerRules(target: self, rules: [metUsersUpdatedRule])
        stateController.registerTransportObserver(self, regardingTarget: KONUserManager.className)
    }

    // MARK: - UITableViewDelegate Protocol
    
    
    
    // MARK: - UITableViewDataSource Protocol
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return userManager.metUsers.count
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: KONMetTableCellReuseIdentifier) as! KONMetTableViewCell
        
//        cell.nameLabel.text = userManager.nearbyUsers[indexPath.row].name.fullName
//        let userIDs = userManager.metUsers.userIDs
        let user = users[indexPath.row]
        cell.uuidLabel.text = user.userID
        cell.nameLabel.text = user.fullName
        
        
        
        return cell
    }
    
    
    
    // MARK: - KONTransportObserver
    
    func observeTransportEvent(_ event: TransportEventType) {
        print("Did Observe Transport Event \(event)")
        tableView.reloadData()
    }
    
    
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
