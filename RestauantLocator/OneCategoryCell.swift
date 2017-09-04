//
//  OneCategoryCell.swift
//  RestauantLocator
//
//  Created by duo pan on 8/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

import UIKit

class OneCategoryCell: UITableViewCell {

    @IBOutlet weak var imageRestaurant: UIImageView!
    @IBOutlet weak var labelRating: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelLocation: UILabel!
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
