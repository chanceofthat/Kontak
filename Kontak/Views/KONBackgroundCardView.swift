//
//  KONBackgroundCardView.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONBackgroundCardView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Set Up Gradient
        layer.insertSublayer(konGradientForRect(frame: bounds), at: 0)
    
    }
    
    func roundCorner(corners: UIRectCorner) {
        layer.roundCorners(corners: corners, radius: 40, viewBounds: bounds)
    }

}
