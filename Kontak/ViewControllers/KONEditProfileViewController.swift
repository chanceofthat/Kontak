//
//  KONEditProfileViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/21/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONEditProfileViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var characterCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    weak var usersViewController: KONUsersViewController?
    
    var userRef: KONUserReference?
    
    var remainingCharacterCount = Constants.DefaultValues.initialRemainingCharacterCount {
        didSet {
            characterCountLabel.text = remainingCharacterCount.description
            if remainingCharacterCount <= 10 {
                characterCountLabel.textColor = .konRed
            }
            else {
                characterCountLabel.textColor = .konLightGray
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up NavigationBar
        navigationController?.navigationBar.barTintColor = UIColor.konBlue
        navigationController?.navigationBar.tintColor = .white
        
        // Set Up Text Fields
        firstNameTextField.setBottomBorderToColor(.konLightGray)
        firstNameTextField.delegate = self
        firstNameTextField.text = userRef?.firstName
        
        lastNameTextField.setBottomBorderToColor(.konLightGray)
        lastNameTextField.delegate = self
        lastNameTextField.text = userRef?.lastName

        // Set Up TextView
        bioTextView.setBottomBorderToColor(.konLightGray)
        bioTextView.delegate = self
        bioTextView.text = userRef?.bio

        // Set Up Character Count
        remainingCharacterCount = Constants.DefaultValues.initialRemainingCharacterCount - bioTextView.text.characters.count

        // Set Up Gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tapRecognizer.cancelsTouchesInView = false
//        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
        // Set Up Profile Image
        
        if let profileImage = userRef?.profilePicture {
            profileImageView.image = profileImage
            profileImageView.makeCircularWithBorderColor(UIColor.konBlue)
        }
        
        // Set Up TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
    
    

        if let usersViewController = usersViewController, let userRef = userRef {
            userRef.firstName = firstNameTextField.text
            userRef.lastName = lastNameTextField.text
            userRef.bio = bioTextView.text
            
            usersViewController.setUserProfile(userRef: userRef)
        }

        
    }
    
    
    func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func textFieldEditingChanged(_ textField: UITextField) {
        
        if textField == firstNameTextField {
            if let text = textField.text {
                
//                if text.characters.count > 0 {
//                    nextButton.isUserInteractionEnabled = true
//                    nextButton.alpha = 1
//                    helperTextLabel.alpha = 0
//                }
//                else {
//                    nextButton.isUserInteractionEnabled = false
//                    nextButton.alpha = 0.5
//                    helperTextLabel.alpha = 1
//                }
            }
        }
        else if textField == lastNameTextField {
        }
    }
    
    // MARK: - UITextFieldDelegate Protocol
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == firstNameTextField || textField == lastNameTextField, string == " " {
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konBlue)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konLightGray)
    }
    
    // MARK: - UITextViewDelegate Protocol
    
    func textViewDidChange(_ textView: UITextView) {
        remainingCharacterCount = Constants.DefaultValues.initialRemainingCharacterCount - textView.text.characters.count
        
        if let text = textView.text {
//            if text.characters.count > 0 {
//                nextButton.isUserInteractionEnabled = true
//                nextButton.alpha = 1
//            }
//            else {
//                nextButton.isUserInteractionEnabled = false
//                nextButton.alpha = 0.5
//            }
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return text.characters.count == 0 || remainingCharacterCount - text.characters.count >= 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.setBottomBorderToColor(.konBlue)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.setBottomBorderToColor(.konLightGray)
    }
    
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
