//
//  userNameAndIconCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/08.
//

import UIKit

class userNameAndIconCell: UITableViewCell {
    
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var lockedOrUnlockedImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userIcon.layer.borderColor = UIColor.black.cgColor
        userIcon.layer.borderWidth = 0.1
        userIcon.layer.cornerRadius = userIcon.frame.height/2
        userIcon.layer.masksToBounds = true
        lockedOrUnlockedImage.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
