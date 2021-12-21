//
//  sideMenuCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/24.
//

import UIKit

class sideMenuCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        iconImage.layer.borderColor = UIColor.black.cgColor
        iconImage.layer.borderWidth = 0.5
        iconImage.layer.cornerRadius = iconImage.frame.height/2
        iconImage.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
