//
//  KONOnboardBioViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/17/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardBioViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var remainingCharacterCountLabel: UILabel!
    
    var userRef: KONUserReference?
    var remainingCharacterCount = Constants.DefaultValues.initialRemainingCharacterCount {
        didSet {
            remainingCharacterCountLabel.text = remainingCharacterCount.description
            if remainingCharacterCount <= 10 {
                remainingCharacterCountLabel.textColor = .konRed
            }
            else {
                remainingCharacterCountLabel.textColor = .konLightGray
            }
        }
    }

    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up TextView
        bioTextView.setBottomBorderToColor(.konBlue)
        bioTextView.delegate = self
        bioTextView.becomeFirstResponder()
        
        // Set Up Character Count
        remainingCharacterCountLabel.text = remainingCharacterCount.description
        
        // Set Up Next Button
        nextButton.isUserInteractionEnabled = false
        nextButton.alpha = 0.5

    }
    
    // MARK: - Actions
    
    @IBAction func didPressNextButton(_ sender: UIButton) {
        
        if let bio = bioTextView.text, bio.characters.count > 0 {
            userRef?.bio = bio
        }
    }
    
    // MARK: - UITextViewDelegate Protocl
    
    func textViewDidChange(_ textView: UITextView) {
        remainingCharacterCount = Constants.DefaultValues.initialRemainingCharacterCount - textView.text.characters.count
        
        if let text = textView.text {
            if text.characters.count > 0 {
                nextButton.isUserInteractionEnabled = true
                nextButton.alpha = 1
            }
            else {
                nextButton.isUserInteractionEnabled = false
                nextButton.alpha = 0.5
            }
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return text.characters.count == 0 || remainingCharacterCount - text.characters.count >= 0
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
