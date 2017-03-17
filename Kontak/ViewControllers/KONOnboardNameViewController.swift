//
//  KONOnboardNameViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardNameViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var helperTextLabel: UILabel!
    
    var userRef: KONUserReference?
    
    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Up NavigationBar
        navigationController?.navigationBar.barTintColor = UIColor.konBlue
        navigationController?.navigationBar.tintColor = .white


        // Set Up Text Fields
        firstNameTextField.setBottomBorderToColor(.konBlue)
        firstNameTextField.delegate = self
        
        lastNameTextField.setBottomBorderToColor(.konLightGray)
        lastNameTextField.delegate = self
        
        // Set Up Next Button
        nextButton.isUserInteractionEnabled = false
        nextButton.alpha = 0.5
        helperTextLabel.alpha = 0

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        firstNameTextField.becomeFirstResponder()
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
    
    
    // MARK: - UITextFieldDelegate Protocol
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == firstNameTextField || textField == lastNameTextField, string == " " {
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konBlue)
        
        if textField == firstNameTextField {
            lastNameTextField.setBottomBorderToColor(.konLightGray)
        }
        else if textField == lastNameTextField {
            firstNameTextField.setBottomBorderToColor(.konLightGray)
        }

    }


    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? KONOnboardProfilePictureViewController {
            destination.userRef = userRef
        }
    }
 

}
