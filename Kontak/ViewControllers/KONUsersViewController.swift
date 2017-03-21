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
    
    func observeUserChanges(observer: AnyObject?, callback:@escaping (KONUserManager, String) -> Void) {
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
    var metUsers: [KONUserReference]?
    
    var expandedRows = Set<Int>()


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
        stateController.observeUserChanges(observer: self) {[weak self] (userManager, keyPath) in
            guard let `self` = self else { return }
            self.nearbyUsers = userManager.nearbyUsers
            self.metUsers = userManager.metUsers
            self.tableView.reloadData()
        }
        
        
        // Set Up TableView 
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        

    }
    
    
    // MARK: - Actions
    
    @IBAction func didPressManualLocationButton(_ sender: UIButton) {
        if let title = sender.titleLabel?.text {
            switch title {
            case "Out Of Range":
                stateController.setManualLocationHash("0q60y622fm")
                break
            case "In Region":
                stateController.setManualLocationHash("9q60y622Xm")
                break
            case "Nearby":
                stateController.setManualLocationHash("9q60y622fX")
                break
            default:
                break
            }
        
        }
        
    }
    

    // MARK: - User Manger Helpers
    
    func setUserProfile(userRef: KONUserReference) {
        stateController.setCurrentUser(userRef)
    }
 
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? KONUserTableViewCell else { return }
        
        if indexPath.section == 1 {
            tableView.beginUpdates()
            cell.isExpanded = !cell.isExpanded
            tableView.endUpdates()
            
            if cell.isExpanded {
                expandedRows.insert(indexPath.row)
            }
            else {
                expandedRows.remove(indexPath.row)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? KONUserTableViewCell else { return }
        
        if indexPath.section == 1 {
            tableView.beginUpdates()
            cell.isExpanded = false
            tableView.endUpdates()
            
            expandedRows.remove(indexPath.row)
        }
    }
    
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
        else if section == 1, let metUsers = metUsers {
            return metUsers.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableView.Cells.Identifiers.userTableViewCell) as! KONUserTableViewCell
        
        if indexPath.section == 0, let userRef = nearbyUsers?[indexPath.row] {
            cell.nameLabel.text = userRef.fullName
            cell.profilePictureImageView?.image = userRef.profilePicture?.squareImage()
           
            cell.bioTextView.text = ""
            cell.contactMethodsTextView.text = ""

            cell.profilePictureImageView?.makeCircularWithBorderColor(UIColor.konDarkGray)
            cell.isExpanded = false
        }
        else if indexPath.section == 1, let userRef = metUsers?[indexPath.row] {
            cell.nameLabel.text = userRef.fullName
            cell.profilePictureImageView?.image = userRef.profilePicture?.squareImage()
            
            cell.bioTextView.text = userRef.bio
            cell.bioTextView.sizeToFit()
            cell.contactMethodsTextView.text = userRef.contactMethodDictionary.description
            cell.contactMethodsLabel.sizeToFit()
            cell.bioTextHeight = cell.bioTextView.frame.height
            cell.expansionHeight = 223// cell.contactMethodsLabel.frame.height + cell.bioTextView.frame.height + 20

            cell.profilePictureImageView?.makeCircularWithBorderColor(UIColor.konDarkGray)
            
            cell.isExpanded = expandedRows.contains(indexPath.row)

        }
        
        
        return cell
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? KONEditProfileViewController {
            destination.userRef = userRef
            destination.usersViewController = self
        }
    }
    

}
