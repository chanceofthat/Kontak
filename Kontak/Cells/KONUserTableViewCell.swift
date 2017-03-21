//
//  KONUserTableViewCell.swift
//  Kontak
//
//  Created by Chance Daniel on 3/18/17.
//  Copyright © 2017 ChanceDaniel. All rights reserved.
//

import UIKit

class KONUserTableViewCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var bioTextViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contactMethodsTextView: UITextView!
    
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var contactMethodsLabel: UILabel!
    
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    
    var expansionHeight: CGFloat = 0
    var bioTextHeight: CGFloat = 0

    
    var isExpanded = false {
        didSet {
            if isExpanded {
                cellHeightConstraint.constant = expansionHeight
                bioTextViewHeightConstraint.constant = bioTextHeight
                bioLabel.isHidden = false
                contactMethodsLabel.isHidden = false

            }
            else {
                cellHeightConstraint.constant = 15
                bioTextViewHeightConstraint.constant = 0
                bioLabel.isHidden = true
                contactMethodsLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
