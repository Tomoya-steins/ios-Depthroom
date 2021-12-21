//
//  newRoomViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/08.
//

import UIKit
import Firebase
import FirebaseStorageUI

class newRoomViewController2: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    //ルームに招待する人のIDを格納する配列
    var inviteSelectUser: [AppUser] = []
    //招待者の情報をFireStoreに保存する際に使われる
    var inviteMap: [String:Any] = [:]
    //オープンな部屋かクローズドな部屋かを区別する
    //オープンの場合はルーム一覧から、クローズドの場合は前画面から受け取る
    var state: String!
    //コミュニティから部屋を作成する場合に使用する
    //コミュニティの情報を受け取っている
    var myCommunity: Community!
    var tagArray: [Tag] = []
    var tagMap: [String:Any] = [:]
    //登録されていないタグ
    var unRegisterTag: [String] = []
    //インディケータ
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    
    @IBOutlet weak var roomNameLabel: CustomTextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tagLabel: CustomTextField!
    @IBOutlet weak var Nametag: UILabel!
    @IBOutlet weak var buttonToAddTag: UIButton!
    
    
    
    //roomsのmembersに自身の情報を登録させる際、紹介文が空の場合の対策
    //var meDescription = "null"
    //"example"は仮置き
    var roomID = "example"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        roomNameLabel.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        //カスタムのセルを登録
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "communityCreateCell", bundle: nil), forCellReuseIdentifier: "communityCreate")
        
        //タグを付けるボタンの初期設定
        buttonToAddTag.isSelected = false
        buttonToAddTag.setTitle("タグを付ける", for: UIControl.State.normal)
        Nametag.isHidden = true
        tagLabel.isHidden = true
    }
    
    //クルクルを表示するためのメソッド
    private func showIndicator(){
        backView.frame = self.view.frame
        backView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        indicator.center = view.center
        indicator.style = .large
        indicator.color = UIColor(red: 44/255, green: 169/255, blue: 225/255, alpha: 1)
        backView.addSubview(indicator)
        view.addSubview(backView)
        indicator.startAnimating()
    }
    
    //createボタンを押した時のアクション
    @IBAction func createRoom(_ sender: Any) {
        let roomName = roomNameLabel.text!
        let tags = tagLabel.text!
        //タグに関する処理
        if tags.isEmpty != true{
            let shap = tags.range(of: "#")
            if shap == nil{
                let alert = UIAlertController(title: "#が付いてません!", message: "タグの先頭に#を付けてください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return;
            }
        }
        //直列処理のために必要
        let dispatchGroup = DispatchGroup()
        let semaphoreSet = DispatchSemaphore(value: 0)
        let semaphoreGet = DispatchSemaphore(value: 0)
        
        //無闇にFireStoreに接続させないためにif 文で空かどうかを判断する
        if roomName.isEmpty != true{
            //通信開始したので、クルクルさせる
            showIndicator()
            if tags.isEmpty != true{
                //タグの処理
                tagInfo(tags: tags, dispatch: dispatchGroup)
            }
            
            //上のタグの検索処理が終わったら下に続く
            dispatchGroup.notify(queue: .main){
                if tags.isEmpty != true{
                    //上からとってきた配列の登録を済ませる
                    self.registerTagToTags()
                }
                
                //クローズドを選択した場合、あらかじめユーザの情報を前画面にてgetしているため、この画面でgetDocumentする必要がなくなる→FireStore接続の回数を節約できる
                if self.state == "close"{
                    self.registerRoomAndInvitation(roomName: roomName, meName: self.me.userName, meIcon: self.me.userIcon, semaphoreSet: semaphoreSet)
                }else{
                    //ownerのユーザの名前を登録する必要があるため、クロージャを用いてnameを取得し、ルームと招待者を登録している
                    self.database.collection("users").document(self.me.userID).getDocument { (snapshot, error) in
                        if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                            self.me = AppUser(data: data)
                            let meName = self.me.userName
                            let meIcon = self.me.userIcon
                            //description は空の場合があり得るため
                            //self.meDescription = self.me.userDescription
                            //ルームと招待者の登録を行う
                            self.registerRoomAndInvitation(roomName: roomName, meName: meName!, meIcon: meIcon!, semaphoreSet: semaphoreSet)
                            semaphoreGet.signal()
                        }
                    }
                }
                //この画面でルーム登録を終わらせるために0.3秒の遅延
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    //セマフォカウント -1
                    if self.state == "open"{
                        semaphoreGet.wait()
                    }
                    semaphoreSet.wait()
                    self.indicator.stopAnimating()
                    //全て登録したら画面遷移
                    if self.indicator.isAnimating == false{
                        //クローズかオープンかコミュニティかで処理が微妙に異なる
                        if self.state == "close" || self.myCommunity != nil{
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                        }else{
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func cancelRoomCreate(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    //タップによって表示する内容を変更する
    @IBAction func buttonToAddTag(_ sender: Any) {
        if buttonToAddTag.isSelected == true{
            buttonToAddTag.isSelected = false
            buttonToAddTag.setTitle("タグを付ける", for: UIControl.State.normal)
            Nametag.isHidden = true
            tagLabel.isHidden = true
            tagLabel.text = ""
        }else if buttonToAddTag.isSelected == false{
            buttonToAddTag.isSelected = true
            buttonToAddTag.setTitle("タグを非表示", for: UIControl.State.normal)
            Nametag.isHidden = false
            tagLabel.isHidden = false
        }
    }
    
    //createボタンを押した時のタグの処理
    func tagInfo(tags: String, dispatch: DispatchGroup){
        tagArray = []
        unRegisterTag = []
        let dispatchQueue = DispatchQueue(label: "queue")
        //let globalQueue = DispatchQueue.global(qos: .default)
        
        //タグに対しての処理
        let hashTagText = tags as NSString?
        do{
            let regex = try NSRegularExpression(pattern: "#\\S+", options: [])
            //見つけたハッシュタグを、for文で回す。
            for match in regex.matches(in: hashTagText! as String, options: [], range: NSRange(location: 0, length: hashTagText!.length)) {
                //この中に#~のようにタグ名が入る
                let tag = hashTagText!.substring(with: match.range)
                
                //登録するタグがtagsにあるかを確認
                //検索を優先させるためdispatch処理が必要
                let dispatchSemaphore = DispatchSemaphore(value: 0)
                dispatchQueue.async(group: dispatch) {
                    dispatch.enter()
                    self.database.collection("tags").whereField("tagName", isEqualTo: tag).getDocuments { (snapshot, error) in
                        //登録していなかったらunRegisterに登録
                        if error == nil, snapshot?.documents.count == 0{
                            self.unRegisterTag.append(tag)
                        }
                        if error == nil, let snapshot = snapshot, snapshot.documents.count > 0{
                            for document in snapshot.documents{
                                //tagsに存在していた場合、その情報をarrayに入れる
                                let data = document.data()
                                let tagComponent = Tag(data: data)
                                self.tagArray.append(tagComponent)
                            }
                        }
                        dispatch.leave()
                        dispatchSemaphore.signal()
                    }
                    dispatchSemaphore.wait()
                }
            }
        }catch{
            print("errorTag")
        }
    }
    
    func registerTagToTags(){
        for unRegister in self.unRegisterTag{
            let saveTag = self.database.collection("tags").document()
            saveTag.setData([
                "tagID": saveTag.documentID,
                "tagName": unRegister
            ])
            let data = ["tagID": saveTag.documentID, "tagName": unRegister]
            let tagComponent = Tag(data: data)
            self.tagArray.append(tagComponent)
        }
    }
    
    //createRoomアクション時の登録に関する処理
    func registerRoomAndInvitation(roomName: String, meName: String, meIcon: String, semaphoreSet: DispatchSemaphore){
     
        if roomName.isEmpty != true {
            if tagArray.count > 0{
                //タグをmap型に対応
                for tag in tagArray{
                    tagMap["\(tag.tagID!)"] = [
                        "tagID": tag.tagID,
                        "tagName": tag.tagName
                    ]
                }
            }
            
            //クローズドな部屋
            if state == "close"{
                //招待者の情報を"invitation"に保存
                for invite in inviteSelectUser{
                    inviteMap["\(invite.userID!)"] = [
                        "userID": invite.userID,
                        "userName": invite.userName,
                        //"description": invite.userDescription,
                        "userIcon": invite.userIcon
                    ]
                }
                
                let saveRoom = database.collection("rooms").document()
                saveRoom.setData([
                    "roomID": saveRoom.documentID,
                    "roomName": roomName,
                    "owner": [
                        "userID": me.userID,
                        "userName": me.userName,
                        "userIcon": me.userIcon
                    ],
                    "state": state!,
                    //予約の廃止により
                    //"visible": true,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "tags": tagMap,
                    "invitations": inviteMap,
                    "members": [
                        me.userID: [
                            "userID": me.userID,
                            "userName": meName,
                            //"userDescription": meDescription,
                            "userIcon": meIcon
                        ]
                    ]
                ]){err in
                    if let err = err{
                        print("Error writing document: \(err)")
                    }else{
                        print("Document successfully written!")
                    }
                }
                semaphoreSet.signal()
                
                //roomID(documentID)を変数に格納、ルームのサムネイル画像のファイル名に使用する
//                roomID = saveRoom.documentID
//
//                //プロフィール画像を保存
//                let data = image.jpegData(compressionQuality: 1.0)
//                self.sendProfileImageData(data: data!, roomID: roomID)
            }else{
                //オープンな部屋
                let saveRoom = database.collection("rooms").document()
                //コミュニティとして部屋を作成しているかどうか
                if myCommunity != nil{
                    saveRoom.setData([
                        "roomID": saveRoom.documentID,
                        "roomName": roomName,
                        "owner": [
                            "userID": me.userID,
                            "userName": me.userName,
                            "userIcon": me.userIcon
                        ],
                        "state": state!,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp(),
                        "tags": tagMap,
                        "members": [
                            me.userID: [
                                "userID": me.userID,
                                "userName": meName,
                                //"userDescription": meDescription,
                                "userIcon": meIcon
                            ]
                        ],
                        //ここにコミュニティの情報を載せる
                        "community": [
                            "communityID": myCommunity.communityID,
                            "communityName": myCommunity.communityName,
                            "communityIcon": myCommunity.communityIcon,
                            "communityColor": myCommunity.communityColor
                        ],
                        "invitations": []
                    ]){err in
                        if let err = err{
                            print("Error writing document: \(err)")
                        }else{
                            print("Document successfully written!")
                        }
                    }
                    semaphoreSet.signal()
                }else{
                    print("ここで登録")
                    saveRoom.setData([
                        "roomID": saveRoom.documentID,
                        "roomName": roomName,
                        "owner": [
                            "userID": me.userID,
                            "userName": me.userName,
                            "userIcon": me.userIcon
                        ],
                        //予約廃止
                        //"visible": true,
                        "state": state!,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp(),
                        "tags": tagMap,
                        "members": [
                            me.userID: [
                                "userID": me.userID,
                                "userName": meName,
                                //"userDescription": meDescription,
                                "userIcon": meIcon
                            ]
                        ],
                        "invitations": []
                    ]){err in
                        if let err = err{
                            print("Error writing document: \(err)")
                        }else{
                            print("Document successfully written!")
                        }
                    }
                    semaphoreSet.signal()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //選択したコミュニティ
        if myCommunity != nil{
            return 1
        }else{
            return inviteSelectUser.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if myCommunity != nil{
            let cell = tableView.dequeueReusableCell(withIdentifier: "communityCreate", for: indexPath) as! communityCreateCell
            cell.communityNameLabel.text = myCommunity.communityName
            if let icon = myCommunity.communityIcon{
                let storageRef = icon
                if let photoURL = URL(string: storageRef){
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        cell.communityIcon.image = image
                    }
                    catch{
                        print("error")
                        //return
                    }
                }
            }
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
            cell.userNameLabel.text = inviteSelectUser[indexPath.row].userName
            if let icon = inviteSelectUser[indexPath.row].userIcon{
                let storageRef = icon
                if let photoURL = URL(string: storageRef){
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        cell.profileImageView.image = image
                    }
                    catch{
                        print("error")
                        //return
                    }
                }
            }else{
                //let storageRef = self.storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child("profileImage").child("\(self.inviteSelectUser[indexPath.row].userID!).jpg")
                let storageRef = self.storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child(self.inviteSelectUser[indexPath.row].userID).child("icon.jpg")
                
                //キャッシュを消している
                SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                cell.profileImageView.sd_setImage(with: storageRef)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //今回(2021/0812)は95に設定
        return 95
    }
}

extension newRoomViewController2: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
