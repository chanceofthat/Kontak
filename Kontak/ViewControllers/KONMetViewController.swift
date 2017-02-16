//
//  KONMetViewController.swift
//  Kontak
//
//  Created by Chance Daniel on 2/9/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    @IBOutlet var backgroundView: KONBackgroundView!
    @IBOutlet weak var backgroundCardView: KONBackgroundCardView!
    @IBOutlet weak var tableView: UITableView!
    
    var userManager: KONUserManager!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get User Manager Singleton
        userManager = KONUserManager.sharedInstance
        userManager.metControllerUpdateCallback = {[weak self] in
            guard let `self` = self else { return }
            
            self.tableView.reloadData()
        }

        // Set Up BackgroundView
        backgroundView.setBackgroundImage(image: #imageLiteral(resourceName: "MetBackgroundFill"))
        
        // Set Up BackgroundCardView
        backgroundCardView.roundCorner(corners: .topRight)
        
        // Set Up TabBarItem
        tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.konRed], for: .selected)
        
        // Set Up TableView
        tableView.dataSource = self
        tableView.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - UITableViewDelegate Protocol
    
    
    
    // MARK: - UITableViewDataSource Protocol
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userManager.metUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: KONMetTableCellReuseIdentifier) as! KONMetTableViewCell
        
//        cell.nameLabel.text = userManager.nearbyUsers[indexPath.row].name.fullName
        cell.uuidLabel.text = userManager.metUsers.userIDs[indexPath.row]
        
        
        return cell
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
