//
//  CustomTextField.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/12/20.
//

import UIKit

class CustomTextField: UITextField {
    // 下線用のUIViewを作っておく
    let underline: UIView = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //↓を記述するとout layoutの関係上上手く動作しなくなる
        //self.frame.size.height = 50
        composeUnderline()
        self.borderStyle = .none
    }
    
    private func composeUnderline(){
        self.underline.frame = CGRect(x: 0, y: self.frame.height, width: self.frame.width, height: 2.5)
        self.underline.backgroundColor = UIColor(red:0.36, green:0.61, blue:0.93, alpha:1.0)
        self.addSubview(self.underline)
        self.bringSubviewToFront(self.underline)
    }
}
