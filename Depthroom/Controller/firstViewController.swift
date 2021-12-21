//
//  firstViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/12/11.
//

import UIKit

class firstViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        //「Start!」ボタン
        signInButton.backgroundColor = UIColor(displayP3Red: 79/255, green: 172/255,     blue: 254/255,alpha: 1.0)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        signInButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        signInButton.layer.cornerRadius = 15.0
        signInButton.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        signInButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        signInButton.layer.shadowOpacity = 0.3
        signInButton.layer.shadowRadius = 5
        //「アカウントをお持ちの方は」ボタン
        logInButton.backgroundColor = UIColor.white
        logInButton.setTitleColor( UIColor(displayP3Red: 79/255, green: 172/255, blue: 254/255,alpha: 1.0), for: .normal)
        logInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        logInButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        logInButton.layer.cornerRadius = 15.0
        logInButton.layer.borderColor =  UIColor(displayP3Red: 79/255, green: 172/255, blue: 254/255,alpha: 1.0).cgColor
        logInButton.layer.borderWidth = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func buttonToSignIn(_ sender: Any) {
        //紹介画面に遷移する
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "intro") as! introViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    @IBAction func buttonToLogIn(_ sender: Any) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "login") as! loginViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
