//
//  KONDiagnosticTableViewCell.swift
//  Kontak
//
//  Created by Chance Daniel on 3/7/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONDiagnosticTableViewCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var userID: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
