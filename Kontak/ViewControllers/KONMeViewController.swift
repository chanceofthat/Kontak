//
//  KONMeViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMeViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet var backgroundView: KONBackgroundView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var backgroundCardView: KONBackgroundCardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up Background View
        backgroundView.setBackgroundImage(image: #imageLiteral(resourceName: "MeBackgroundFill"))
        
        // Set Up BackgroundCard View
        backgroundCardView.roundCorner(corners: .topLeft)
        
        // Set Up TabBar
        if let tabBar = tabBarController?.tabBar {
            tabBar.layer.insertSublayer(konGradientForRect(frame: tabBar.bounds), at: 0)
        }
        tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.konGreen], for: .selected)
        
        
        KONUserManager.sharedInstance.updateKONMeUserRecord()

        
    }

    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
