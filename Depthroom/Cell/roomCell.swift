//
//  roomCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/13.
//

import UIKit
import ActiveLabel

class roomCell: UITableViewCell {

    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var roomOwnerImageView: UIImageView!
    @IBOutlet weak var mainBackground: UIView!
    @IBOutlet weak var updatedTimeLabel: UILabel!
    var color: String!
    @IBOutlet weak var tagLabel: ActiveLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //cell自体の設定
        mainBackground.layer.cornerRadius = 20
        mainBackground.layer.masksToBounds = true
        mainBackground.layer.borderWidth = 0.5
        
        //roomThumbnailの画像の左上と左下に丸みと枠線を設ける
        //roomThumbnailImageView.layer.cornerRadius = 20
        //roomThumbnailImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        //roomThumbnailImageView.layer.masksToBounds = true
        //ownerの画像に丸みと枠線を設ける
        roomOwnerImageView.layer.borderColor = UIColor.black.cgColor
        roomOwnerImageView.layer.borderWidth = 3
        roomOwnerImageView.layer.cornerRadius = roomOwnerImageView.frame.height/2
        roomOwnerImageView.layer.masksToBounds = true
        
        //丸
        //let drawView = DrawView(frame: UIScreen.main.bounds, color: color)
        //self.view.addSubview(drawView)
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
