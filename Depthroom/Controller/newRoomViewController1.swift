//
//  roomReservationViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/28.
//

import UIKit
import Firebase
import FirebaseStorageUI

class newRoomViewController1: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    //相手が自分をフォローしており、相手の情報を格納
    var followerArray: [AppUser] = []
    //相手が自身をブロックしていることを除いたfollowerArray配列
    var sinFollowerArray: [AppUser] = []
    //ルームに招待する人のIDを格納する配列
    var inviteSelectUserID: [AppUser] = []
    //オープンな部屋かクローズドな部屋かを区別する
    //基本的に部屋作成のオプションから値を受け取る
    var state = "close"
    //フォロワーを選択したかどうかを
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        //timeLabel.delegate = self
        
        //カスタムのセルを登録
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.allowsMultipleSelectionDuringEditing = true
        //フォロワー情報を
        followerInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        inviteSelectUserID = []
    }
    
    func followerInfo(){
        //自分をフォローしてくれているユーザを配列に格納
        database.collection("users").document(me.userID).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.followerArray = []
                //これを次の画面に直接渡すことで、次の画面内にてgetDocumtnする必要がなくなる
                self.me = AppUser(data: data)
                if let follower = data["follower"] as? [String:Any]{
                    for follower in follower.values{
                        let userInfo = AppUser(data: follower as! [String:Any])
                        self.followerArray.append(userInfo)
                    }
                    self.tableView.reloadData()
                }
            }
        }
        
    }
    
    @IBAction func nextButton(_ sender: Any) {
        if inviteSelectUserID.count > 0{
            performSegue(withIdentifier: "completeCreateRoom", sender: me)
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "completeCreateRoom"{
            let nextViewController = segue.destination as! newRoomViewController2
            nextViewController.inviteSelectUser = inviteSelectUserID
            nextViewController.me = me
            //クローズドな状態を値として渡す
            nextViewController.state = state
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //選択してセルにチェックマークがない場合=選択処理
        if(cell?.accessoryType == UITableViewCell.AccessoryType.none){
            cell?.accessoryType = .checkmark
            inviteSelectUserID.append(followerArray[indexPath.row])
        }else{
            cell?.accessoryType = .none
            if let index = inviteSelectUserID.firstIndex(where: { $0.userID == followerArray[indexPath.row].userID }) {
                inviteSelectUserID.remove(at: index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followerArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
        cell.accessoryType = .none
        cell.userNameLabel.text = followerArray[indexPath.row].userName
        if let icon = followerArray[indexPath.row].userIcon{
            let storageRef = icon
            if let photoURL = URL(string: storageRef){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.profileImageView.image = image
                }
                catch{
                    print("error")
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
}

extension newRoomViewController1: UITextFieldDelegate{
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // キーボード入力や、カット/ペースによる変更を防ぐ
        return false
    }
}
