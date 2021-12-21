//
//  roomMemberAndInvitationIndexViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/08.
//

import UIKit
import Firebase

class roomMemberAndInvitationIndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var room: Room!
    var database: Firestore!
    var storage: Storage!
    var sections: [String] = []
    var memberArray: [AppUser] = []
    var invitationArray: [AppUser] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        sections = []
        tableView.register(UINib(nibName: "userNameAndIconCell", bundle: nil), forCellReuseIdentifier: "userNameAndIcon")
        
        if room.state == "open"{
            sections = ["参加者"]
        }else if room.state == "close"{
            sections = ["参加者", "招待中"]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        memberArray = []
        invitationArray = []
        
        //メンバーなどに変更がある場合に備えて
        database.collection("rooms").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.room = Room(data: data)
                
                if let members = self.room.members{
                    for data in members.values{
                        let user = AppUser(data: data as! [String : Any])
                        self.memberArray.append(user)
                    }
                }
                if let invitaion = self.room.invitations{
                    for data in invitaion.values{
                        let user = AppUser(data: data as! [String:Any])
                        self.invitationArray.append(user)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section{
        case 0:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
            nextViewController.user = memberArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        case 1:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
            nextViewController.user = invitationArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return memberArray.count
        case 1:
            return invitationArray.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section{
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon") as! userNameAndIconCell
            cell.userNameLabel.text = memberArray[indexPath.row].userName
            
            if let photoURL = URL(string: memberArray[indexPath.row].userIcon){
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
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon") as! userNameAndIconCell
            cell.userNameLabel.text = invitationArray[indexPath.row].userName
            
            if let photoURL = URL(string: invitationArray[indexPath.row].userIcon){
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
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell")
            cell?.textLabel?.text = ""
            return cell!
        }
    }

    
}
