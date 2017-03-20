//
//  KONUsersViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/18/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

// State Controller Extension 

extension KONStateController {
    func setCurrentUser(_ userRef: KONUserReference) {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            userManager.currentUser = userRef
        }
    }
    
    func observeUserChanges(observer: AnyObject?, callback:@escaping (KONUserManager) -> Void) {
        if let userManager = self.registeredManagerForTargetName(KONUserManager.className) as? KONUserManager {
            userManager.observers.observe(observer: observer, callback: callback)
        }
    }
    
    // Diagnostic
    func setManualLocationHash(_ locationHash: String?) {
        if let locationManager = self.registeredManagerForTargetName(KONLocationManager.className) as? KONLocationManager {
            locationManager.overrideLocationHash = locationHash
        }
    }
}

class KONUsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileVisiblityButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    
    let stateController = KONStateController.sharedInstance
    
    var userRef: KONUserReference?
    var nearbyUsers: [KONUserReference]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up NavigationBar
        navigationController?.navigationBar.barTintColor = UIColor.konGreen
        navigationController?.navigationBar.tintColor = .white
                
        // Set User Profile
        if let userRef = userRef {
            setUserProfile(userRef: userRef)
        }
        
        // Set Up Observing
        stateController.observeUserChanges(observer: self) {[weak self] (userManager) in
            guard let `self` = self else { return }
            self.nearbyUsers = userManager.nearbyUsers
            self.tableView.reloadData()
        }
        
        stateController.setManualLocationHash("9q60y622fm")
        
        // Set Up TableView 
        tableView.delegate = self
        tableView.dataSource = self
        

    }

    // MARK: - User Manger Helpers
    
    func setUserProfile(userRef: KONUserReference) {
        stateController.setCurrentUser(userRef)
    }
 
    // MARK: - UITableViewDelegate
    
    
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.TableView.Cells.Users.headerTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.TableView.Cells.Users.headerTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0, let nearbyUsers = nearbyUsers {
            return nearbyUsers.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableView.Cells.Identifiers.userTableViewCell) as! KONUserTableViewCell
        
        if indexPath.section == 0, let userRef = nearbyUsers?[indexPath.row] {
            cell.nameLabel.text = userRef.fullName
        }
        
        return cell
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
