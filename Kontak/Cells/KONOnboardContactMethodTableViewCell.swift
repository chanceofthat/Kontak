//
//  KONOnboardContactMethodTableViewCell.swift
//  Kontak
//
//  Created by Chance Daniel on 3/17/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardContactMethodTableViewCell: UITableViewCell, UITextFieldDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var methodLabel: UILabel!
    @IBOutlet weak var methodTextField: UITextField!
    
    var userRef: KONUserReference?
    
    // MARK: - Awake
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup TextField
        methodTextField.setBottomBorderToColor(.konLightGray)
        methodTextField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func methodTextFieldDidChange(_ sender: UITextField) {
        if let text = sender.text, text.characters.count > 0, let userRef = userRef, let method = methodLabel.text {
            userRef.contactMethodDictionary[method] = text
        }
    }
    
    func previousMethodText() -> String? {
        if let userRef = userRef, let method = methodLabel.text {
            return userRef.contactMethodDictionary[method]
        }
        return nil
    }
    
    // MARK: - UITextFieldDelegate Protocol
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == methodTextField, string == " " {
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konBlue)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setBottomBorderToColor(.konLightGray)
        methodTextFieldDidChange(textField)
        textField.resignFirstResponder()
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
