//
//  hashTagRoomsViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/27.
//

import UIKit
import Firebase
import FirebaseStorageUI

class hashTagRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var gettag: String!
    var tag: Tag!
    var roomArray: [Room] = []
    var database: Firestore!
    var storage: Storage!
    var recentMessage = "noTextData"
    var tagsArray: [String] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tagLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "roomCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tagLabel.text = gettag
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        dispatchQueue.async(group: dispatchGroup) {
            dispatchGroup.enter()
            self.database.collection("tags").whereField("tagName", isEqualTo: self.gettag!).addSnapshotListener{ (snapshot, error) in
                if error == nil, let snapshot = snapshot{
                    for document in snapshot.documents{
                        let data = document.data()
                        let tag = Tag(data: data)
                        self.tag = tag
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main){
            //ルームの情報を取得
            self.roomInfo()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.tableView.reloadData()
        super.viewWillAppear(animated)
        tagsArray = []
    }
    
    func roomInfo(){
        roomArray = []
        database.collection("rooms").whereField("tags.\(tag.tagID!).tagID", isEqualTo: tag.tagID!).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documentChanges.forEach{ diff in
                    if (diff.type == .added){
                        let data = diff.document.data()
                        let room = Room(data: data)
                        self.roomArray.append(room)
                    }
                    if (diff.type == .modified){
                        print("Modified city: \(diff.document.data())")
                    }
                    if (diff.type == .removed){
                        print("Removed city: \(diff.document.data())")
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //segueを使っていないため、コードで繋ぐ
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
        nextViewController.room = roomArray[indexPath.row]
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCell
        cell.roomNameLabel.text = roomArray[indexPath.row].roomName
        //roomのメッセージを受け取る
//        database.collection("rooms").document(roomArray[indexPath.row].roomID).collection("messages").order(by: "timeStamp", descending: true).limit(to: 1).getDocuments { (snapshot, error) in
//            guard snapshot != nil else{
//                print("snapshot is nil")
//                return
//            }
//            if error == nil, let snapshot = snapshot{
//                for document in snapshot.documents{
//                    let data = document.data()
//                    let message = GroupChat(data: data)
//                    cell.messageLabel.text = message.context
//                }
//            }
//        }
        
//        if roomArray[indexPath.row].recentMessage != nil{
//            let recentMessage = GroupChat(data: roomArray[indexPath.row].recentMessage)
//            cell.messageLabel.text = recentMessage.body
//        }else{
//            cell.messageLabel.text = recentMessage
//        }
        
        //更新時間
        let time = roomArray[indexPath.row].updatedAt.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
        
        //タグ
        if let tags = roomArray[indexPath.row].tags{
            for data in tags.values{
                let tag = Tag(data: data as! [String : Any])
                self.tagsArray.append(tag.tagName)
            }
        }
        
        //取得したタグを結合
        let tagsString = tagsArray.joined(separator: "")
        let tagText = cell.tagLabel!
        tagText.text = tagsString
        
        tagText.handleHashtagTap{ hashTag in
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "hashTagRooms") as! hashTagRoomsViewController
            nextViewController.gettag = "#\(hashTag)" as String
            self.navigationController?.pushViewController(nextViewController, animated: true)
        }
        
        
        
//        if let icon = roomArray[indexPath.row].icon{
//            let storageRef = icon
//            //URL型に代入
//            if let photoURL = URL(string: storageRef){
//                do{
//                    //data→image型に代入
//                    let data = try Data(contentsOf: photoURL)
//                    let image = UIImage(data: data)
//                    cell.roomThumbnailImageView.image = image
//                }
//                catch{
//                    print("error")
//                }
//            }
//        }else{
//            let storageRefRoom = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("rooms").child("roomThumbnail").child("\(roomArray[indexPath.row].roomID!).jpg")
//            
//            SDImageCache.shared.removeImage(forKey: "\(storageRefRoom)", withCompletion: nil)
//            cell.roomThumbnailImageView.sd_setImage(with: storageRefRoom)
//        }
        //ルームのオーナーの画像を取得・表示
        let owner = AppUser(data: roomArray[indexPath.row].owner)
        let storageRefOwner = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child(owner.userID).child("icon.jpg")
        SDImageCache.shared.removeImage(forKey: "\(storageRefOwner)", withCompletion: nil)
        cell.roomOwnerImageView.sd_setImage(with: storageRefOwner)

        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
}
