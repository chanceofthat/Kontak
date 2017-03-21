//
//  KONDiagnosticsViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/18/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONDiagnosticsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var geoHashTextField: UITextField!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var lonLabel: UILabel!
    @IBOutlet weak var locationManagerStatusLabel: UILabel!
    @IBOutlet weak var locationManagerSwitch: UISwitch!
    @IBOutlet weak var overrideLocationSwitch: UISwitch!
    @IBOutlet weak var saveMetOverrideSwitch: UISwitch!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let stateController = KONStateController.sharedInstance
    lazy var userManager: KONUserManager = KONStateController.sharedInstance.registeredManagerForTargetName(KONUserManager.className) as! KONUserManager
    lazy var locationManager: KONLocationManager = KONStateController.sharedInstance.registeredManagerForTargetName(KONLocationManager.className) as! KONLocationManager
    lazy var networkManager: KONNetworkManager = KONStateController.sharedInstance.registeredManagerForTargetName(KONNetworkManager.className) as! KONNetworkManager
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)

        
        tableView.delegate = self
        tableView.dataSource = self
        
        uuidTextField.text = userManager.currentUser?.userID
        locationManagerSwitch.isOn = locationManager.overrideLocationHash == nil
        locationManagerStatusLabel.text = locationManagerSwitch.isOn ? "On" : "Off"

        saveMetOverrideSwitch.isOn = networkManager.allowMet
        overrideLocationSwitch.isOn = locationManager.updateLocationContinuously
        


        registerWithStateController()
        registerWithUserStateController()
    }
    
    func dismissKeyboard() {
        uuidTextField.resignFirstResponder()
        geoHashTextField.resignFirstResponder()
    }
    
    func registerWithStateController() {
        let locationUpdatedQuery = KONTargetKeyQuery(targetName: KONLocationManager.className, key: #keyPath(KONLocationManager.latestLocationHash), evaluationValue: true)
        let locationUpdatedRule = KONStateControllerRule(owner: self, name: Constants.StateController.RuleNames.locationAvailableRule, targetKeyQueries: [locationUpdatedQuery], condition: .valuesChanged) {[weak self] (rule, successful, context) in
            guard let `self` = self else { return }
            if successful {
                self.updateLocationFields()
            }
        }
        
        stateController.registerRules(target: self, rules: [locationUpdatedRule])
    }
    
    func registerWithUserStateController() {
        networkManager.userStateControllerCallbacks.append {[weak self] in
            guard let `self` = self else { return }
            
            self.tableView.reloadData()
        }
    }
    
    func flashBackgroundWithColor(_ color: UIColor) {
        self.view.backgroundColor = color
        UIView.animate(withDuration: 0.5, delay: 0.25, options: .curveEaseOut, animations: {[weak self] in
            guard let `self` = self else { return }
            self.view.backgroundColor = .white
            }, completion: nil)
    }
    

    @IBAction func getLocationButtonPressed(_ sender: Any) {
        locationManager.latestLocationHash = nil
        locationManagerSwitch.isOn = true
        locationManagerSwitchToggled(locationManagerSwitch)
    }
    
    
    @IBAction func pushLocationButtonPressed(_ sender: Any) {
        if (geoHashTextField.text != "") {
            locationManager.overrideLocationHash = geoHashTextField.text
            flashBackgroundWithColor(.purple)
        }
        else {
            flashBackgroundWithColor(.yellow)
        }
    }
 
    @IBAction func startButtonPressed(_ sender: Any) {
        if let uuid = uuidTextField.text, uuid.characters.count > 0 {
            stateController.stop()
            if let currentUser = userManager.currentUser, let userID = currentUser.userID {
                networkManager.removeUserFromDatabase(userRef: currentUser)
                currentUser.userID = uuid
                stateController.start()
                flashBackgroundWithColor(.green)
            }
        }
        else {
            flashBackgroundWithColor(.yellow)
        }
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        stateController.stop()
        if let currentUser = userManager.currentUser {
            networkManager.removeUserFromDatabase(userRef: currentUser)
            tableView.reloadData()
        }
        flashBackgroundWithColor(.red)
    }
    
    
    @IBAction func locationManagerSwitchToggled(_ sender: Any) {
        if locationManagerSwitch.isOn {
            locationManagerStatusLabel.text = "On"
            
            locationManager.overrideLocationHash = nil
            locationManager.start()
            
        }
        else {
            locationManagerStatusLabel.text = "Off"
            
            locationManager.overrideLocationHash = "9q60y622fm"
            locationManager.stop()
            
        }
    }
    
    @IBAction func overrideLocationSwitchToggled(_ sender: Any) {
        if overrideLocationSwitch.isOn {
            locationManager.updateLocationContinuously = true
        }
        else {
            locationManager.updateLocationContinuously = false
        }
    }
    
    @IBAction func allowMetOverrideToggled(_ sender: Any) {
        if let overrideSwitch = sender as? UISwitch {
            networkManager.allowMet = overrideSwitch.isOn
        }
    }
    
    func updateLocationFields() {
        if let locationHash = locationManager.latestLocationHash {
            geoHashTextField.text = locationHash
            let (lat, lon) = KONLocationManager.coordinatesFromLocationHash(hash: locationHash)
            
            latLabel.text = String(lat)
            lonLabel.text = String(lon)
        }
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return userManager.regionUsers.count
        case 1:
            return userManager.nearbyUsers.count
        case 2:
            return userManager.missingUsers.count
        case 3:
            return userManager.metUsers.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Region"
        case 1:
            return "Nearby"
        case 2:
            return "Missing"
        case 3:
            return "Met"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableView.Cells.Identifiers.KONDiagnosticCell) as! KONDiagnosticTableViewCell
        
        switch indexPath.section {
        case 0:
            cell.userID.text = userManager.regionUsers[indexPath.row].description
        case 1:
            cell.userID.text = userManager.nearbyUsers[indexPath.row].description
        case 2:
            cell.userID.text = userManager.missingUsers[indexPath.row].description
        case 3:
            cell.userID.text = userManager.metUsers[indexPath.row].description
        default:
            break
        }
        
        return cell
    }
    

}
