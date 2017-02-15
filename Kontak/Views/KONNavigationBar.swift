//
//  KONNavigationBar.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONNavigationBar: UINavigationBar {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Set Up Gradient
        layer.insertSublayer(konGradientForRect(frame: bounds), at: 0)
        
        // Set Up Title
        titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 34, weight: UIFontWeightThin), NSForegroundColorAttributeName: UIColor.konBlack]
    }
    
 

}
