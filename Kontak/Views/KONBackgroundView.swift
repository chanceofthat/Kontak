//
//  KONBackgroundView.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONBackgroundView: UIView {
    
    // MARK: - Background Image Setup
    func setBackgroundImage(image: UIImage) {
        
        let backgroundImageView = UIImageView(frame: bounds)
        backgroundImageView.image = image
        insertSubview(backgroundImageView, at: 0)
    
    }

    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
