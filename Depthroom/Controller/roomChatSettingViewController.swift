//
//  roomChatSettingViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/07.
//

import UIKit
import Firebase


class roomChatSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var auth: Auth!
    var database: Firestore!
    var room: Room!
    var me: AppUser!
    var owner: AppUser!
    var roomIndex: [String] = []
    var roomOwnerIndex: [String] = ["編集", "退会させる", "部屋を削除"]
    var  sectionTitle: [String] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        database = Firestore.firestore()
        tableView.delegate = self
        tableView.dataSource = self

        
        tableView.register(UINib(nibName: "roomSettingIndexCell", bundle: nil), forCellReuseIdentifier: "indexCell")
        tableView.register(UINib(nibName: "roomSettingNoticeCell", bundle: nil), forCellReuseIdentifier: "noticeCell")
        tableView.register(UINib(nibName: "roomSettingNextCell", bundle: nil), forCellReuseIdentifier: "nextCell")
        
        if let data = room.owner{
            let user = AppUser(data: data)
            owner = user
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //今回はナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        roomIndex = []
        sectionTitle = []
        
        //クローズの時招待機能を入れる必要がある
        //オープンの時はいらない
        if owner.userID == auth.currentUser?.uid{
            //セクション数が変わる
            sectionTitle = ["ルームオプション", "作成者オプション"]
            if room.state == "close"{
                roomIndex = ["参加者一覧", "通知", "招待する"]
            }else if room.state == "open"{
                roomIndex = ["参加者一覧", "通知"]
            }
        }else{
            //セクション数が変わる
            sectionTitle = ["ルームオプション"]
            if room.state == "close"{
                roomIndex = ["参加者一覧", "通知", "招待する", "退会する"]
            }else if room.state == "open"{
                roomIndex = ["参加者一覧", "通知", "退会する"]
            }
        }
    }
    
    //自身が退会する時(オーナには適用されない)
    func getoutMeAlert(){
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        let confirmGetoutMe = UIAlertController(title: "退会しますか?", message: "Yesをタップすると退会処理は取り消せません。本当によろしいですか?", preferredStyle: .alert)
        confirmGetoutMe.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        confirmGetoutMe.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            dispatchQueue.async(group: dispatchGroup) {
                //データベースから削除処理を行う
                self.database.collection("rooms").document(self.room.roomID).updateData([
                    "members.\(self.me.userID!)": FieldValue.delete()
                ])
            }
            dispatchGroup.notify(queue: .main){
                //self.dismiss(animated: true, completion: nil)
                self.navigationController?.popToRootViewController(animated: true)
            }
        }))
        self.present(confirmGetoutMe, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section{
        case 0:
            switch roomIndex[indexPath.row]{
            case "参加者一覧":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "memberAndInvitationIndex") as! roomMemberAndInvitationIndexViewController
                nextViewController.me = me
                nextViewController.room = room
                self.navigationController?.pushViewController(nextViewController, animated: true)
            case "通知":
                return
            case "招待する":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "invitation") as! invitationToRommViewController
                nextViewController.me = me
                nextViewController.room = room
                self.present(nextViewController, animated: true, completion: nil)
                
            case "退会する":
                getoutMeAlert()
            default:
                break
            }
        case 1:
            switch roomOwnerIndex[indexPath.row]{
            case "編集":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "editRoom") as! editRoomViewController
                nextViewController.me = me
                nextViewController.room = room
                self.present(nextViewController, animated: true, completion: nil)
            case "退会させる":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "getoutRoomMember") as! getoutRoomMemberViewController
                nextViewController.me = me
                nextViewController.room = room
                self.present(nextViewController, animated: true, completion: nil)
            case "部屋を削除":
                print("削除")
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return roomIndex.count
        case 1:
            return roomOwnerIndex.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section{
        case 0:
            switch roomIndex[indexPath.row]{
            case "参加者一覧":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = roomIndex[indexPath.row]
                return cell
            case "招待する":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = roomIndex[indexPath.row]
                return cell
            case "退会する":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = roomIndex[indexPath.row]
                return cell
            case "通知":
                let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell") as! roomSettingNoticeCell
                cell.roomSettingLabel.text = roomIndex[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        case 1:
            switch roomOwnerIndex[indexPath.row]{
            case "編集":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = roomOwnerIndex[indexPath.row]
                return cell
            case "退会させる":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = roomOwnerIndex[indexPath.row]
                return cell
            case "部屋を削除":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = roomOwnerIndex[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
            cell.roomSettingLabel.text = ""
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height/10
    }
}
