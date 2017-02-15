//
//  KONTabBarController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Animate Tab Switching 
    func animateToTab(toIndex: Int) {
        
        guard toIndex != selectedIndex else{return}
        
        //Get To View and From View
        guard let viewControllers = viewControllers else{return}
        
        let fromView = viewControllers[selectedIndex].view!
        let toView = viewControllers[toIndex].view!
        
        fromView.superview?.addSubview(toView)
        
        // Position toView off screen (to the left/right of fromView)
        let screenWidth = UIScreen.main.bounds.size.width;
        let scrollRight = toIndex > selectedIndex;
        let offset = (scrollRight ? screenWidth : -screenWidth)
        toView.center = CGPoint(x: fromView.center.x + offset, y: toView.center.y)
        
    
        // Calculate Animate Distance
        
        //Animate And Remove From View
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseOut], animations: { 

            // Slide the views by -offset
            fromView.center = CGPoint(x: fromView.center.x - offset, y: fromView.center.y);
            toView.center   = CGPoint(x: toView.center.x - offset, y: toView.center.y);
            
        }) { finished in
            
            // Remove the old view from the tabbar view.
            fromView.removeFromSuperview()
            self.selectedIndex = toIndex
            
        }
        
    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tabViewControllers = tabBarController.viewControllers!
        guard let toIndex = tabViewControllers.index(of: viewController) else {return false}
    
        // Animate Tab Switch
//        animateToTab(toIndex: toIndex)
        
        return true
    }
    

}
