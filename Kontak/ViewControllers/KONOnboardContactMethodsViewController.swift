//
//  KONOnboardContactMethodsViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/17/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardContactMethodsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    
    var userRef: KONUserReference?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @IBAction func didPressNextButton(_ sender: Any) {
        
        for cell in tableView.visibleCells {
            cell.endEditing(true)
        }
        
        
        if let userRef = userRef {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let usersViewController = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.Identifiers.usersViewController) as! KONUsersViewController
            
            usersViewController.navigationItem.hidesBackButton = true
            usersViewController.userRef = userRef
            usersViewController.stateController.setManualLocationHash("0q60y622fm")

            self.navigationController?.pushViewController(usersViewController, animated: true)
        }
    }
    
    
    // MARK: - UITableViewDelegate Protocol
    
    
    // MARK: - UITablViewDataSource Protocol
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.TableView.Cells.ContactMethod.headerTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Constants.TableView.Cells.ContactMethod.methodTitles[section].count
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.TableView.Cells.ContactMethod.headerTitles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableView.Cells.Identifiers.onboardContactMethodCell) as! KONOnboardContactMethodTableViewCell
        
        cell.userRef = userRef
        cell.methodLabel.text = Constants.TableView.Cells.ContactMethod.methodTitles[indexPath.section][indexPath.row]
        
        if indexPath.section == 0 {
            cell.methodTextField.keyboardType = Constants.TableView.Cells.ContactMethod.keyboardTypes[indexPath.row]
            
            if indexPath.row == 0 {
                cell.methodTextField.becomeFirstResponder()
            }
        }
        else {
            cell.methodTextField.keyboardType = .asciiCapable
        }
        
        cell.methodTextField.text = cell.previousMethodText()
        
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
