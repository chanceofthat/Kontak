//
//  KONOnboardBioViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 3/17/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONOnboardBioViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var remainingCharacterCountLabel: UILabel!
    
    @IBOutlet weak var nextButtonHeightConstraint: NSLayoutConstraint!

    
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
        bioTextView.setBottomBorderToColor(.konLightGray)
        bioTextView.delegate = self
        
        // Set Up Character Count
        remainingCharacterCountLabel.text = remainingCharacterCount.description
        
        // Set Up Next Button
        nextButton.isUserInteractionEnabled = false
        nextButton.alpha = 0.5
        
        // Set Up Gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        animateNextButton(keyboardShowing: false)
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
    
    @IBAction func didPressNextButton(_ sender: UIButton) {
        
        if let bio = bioTextView.text, bio.characters.count > 0 {
            userRef?.bio = bio
        }
    }
    
    // MARK: - Gesture Recognizer Delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view == nextButton)
    }
    
    // MARK: - UITextViewDelegate Protocol
    
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.setBottomBorderToColor(.konBlue)
        animateNextButton(keyboardShowing: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.setBottomBorderToColor(.konLightGray)
        animateNextButton(keyboardShowing: false)
    }
    
    

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? KONOnboardContactMethodsViewController {
            destination.userRef = userRef
        }
    }

}
