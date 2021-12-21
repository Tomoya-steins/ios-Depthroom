//
//  roomModalViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/24.
//

import UIKit
import Firebase
import FirebaseStorageUI

class roomModalViewController: UIViewController {

    var meID: String!
    var meName: String!
    var meIcon: String!
    var meDescriotion: String!
    var roomID: String!
    var database: Firestore!
    var storage: Storage!
    //ルームのメンバーに関する情報を配列に格納
    var roomMember: [[String:Any]] = []
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        roomInfoFromFirebase()
    }
    
    func roomInfoFromFirebase(){
        //ルームの名前を取得する
        //ルームのメンバー情報を取得する→参加ボタンを押した際に使う
        database.collection("rooms").document(roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                let roomData = Room(data: data)
                self.roomNameLabel.text = roomData.roomName
                
                //members情報を取得2021/08/26解決
                //しんどかったー
//                if let mapData = data["members"] as? [String:Any]{
//
//                    self.roomMember = []
//                    self.roomMember.append(mapData)
//                }
                
                //アイコンの情報を渡して画像を表示
//                if let icon = roomData.icon{
//                    let storageRef = icon
//                    //URL型に代入
//                    if let photoURL = URL(string: storageRef){
//                        //data型→image型に代入
//                        do{
//                            let data = try Data(contentsOf: photoURL)
//                            let image = UIImage(data: data)
//                            self.imageView.image = image
//                        }
//                        catch{
//                            print("error")
//                            return
//                        }
//                    }
//                }else{
//                    //ルームのサムネイルを取得する
//                    let storageRef = self.storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("rooms").child("roomThumbnail").child("\(self.roomID!).jpg")
//
//                    SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
//                    self.imageView.sd_setImage(with: storageRef)
//                }
            }
        }
    }
    
    @IBAction func buttonToJoin(_ sender: Any) {
        
        //rooms内のinvitationから自身の名前を消去して、membersに名前を追加、チャット画面に遷移する
        let roomRef = database.collection("rooms").document(roomID)
        let meInfo = [
            "userID": meID,
            "userName": meName,
            "userIcon": meIcon,
            "userDescription": meDescriotion
        ]
        roomRef.updateData([
            "invitations.\(meID!)": FieldValue.delete(),
            "members.\(meID!)": meInfo
        ])
        
        //チャット画面に遷移
        let roomChatViewController = storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
        roomChatViewController.room = Room(data: ["roomID": roomID!])
        present(roomChatViewController, animated: true, completion: nil)
    }
    
    @IBAction func buttonToReject(_ sender: Any) {
        //invitationから自身の名前を消去して、画面をルーム一覧へ遷移
        database.collection("rooms").document(roomID).updateData([
            "invitations.\(meID!)": FieldValue.delete()
        ])
        dismiss(animated: true, completion: nil)
    }
    
}
