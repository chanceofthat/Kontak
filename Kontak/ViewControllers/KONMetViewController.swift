//
//  KONMetViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMetViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet var backgroundView: KONBackgroundView!
    @IBOutlet weak var backgroundCardView: KONBackgroundCardView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Up Background View
        backgroundView.setBackgroundImage(image: #imageLiteral(resourceName: "MetBackgroundFill"))
        
        // Set Up BackgroundCard View
        backgroundCardView.roundCorner(corners: .topRight)
        
        // Set Up TabBarItem
        tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.konRed], for: .selected)
        
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KONUserManager.sharedInstance.queryForMetUsers()
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
