//
//  indicatorViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/12/09.
//

import UIKit

class indicatorViewController: UIViewController {

    var backView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func start(indicator: UIActivityIndicatorView){
        if indicator.isAnimating == false{
            print("start")
            backView.frame = self.view.frame
            backView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
            indicator.center = view.center
            indicator.style = .large
            indicator.color = UIColor(red: 44/255, green: 169/255, blue: 225/255, alpha: 1)
            backView.addSubview(indicator)
            view.addSubview(backView)
            indicator.startAnimating()
        }
    }
    func stop(indicator: UIActivityIndicatorView){
        if indicator.isAnimating == true{
            print("stop")
            indicator.stopAnimating()
            backView.removeFromSuperview()
        }
    }
}
