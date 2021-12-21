//
//  roomsCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/25.
//

import UIKit
import ActiveLabel

class roomsCell: UITableViewCell {

    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var updatedTimeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tagLabel: ActiveLabel!
    @IBOutlet weak var roomOwnerImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //ownerの画像に丸みと枠線を設ける
        roomOwnerImageView.layer.borderColor = UIColor.black.cgColor
        roomOwnerImageView.layer.borderWidth = 3
        roomOwnerImageView.layer.cornerRadius = roomOwnerImageView.frame.height/2
        roomOwnerImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
