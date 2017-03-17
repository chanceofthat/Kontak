//
//  KONExtensions.swift
//  Kontak
//
//  Created by Chance Daniel on 3/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
    
    func setBottomBorderToColor(_ color: UIColor) {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UITextView {
    
    func setBottomBorderToColor(_ color: UIColor) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UIView {
    
    func makeCircular() {
        makeCircularWithBorderColor(nil)
    }
    
    func makeCircularWithBorderColor(_ color: UIColor?) {
        self.contentMode = .scaleAspectFill
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        self.layer.borderWidth = 4
        if let color = color {
            self.layer.borderColor = color.cgColor
        }
    }
}
