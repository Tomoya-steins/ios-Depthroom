//
//  roomOptionViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/06.
//

import UIKit
import Firebase

class roomOptionViewController: UIViewController {

    var auth: Auth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        
        self.view.backgroundColor = UIColor(red: 245, green: 245, blue: 245, alpha: 50)
        
        //スクリーンの横縦
        let screenWidth: CGFloat = self.view.frame.width
        let screenHeight: CGFloat = self.view.frame.height
        
        let openButton = UIButton()
        let closedButton = UIButton()
        let communityButton = UIButton()
        
        //オープンボタン
        openButton.frame = CGRect(x: 4*screenWidth/10, y: screenHeight/10, width: screenWidth/5, height: 50)
        openButton.setTitle("Open", for: UIControl.State.normal)
        openButton.setImage(UIImage(systemName: "lock.open.fill"), for: UIControl.State.normal)
        openButton.setTitleColor(UIColor.black, for: .normal)
        openButton.titleLabel?.font =  UIFont.systemFont(ofSize: 17)
        openButton.addTarget(self, action: #selector(self.openButton), for: .touchUpInside)
        //openButton.backgroundColor = UIColor.init(red:0.9, green: 0.9, blue: 0.9, alpha: 1)
        self.view.addSubview(openButton)
        
        //クローズボタン
        closedButton.frame = CGRect(x: 7*screenWidth/10, y: screenHeight/10, width: screenWidth/5, height: 50)
        closedButton.setTitle("Close", for: UIControl.State.normal)
        closedButton.setImage(UIImage(systemName: "lock.fill"), for: UIControl.State.normal)
        closedButton.setTitleColor(UIColor.black, for: .normal)
        closedButton.titleLabel?.font =  UIFont.systemFont(ofSize: 17)
        closedButton.addTarget(self, action: #selector(self.closedButton), for:.touchUpInside)
        //closedButton.backgroundColor = UIColor.init(red:0.9, green: 0.9, blue: 0.9, alpha: 1)
        self.view.addSubview(closedButton)
        
        //コミュニティボタン
        communityButton.frame = CGRect(x: screenWidth/15, y: screenHeight/10, width: screenWidth/3, height: 50)
        communityButton.setTitle("Community", for: UIControl.State.normal)
        communityButton.setTitleColor(UIColor.black, for: .normal)
        communityButton.titleLabel?.font =  UIFont.systemFont(ofSize: 20)
        //closeButton.backgroundColor = UIColor.init(red:0.9, green: 0.9, blue: 0.9, alpha: 1)
        communityButton.addTarget(self, action: #selector(self.selectCommunityButton), for:.touchUpInside)
        self.view.addSubview(communityButton)
        
    }
    @objc func closedButton(_ sender: Any){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let nextViewController = storyboard.instantiateViewController(identifier: "newRoom1") as? newRoomViewController1 else { return }
        nextViewController.modalPresentationStyle = .fullScreen
        nextViewController.me = AppUser(data: ["userID": auth.currentUser!.uid])
        nextViewController.state = "close"
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @objc func openButton(_ sender: Any){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let nextViewController = storyboard.instantiateViewController(identifier: "newRoom2") as? newRoomViewController2 else { return }
        nextViewController.modalPresentationStyle = .fullScreen
        nextViewController.me = AppUser(data: ["userID": auth.currentUser!.uid])
        //nextViewController.reserve = ""
        nextViewController.state = "open"
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @objc func selectCommunityButton(_ sender: Any){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let nextViewController = storyboard.instantiateViewController(identifier: "selectCommunity") as? selectCommunityViewController else { return }
        nextViewController.modalPresentationStyle = .fullScreen
        nextViewController.me = AppUser(data: ["userID": auth.currentUser!.uid])
        self.present(nextViewController, animated: true, completion: nil)
    }

}
