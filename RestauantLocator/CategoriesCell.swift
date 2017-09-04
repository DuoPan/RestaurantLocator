//
//  CategoriesCell.swift
//  RestauantLocator
//
//  Created by duo pan on 8/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

import UIKit

class CategoriesCell: UITableViewCell {

    @IBOutlet weak var imageCategory: UIImageView!
    @IBOutlet weak var labelCategoryName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
