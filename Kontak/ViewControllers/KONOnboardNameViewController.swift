//
//  KONOnboardNameViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardNameViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var helperTextLabel: UILabel!
    
    @IBOutlet weak var nextButtonHeightConstraint: NSLayoutConstraint!
    
    
    var userRef: KONUserReference?
    
    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Up NavigationBar
        navigationController?.navigationBar.barTintColor = UIColor.konBlue
        navigationController?.navigationBar.tintColor = .white


        // Set Up Text Fields
        firstNameTextField.setBottomBorderToColor(.konLightGray)
        firstNameTextField.delegate = self
        
        lastNameTextField.setBottomBorderToColor(.konLightGray)
        lastNameTextField.delegate = self
        
        // Set Up Next Button
        nextButton.isUserInteractionEnabled = false
        nextButton.alpha = 0.5
        helperTextLabel.alpha = 0
        
        // Set Up Gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateNextButton(keyboardShowing: false)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Animations
    
    func animateNextButton(keyboardShowing: Bool) {
        
        
        if keyboardShowing {
            self.nextButtonHeightConstraint.constant = 270
        }
        else {
            self.nextButtonHeightConstraint.constant = 32
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {[weak self] in
            guard let `self` = self else { return }
            self.view.layoutIfNeeded()

        }, completion: nil)
        
       
    }
    
    // MARK: - Actions
    
    @IBAction func textFieldEditingChanged(_ textField: UITextField) {
        
        if textField == firstNameTextField {
            if let text = textField.text {
                
                if text.characters.count > 0 {
                    nextButton.isUserInteractionEnabled = true
                    nextButton.alpha = 1
                    helperTextLabel.alpha = 0
                }
                else {
                    nextButton.isUserInteractionEnabled = false
                    nextButton.alpha = 0.5
                    helperTextLabel.alpha = 1
                }
            }
        }
        else if textField == lastNameTextField {
        }
    }
    
    @IBAction func didPressNextButton(_ sender: UIButton) {
        
        if let firstName = firstNameTextField.text, firstName.characters.count > 0 {
            userRef = KONUserReference(firstName: firstName, lastName: lastNameTextField.text)
        }
    }
    
    // MARK: - Diagnostic 
    
    @IBAction func didPressSkipButton(_ sender: Any) {
        userRef = KONUserReference(firstName: "Chance", lastName: "Daniel")
        userRef?.bio = "I am awesome"
        userRef?.profilePicture = #imageLiteral(resourceName: "SampleProfileImage")
        userRef?.contactMethodDictionary = [Constants.TableView.Cells.ContactMethod.methodTitles[0][0] : "7076941519"]
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let usersViewController = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.Identifiers.usersViewController) as! KONUsersViewController
        
        usersViewController.navigationItem.hidesBackButton = true
        usersViewController.userRef = userRef
        self.navigationController?.pushViewController(usersViewController, animated: true)
    }
    
    
    // MARK: - Gesture Recognizer Delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view == nextButton)
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
        
        animateNextButton(keyboardShowing: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konLightGray)
        animateNextButton(keyboardShowing: false)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? KONOnboardProfilePictureViewController {
            destination.userRef = userRef
        }
    }
 

}
