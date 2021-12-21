//
//  communityCreateCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/11.
//

import UIKit

class communityCreateCell: UITableViewCell {

    @IBOutlet weak var communityIcon: UIImageView!
    @IBOutlet weak var communityNameLabel: UILabel!
    @IBOutlet weak var memberCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        communityIcon.layer.borderColor = UIColor.black.cgColor
        communityIcon.layer.borderWidth = 1
        communityIcon.layer.cornerRadius = communityIcon.frame.height/2
        communityIcon.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}
