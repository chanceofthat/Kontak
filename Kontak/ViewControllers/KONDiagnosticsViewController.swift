//
//  KONDiagnosticsViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/18/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONDiagnosticsViewController: UIViewController {

    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var geoHashTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var lonTextField: UITextField!
    @IBOutlet weak var locationManagerStatusLabel: UILabel!
    @IBOutlet weak var locationDeltaTextField: UITextField!
    @IBOutlet weak var locationManagerSwitch: UISwitch!
    
    lazy var userManager: KONUserManager = KONUserManager.sharedInstance
    lazy var locationManager: KONLocationManager = KONLocationManager.sharedInstance
    lazy var networkManager: KONNetworkManager = KONNetworkManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uuidTextField.text = userManager.meUser.userID
        updateLocationFields()
        locationManagerStatusLabel.text = "On"
    }

    
    @IBAction func getLocationButtonPressed(_ sender: Any) {
        locationManager.requestLocation()
        locationManager.locationAvailableCallbacks.append {[weak self] in
            guard let `self` = self else { return }
            self.updateLocationFields()
        }
    }
    
    @IBAction func pushLocationButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            if let title = button.titleLabel?.text {
                if title == "Push" {
                    if (geoHashTextField.text != "") {
                        locationManager.manuallySetLocationToHash(hash: geoHashTextField.text!)
                        
                        let (lat, lon) = KONLocationManager.coordinatesFromLocationHash(hash: geoHashTextField.text!)
                        latTextField.text = String(lat)
                        lonTextField.text = String(lon)
                    }
                }
                else {
                    if (latTextField.text != "" && lonTextField.text != "") {
                        let hash = Geohash.encode(latitude: Double(latTextField.text!)!, longitude: Double(lonTextField.text!)!, length: 10)
                        locationManager.manuallySetLocationToHash(hash: hash)
                        geoHashTextField.text = hash
                    }
                }
            }
        }
        
    }
    
    @IBAction func assumeIdentityButtonPressed(_ sender: Any) {
        if let uuid = uuidTextField.text {
            networkManager.stop()
            networkManager.start()
            userManager.meUser.userID = uuid
            
        }
    }
    
    @IBAction func locationManagerSwitchToggled(_ sender: Any) {
        if locationManagerSwitch.isOn {
            locationManagerStatusLabel.text = "On"
            locationManager.startLocationManager()
        }
        else {
            locationManagerStatusLabel.text = "Off"
            locationManager.stopLocationManager()
        }
    }
    
    @IBAction func locationDeltaButtonPressed(_ sender: Any) {
        if (latTextField.text != "" && lonTextField.text != "" && locationDeltaTextField.text != "") {
            let (lat, lon) = KONLocationManager.adjustedCoordinatesForDelta(lat: Double(latTextField.text!)!, Lon: Double(lonTextField.text!)!, delta: Double(locationDeltaTextField.text!)!)
            
            let hash = Geohash.encode(latitude: lat, longitude: lon, length: 10)
            locationManager.manuallySetLocationToHash(hash: hash)
            geoHashTextField.text = hash
            
            latTextField.text = String(lat)
            lonTextField.text = String(lon)

        }

    }
    
    func updateLocationFields() {
        if let locationHash = userManager.meUser.locationHash {
            geoHashTextField.text = locationHash
            let (lat, lon) = KONLocationManager.coordinatesFromLocationHash(hash: locationHash)
            latTextField.text = String(lat)
            lonTextField.text = String(lon)
        }
    }

}
