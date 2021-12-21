//
//  followsViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/16.
//

import UIKit
import Firebase

class followsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var user: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    //ユーザがフォローしている人の配列
    var followArray: [AppUser] = []
    //ユーザをフォローしてくれている人の配列
    var followerArray: [AppUser] = []
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "userNameAndIconCell", bundle: nil), forCellReuseIdentifier: "userNameAndIcon")
        
       followAndFollowerInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    func followAndFollowerInfo(){
        database.collection("users").document(user.userID).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.user = AppUser(data: data)
                self.userNameLabel.text = self.user.userName
                if let follow = data["follow"] as? [String:Any]{
                    self.followArray = []
                    for follow in follow.values{
                        let userInfo = AppUser(data: follow as! [String:Any])
                        self.followArray.append(userInfo)
                    }
                    self.tableView.reloadData()
                }
                if let follower = data["follower"] as? [String:Any]{
                    self.followerArray = []
                    for follower in follower.values{
                        let userInfo = AppUser(data: follower as! [String:Any])
                        self.followerArray.append(userInfo)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func tappedSegmentedControl(_ sender: Any) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
        switch segmentIndex{
        case 0:
            nextViewController.user = followArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        case 1:
            nextViewController.user = followerArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            return followArray.count
        case 1:
            return followerArray.count
        default:
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon", for: indexPath) as! userNameAndIconCell
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            cell.userNameLabel.text = followArray[indexPath.row].userName
            //アイコンを取得・表示
            if let photoURL = URL(string: followArray[indexPath.row].userIcon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.userIcon.image = image
                }
                catch{
                    print("error")
                }
            }
        case 1:
            cell.userNameLabel.text = followerArray[indexPath.row].userName
            //アイコンを取得・表示
            if let photoURL = URL(string: followerArray[indexPath.row].userIcon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.userIcon.image = image
                }
                catch{
                    print("error")
                }
            }
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/7
    }

}
