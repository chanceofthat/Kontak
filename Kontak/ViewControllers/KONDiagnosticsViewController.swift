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
        
        uuidTextField.text = userManager.meUser.userID
        locationManagerStatusLabel.text = "On"
        overrideLocationSwitch.isOn = false

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
                print(context)
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
        locationManager.useManualLocation = false
        locationManager.latestLocationHash = nil
    }
    
    
    @IBAction func pushLocationButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            if (geoHashTextField.text != "") {
                locationManager.useManualLocation = true
                locationManager.latestLocationHash = geoHashTextField.text
                flashBackgroundWithColor(.purple)
            }
            else {
                flashBackgroundWithColor(.yellow)
            }
        }
    }
 
    @IBAction func startButtonPressed(_ sender: Any) {
        if let uuid = uuidTextField.text, uuid.characters.count > 0 {
            stateController.stop()
            networkManager.removeUserFromDatabase(userID: userManager.meUser.userID)
            userManager.meUser.userID = uuid
            stateController.start()
            flashBackgroundWithColor(.green)
        }
        else {
            flashBackgroundWithColor(.yellow)
        }
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        stateController.stop()
        networkManager.removeUserFromDatabase(userID: userManager.meUser.userID)
        tableView.reloadData()
        flashBackgroundWithColor(.red)
    }
    
    
    @IBAction func locationManagerSwitchToggled(_ sender: Any) {
        if locationManagerSwitch.isOn {
            locationManagerStatusLabel.text = "On"
            locationManager.start()
        }
        else {
            locationManagerStatusLabel.text = "Off"
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
            if overrideSwitch.isOn {
                networkManager.allowMet = true
            }
            else {
                networkManager.allowMet = false
            }
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
            return networkManager.userStateController.regionUserIDs.count
        case 1:
            return networkManager.userStateController.nearbyUserIDs.count
        case 2:
            return networkManager.userStateController.missingUserIDs.count
        case 3:
            return networkManager.userStateController.metUserIDs.count
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
            cell.userID.text = networkManager.userStateController.regionUserIDs[indexPath.row]
        case 1:
            cell.userID.text = networkManager.userStateController.nearbyUserIDs[indexPath.row]
        case 2:
            cell.userID.text = networkManager.userStateController.missingUserIDs[indexPath.row]
        case 3:
            cell.userID.text = networkManager.userStateController.metUserIDs[indexPath.row]
        default:
            break
        }
        
        return cell
    }
    

}
