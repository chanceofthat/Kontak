//
//  KONMetTableViewCell.swift
//  Kontak
//
//  Created by Chance Daniel on 2/16/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONMetTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
