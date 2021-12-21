//
//  roomSettingNoticeCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/08.
//

import UIKit

class roomSettingNoticeCell: UITableViewCell {

    @IBOutlet weak var roomSettingLabel: UILabel!
    @IBOutlet weak var noticeSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        noticeSwitch.isOn = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
