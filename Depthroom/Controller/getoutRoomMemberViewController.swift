//
//  getoutMemberViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/10.
//

import UIKit
import Firebase

class getoutRoomMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var room: Room!
    var database: Firestore!
    var roomMemberArray: [AppUser] = []
    var getoutSelectUser: [AppUser] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getoutSelectUser = []
        roomMemberArray = []
        database.collection("rooms").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.room = Room(data: data)
                if let members = data["members"] as? [String:Any]{
                    for member in members.values{
                        let user = AppUser(data: member as! [String:Any])
                        //自身以外のルームのメンバーが退会の対象
                        if self.me.userID != user.userID{
                            self.roomMemberArray.append(user)
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func CompleteGetoutButton(_ sender: Any) {
        if getoutSelectUser.count > 0{
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            
            //アラートを表示させてYesを押したら退会処理完了
            let confirmGetout = UIAlertController(title: "退会させますか?", message: "Yesをタップすると退会処理は取り消せません。本当によろしいですか?", preferredStyle: .alert)
            
            confirmGetout.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            confirmGetout.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                dispatchQueue.async(group: dispatchGroup) {
                    //データベースから削除処理を行う
                    for getoutMember in self.getoutSelectUser{
                        self.database.collection("rooms").document(self.room.roomID).updateData([
                            "members.\(getoutMember.userID!)": FieldValue.delete()
                        ])
                    }
                }
                dispatchGroup.notify(queue: .main){
//                    let alert = UIAlertController(title: "Complete", message: "退会処理が完了しました。", preferredStyle: .alert)
//                    let ok = UIAlertAction(title: "OK", style: .default) { (action) in
//                        self.dismiss(animated: true, completion: nil)
//                    }
//                    alert.addAction(ok)
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }))
            
            self.present(confirmGetout, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //選択してセルにチェックマークがない場合=選択処理
        if(cell?.accessoryType == UITableViewCell.AccessoryType.none){
            cell?.accessoryType = .checkmark
            getoutSelectUser.append(roomMemberArray[indexPath.row])
        }else{
            cell?.accessoryType = .none
            if let index = getoutSelectUser.firstIndex(where: { $0.userID == roomMemberArray[indexPath.row].userID }) {
                getoutSelectUser.remove(at: index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomMemberArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:  indexPath) as! roomCreateCell
        cell.userNameLabel.text = roomMemberArray[indexPath.row].userName
        if let icon = roomMemberArray[indexPath.row].userIcon{
            if let photoURL = URL(string: icon){
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
