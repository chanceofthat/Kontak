//
//  KONConstants.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import Foundation
import UIKit

// MARK: - NSObject 

extension NSObject {
    var className: String {
        return NSStringFromClass(type(of: self))
    }
    
    public class var className: String{
        return NSStringFromClass(self)
    }
}

// MARK: - Targetable

//extension Bool: Targetable {
//    func getValue() -> Bool {
//        return self
//    }
//}

// MARK: - Colors and Gradients
extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
    
    static let konGreen = UIColor.init(hex: 0x00B9A9)
    static let konYellow = UIColor.init(hex: 0xF8F4D2)
    static let konBlue = UIColor.init(hex: 0x58B2E6)
    static let konRed = UIColor.init(hex: 0xEA5455)
    static let konBlack = UIColor.init(hex: 0x343434)
    static let konGray = UIColor.init(hex: 0xF0F0F0)
}

func konGradientForRect(frame: CGRect) -> CAGradientLayer {
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.white.cgColor, UIColor.konGray.cgColor]
    gradient.startPoint = CGPoint(x: 0, y: 1)
    gradient.endPoint = CGPoint(x: 1, y: 0)
    gradient.frame = frame
    
    return gradient
}

// MARK: - Corner Rounding
extension CALayer {
    func roundCorners(corners: UIRectCorner, radius: CGFloat, viewBounds: CGRect) {
        
        let maskPath = UIBezierPath(roundedRect: viewBounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
        
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        
        mask = shape
    }
}

// MARK: - Strings
let KONNearbyTableCellReuseIdentifier = "KONNearbyTableCellReuseIdentifier"
let KONMetTableCellReuseIdentifier = "KONMetTableCellReuseIdentifier"

let KONDefaultsUserIDKey = "KONUserIDKey"

// MARK: - Location
let KONRegionRadius: Double = 50
let KONRegionRange: Int = 7
let KONNearbyRange: Int = 9
let KONRegionIdentifier = "KONRegionIdentifier"

// MARK: - Meet Criteria
let KONMeetDuration: TimeInterval = 0.5 //minutes

struct Constants {
    struct StateController {
        struct RuleNames {
            static let meUserAvailableRule = "MeUserAvailableRule"
            static let locationAvailableRule = "LocationAvailableRule"
            static let meUserAndLocationAvailableRule = "MeUserAndLocationAvailableRule"
        }
    }
}

