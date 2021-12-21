//
//  communityCollectionViewCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/21.
//

import UIKit

class communityCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var communityNameLabel: UILabel!
    @IBOutlet weak var communityMembersCount: UILabel!
    @IBOutlet weak var communityIconImage: UIImageView!
    @IBOutlet weak var communityMainColor: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        communityIconImage.layer.borderColor = UIColor.black.cgColor
        communityIconImage.layer.borderWidth = 0.3
        communityIconImage.layer.cornerRadius = communityIconImage.frame.height/2
        communityIconImage.layer.masksToBounds = true
    }

}
