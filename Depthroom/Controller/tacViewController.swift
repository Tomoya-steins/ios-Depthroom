//
//  tacViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/12/11.
//

import UIKit
import Firebase

class tacViewController: UIViewController {

    var auth: Auth!
    var database: Firestore!
    var me: AppUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        database = Firestore.firestore()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        
        if auth.currentUser?.uid != nil{
            database.collection("users").document(auth.currentUser!.uid).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    self.me = AppUser(data: data)
                    //ユーザネームとアイコンを持っていたら遷移
                    if self.me.userName.isEmpty != true && self.me.userIcon.isEmpty != true{
                        let nextViewController = self.storyboard?.instantiateViewController(identifier: "tabBar") as! tabBarViewController
                        nextViewController.me = self.me
                        self.navigationController?.pushViewController(nextViewController, animated: false)
                    }else{
                        //authには登録しているが、userName, userIconが登録されていないので、そこまで遷移させる
                        let nextViewController = self.storyboard?.instantiateViewController(identifier: "addition") as! additionalRegisterViewController
                        nextViewController.me = AppUser(data: ["userID": self.auth.currentUser!.uid])
                        self.navigationController?.pushViewController(nextViewController, animated: true)
                    }
                }
            }
        }else{
            //currentでないのなら、隣に遷移
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "firstView") as! firstViewController
            self.navigationController?.pushViewController(nextViewController, animated: false)
        }
    }
}
