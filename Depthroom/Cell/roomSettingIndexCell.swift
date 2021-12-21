//
//  roomSettingIndexCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/08.
//

import UIKit

class roomSettingIndexCell: UITableViewCell {

    @IBOutlet weak var roomSettingLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let view = UIScreen.main.bounds
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
