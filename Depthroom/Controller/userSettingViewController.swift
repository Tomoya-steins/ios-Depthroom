//
//  userSettingViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/01.
//

import UIKit
import Firebase

class userSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var auth: Auth!
    var database: Firestore!
    //自分自身の設定画面の場合、meには何も値が入っていないため、取扱注意!
    var me: AppUser!
    //自分自身の設定画面の場合、userには自身の情報が入っている
    //他人の設定画面の場合、userには他人の情報が入っている
    var user: AppUser!
    var optionArray: [String] = []
    var blockOrUnblock = "ブロックする"
    //相手からブロックされているか
    //チャット画面への遷移の際に使用される
    var blocked = false
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        database = Firestore.firestore()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "roomSettingNextCell", bundle: nil), forCellReuseIdentifier: "nextCell")
        tableView.register(UINib(nibName: "roomSettingIndexCell", bundle: nil), forCellReuseIdentifier: "indexCell")
        tableView.register(UINib(nibName: "roomSettingNoticeCell", bundle: nil), forCellReuseIdentifier: "noticeCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        //配列初期化
        optionArray = []
        //自身のページかどうかで処理を分ける
        if auth.currentUser?.uid == user.userID{
            //自身の場合、退会などのオプション
            optionArray = ["アカウントに鍵をかける", "ブロックしているユーザ", "利用規約", "ログアウトする", "退会する"]
            
        }else if auth.currentUser?.uid != user.userID{
            //他人の場合メッセージ・ブロック関係
            //既に自分は相手をブロックしているかどうか確認する
            if let blocked = me.blocked{
                for block in blocked.values{
                    let userInfo = AppUser(data: block as! [String : Any])
                    if user.userID == userInfo.userID{
                        blockOrUnblock = "ブロックを解除する"
                    }
                }
            }
            optionArray = ["メッセージを送る", blockOrUnblock]
            
            //他人からブロックされているかどうか
            if let block = user.blocked{
                for block in block.values{
                    let blockUser = AppUser(data: block as! [String:Any])
                    if me.userID == blockUser.userID{
                        //ブロックされていた場合、"メッセージを送る"への遷移を防ぐために使う
                       blocked = true
                    }
                }
            }
        }
    }
    
    func logout(){
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        let confirmLogout = UIAlertController(title: "確認", message: "アカウント名「\(user.userName!)」からログアウトしますか?", preferredStyle: .alert)
        confirmLogout.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        confirmLogout.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            dispatchQueue.async(group: dispatchGroup){
                try? self.auth.signOut()
                self.dismiss(animated: true, completion: nil)
            }
            dispatchGroup.notify(queue: .main){
                let newRegisterViewController = self.storyboard?.instantiateViewController(identifier: "firstView") as! firstViewController
                self.navigationController?.pushViewController(newRegisterViewController, animated: true)
            }
        }))
        self.present(confirmLogout, animated: true, completion: nil)
    }
    
    func blockUserIndex(){
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "blockedUserIndex") as! blockedUserIndexViewController
        nextViewController.meID = auth.currentUser?.uid
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func doBlockOrUnblock(state: String){
        if me != nil{
            //stateに合わせて処理を行う
            let meRef = database.collection("users").document(me.userID)
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            if state == "ブロックする"{
                //アラートを表示
                let confirmBlock = UIAlertController(title: "確認", message: "\(user.userName!)をブロックしますか?", preferredStyle: .alert)
                confirmBlock.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                confirmBlock.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    dispatchQueue.async(group: dispatchGroup){
                        dispatchGroup.enter()
                        meRef.setData([
                            "blocked": [
                                self.user.userID: [
                                    "userID": self.user.userID,
                                    "userName": self.user.userName,
                                    "userIcon": self.user.userIcon
                                ]
                            ]
                        ], merge:  true)
                        dispatchGroup.leave()
                    }
                    dispatchGroup.notify(queue: .main){
                        self.dismiss(animated: true, completion: nil)
                        self.navigationController?.popViewController(animated: true)
                    }
                }))
                self.present(confirmBlock, animated: true, completion: nil)
            }else if state == "ブロックを解除する"{
                //アラートを表示
                let confirmUnblock = UIAlertController(title: "確認", message: "\(user.userName!)に対してのブロックを解除しますか?", preferredStyle: .alert)
                confirmUnblock.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                confirmUnblock.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    dispatchQueue.async(group: dispatchGroup){
                        dispatchGroup.enter()
                        meRef.updateData([
                            "blocked.\(self.user.userID!)": FieldValue.delete()
                        ])
                        dispatchGroup.leave()
                    }
                    dispatchGroup.notify(queue: .main){
                        self.dismiss(animated: true, completion: nil)
                        self.navigationController?.popViewController(animated: true)
                    }
                }))
                self.present(confirmUnblock, animated: true, completion: nil)
            }
        }
    }
    
    func directMessage(){
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "directMessage") as! directMessageViewController
        nextViewController.user = user
        nextViewController.me = me
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func blockedAlert(){
        let alert = UIAlertController(title: "ブロックされています", message: "現在\(user.userName!)にブロックされています。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func lockOrUnlock(sender: UISwitch){
        let meRef = database.collection("users").document(user.userID)
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        let onCheck: Bool = sender.isOn
        //有効化した時
        if onCheck == true{
            //アラートを表示
            let confirmlock = UIAlertController(title: "確認", message: "鍵アカウント化を有効にしますか?", preferredStyle: .alert)
            confirmlock.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
                //yesでもnoでもスイッチはonになるので、ここでoffにしておく
                sender.isOn = false
            }))
            confirmlock.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                dispatchQueue.async(group: dispatchGroup){
                    dispatchGroup.enter()
                    meRef.updateData([
                        "locked": true
                    ])
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main){
                    self.dismiss(animated: true, completion: nil)
                    
                }
            }))
            self.present(confirmlock, animated: true, completion: nil)
            
        }else{
            //無効化した時
            //アラートを表示
            let confirmunlock = UIAlertController(title: "確認", message: "鍵アカウント化を無効にしますか?", preferredStyle: .alert)
            confirmunlock.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
                //yesでもnoでもスイッチはonになるので、ここでoffにしておく
                sender.isOn = true
            }))
            confirmunlock.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                dispatchQueue.async(group: dispatchGroup){
                    dispatchGroup.enter()
                    meRef.updateData([
                        "locked": false
                    ])
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main){
                    self.dismiss(animated: true, completion: nil)
                }
            }))
            self.present(confirmunlock, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if auth.currentUser?.uid == user.userID{
            //自身ならば
            switch optionArray[indexPath.row]{
            case "アカウントに鍵をかける":
                return
            case "ブロックしているユーザ":
                blockUserIndex()
            case "利用規約":
                return
            case "ログアウトする":
                logout()
            case "退会する":
                return
            default:
                break
            }
        }else{
            //相手のならば
            switch optionArray[indexPath.row]{
            case "メッセージを送る":
                //相手にブロックされているかで処理を分ける
                if blocked == false{
                    directMessage()
                }else if blocked == true{
                    blockedAlert()
                }
            case "ブロックする":
                doBlockOrUnblock(state: optionArray[indexPath.row])
            case "ブロックを解除する":
                doBlockOrUnblock(state: optionArray[indexPath.row])
            default:
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if auth.currentUser?.uid == user.userID{
            //自身ならば
            switch optionArray[indexPath.row]{
            case "アカウントに鍵をかける":
                let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell") as! roomSettingNoticeCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                //もし自分が鍵アカウント化しているのならば
                //スイッチはONの状態になる
                if let lock = user.locked{
                    if lock == true{
                        cell.noticeSwitch.isOn = true
                    }
                }
                //スイッチをタップした時の処理
                cell.noticeSwitch.addTarget(self, action: #selector(self.lockOrUnlock), for: UIControl.Event.valueChanged)
                return cell
            case "ブロックしているユーザ":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            case "利用規約":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            case "ログアウトする":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            case "退会する":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        }else{
            //相手のならば
            switch optionArray[indexPath.row]{
            case "メッセージを送る":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            //ブロックするorブロックを解除する
            case blockOrUnblock:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = optionArray[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/7
    }
}
