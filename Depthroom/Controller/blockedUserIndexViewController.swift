//
//  blockedUserIndexViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/17.
//

import UIKit
import Firebase

class blockedUserIndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var database: Firestore!
    var me: AppUser!
    var meID: String!
    var blockedUser: [AppUser] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "userNameAndIconCell", bundle: nil), forCellReuseIdentifier: "userNameAndIcon")
        
        //ここはfireStoreから呼び出す
        userInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    func userInfo(){
        //主にブロック一覧を呼び出す
        database.collection("users").document(meID).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.me = AppUser(data: data)
                if let blocked = data["blocked"] as? [String:Any]{
                    //ここで配列初期化
                    self.blockedUser = []
                    for block in blocked.values{
                        let user = AppUser(data: block as! [String:Any])
                        self.blockedUser.append(user)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
        nextViewController.user = blockedUser[indexPath.row]
        nextViewController.me = me
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUser.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon") as! userNameAndIconCell
        cell.userNameLabel.text = blockedUser[indexPath.row].userName
        if let photoURL = URL(string: blockedUser[indexPath.row].userIcon){
            do{
                let data = try Data(contentsOf: photoURL)
                let image = UIImage(data: data)
                cell.userIcon.image = image
            }
            catch{
                print("error")
            }
        }
        return cell
    }
}
