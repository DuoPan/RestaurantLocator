//
//  OneRestaurantCell.swift
//  RestauantLocator
//
//  Created by duo pan on 9/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

import UIKit

class OneRestaurantCell: UITableViewCell {
// reuse these  two labels
    @IBOutlet weak var labelValue: UILabel!
    @IBOutlet weak var labelName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
