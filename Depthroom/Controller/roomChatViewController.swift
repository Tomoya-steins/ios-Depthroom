import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseStorageUI

class roomChatViewController: MessagesViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var room: Room!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    var meName = "initial"
    var me: AppUser!
    //自身がルームのメンバーかどうかに使う
    //ユーザIDのみ格納
    var roomMemberArray: [String] = []
    //チャットのために必要
    var roomMemberArrayToChat: [AppUser] = []
    //同じく必要
    var userName = "testName"
    var meInfo: [String:Any] = [:]
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    
    var messageList: [MockMessage] = []{
        didSet{
            // messagesCollectionViewをリロード
            self.messagesCollectionView.reloadData()
            // 一番下までスクロールする
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    //ナビゲーションバーのアイテムの宣言(クリップボタン, 設定ボタン)
    var clipBarButtonItem: UIBarButtonItem!
    var settingBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "roomChat"
        
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        
        //インディケータを動かす
        if indicator.isAnimating == false{
            showIndicator()
        }
        //ルームの情報をroomに格納
        //オープンルームにて自身がチャットを送った際に、ルームのメンバーに登録される仕組みに使う
        //非同期対応
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        dispatchQueue.async(group: dispatchGroup) {
            self.database.collection("rooms").document(self.room.roomID).addSnapshotListener { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    self.room = Room(data: data)
                    if let members = data["members"] as? [String:Any]{
                        self.roomMemberArray = []
                        self.roomMemberArrayToChat = []
                        for member in members.values{
                            let memberInfo = AppUser(data: member as! [String:Any])
                            self.roomMemberArray.append(memberInfo.userID)
                            //idから名前を割り出すために使う
                            self.roomMemberArrayToChat.append(memberInfo)
                            
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main){
            self.fireStoreDocumentChange()
        }
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        //画面下の細々とした設定
        setupInput()
        setupButton()
        setupCameraButton()
        setupBottomItem()
        // 背景の色を指定
        messagesCollectionView.backgroundColor = .white
        
        // メッセージ入力時に一番下までスクロール
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        //クリップボタンの初期化・配置
        clipBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(clipBarButtonTapped(_:)))
        //ルームの設定ボタンの初期化・配置
        settingBarButtonItem = UIBarButtonItem(title: "設定", style: .done, target: self, action: #selector(settingBarButtonTapped(_:)))
        //クローズなルームにはクリップボタンはいらない
        if room.state == "open"{
            //ナビゲーションバーアイテムの配置
            self.navigationItem.rightBarButtonItems = [settingBarButtonItem, clipBarButtonItem]
        }else{
            self.navigationItem.rightBarButtonItems = [settingBarButtonItem]
        }
        //インディケータが動いていたら、止める
        DispatchQueue.main.async {
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
    
    func showIndicator(){
        backView.frame = self.view.frame
        //indicate中は他の操作を受け付けさせないために必要
        backView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.0)
        indicator.center = view.center
        indicator.style = .large
        indicator.color = UIColor(red: 44/255, green: 169/255, blue: 225/255, alpha: 1)
        backView.addSubview(indicator)
        view.addSubview(backView)
        indicator.startAnimating()
    }
    func hideIndicator(){
        indicator.stopAnimating()
        backView.removeFromSuperview()
    }
    
    //クリップボタンをタップした時の処理
    @objc func clipBarButtonTapped(_ sender: UIBarButtonItem){
        //追加
        if clipBarButtonItem.isEnabled == true{
            //usersにルームの情報を保存(myRoomsで表示するため)
            let owner = AppUser(data: room.owner)
            let me = database.collection("users").document(me.userID)
            me.updateData([
                "clips.\(room.roomID!)": [
                    "roomID": room.roomID!,
                    "owner": [
                        "userID": owner.userID,
                        "userName": owner.userName,
                        "userIcon": owner.userIcon
                    ],
                    "roomName": room.roomName!,
                    "createdAt": room.createdAt!,
                    "updatedAt": room.updatedAt!,
                ]
            ])
            clipBarButtonItem.isEnabled = false
        }else if clipBarButtonItem.isEnabled == false{
            //削除
            //ここは機能していない(2021/11/27)
            database.collection("users").document(me.userID).updateData([
                "clips.\(room.roomID!)": FieldValue.delete()
            ])
            clipBarButtonItem.isEnabled = true
        }
    }
    
    //設定ボタンをタップした時の処理
    @objc func settingBarButtonTapped(_ sender: UIBarButtonItem){
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChatSetting") as! roomChatSettingViewController
        nextViewController.room = room
        nextViewController.me = me
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //今回はナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        database.collection("users").document(auth.currentUser!.uid).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.me = AppUser(data: data)
                //初期値が入ったmeNameに代入することでnilを回避
                //func current_user で使っている
                self.meName = self.me.userName
                //このルームを既にクリップしているかどうか
                if let clips = self.me.clips{
                    for clip in clips.values{
                        let clipRoom = Room(data: clip as! [String:Any])
                        if clipRoom.roomID == self.room.roomID{
                            self.clipBarButtonItem.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func fireStoreDocumentChange(){
        //チャット内容をFireStoreから取得・ドキュメントに変更が生じた際、messageListにドキュメントを追加する
        database.collection("rooms").document(room.roomID).collection("messages").order(by: "timeStamp", descending: false).addSnapshotListener { (snapShot, error) in
            guard snapShot != nil else {
                print("snapShot is nil")
                return
            }
            snapShot!.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("New city: \(diff.document.data())")
                    let snapshotValue = diff.document.data()
                    let text = snapshotValue["body"] as! String
                    let id = snapshotValue["from"] as! String
                   
                    //idからnameを割り出す
                    for user in self.roomMemberArrayToChat{
                        if user.userID == id{
                            self.userName = user.userName
                        }
                    }
                    let name = self.userName
                    
                    //let name = snapshotValue["senderName"] as! String
                    //fireStoreのFieldValueからdateに変換
                    //let createTime = snapshotValue["timeStamp"] as! Timestamp
                    //let date = createTime.dateValue()
                    let createTime = snapshotValue["timeStamp"] as! Timestamp
                    let date = createTime.dateValue()
                    let type = snapshotValue["type"] as! String
                    //文字なら
                    if type == "text"{
                        self.messageList.append(self.createMessage(text: text, id: id, name: name, date: date))
                    }else if type == "image"{
                        self.messageList.append(self.createImageMessage(url: text, id: id, name: name, date: date))
                    }
                }
                if (diff.type == .modified) {
                    print("Modified city: \(diff.document.data())")
                }
                if (diff.type == .removed) {
                    print("Removed city: \(diff.document.data())")
                }
            }
        }
    }
    
    func setupInput(){
        // プレースホルダーの指定
        messageInputBar.inputTextView.placeholder = "入力"
        // 入力欄のカーソルの色を指定
        //messageInputBar.inputTextView.tintColor = .red
        // 入力欄の色を指定
        //messageInputBar.inputTextView.backgroundColor = .white
        //テキストを打ち込むバーの設定
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = .purple
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    private func setupButton(){
        // ボタンの変更
        messageInputBar.sendButton.title = "送信"
        // 送信ボタンの色を指定
        messageInputBar.sendButton.tintColor = .lightGray
    }
    
    //今何文字かを確認するUI
    private func setupBottomItem(){
        let charCountButton = InputBarButtonItem()
            .configure{
                $0.title = "0/140"
                $0.contentHorizontalAlignment = .right
                $0.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
                $0.setSize(CGSize(width: 50, height: 25), animated: false)
            }.onTextViewDidChange{ (item, textView) in
                item.title = "\(textView.text.count)/140"
                let isOverLimit = textView.text.count > 140
                item.inputBarAccessoryView?.shouldManageSendButtonEnabledState = !isOverLimit
                if isOverLimit {
                    item.inputBarAccessoryView?.sendButton.isEnabled = false
                }
                let color = isOverLimit ? .red : UIColor(white: 0.6, alpha: 1)
                item.setTitleColor(color, for: .normal)
            }
        let bottomItems = [.flexibleSpace, charCountButton]
        
        messageInputBar.setStackViewItems(bottomItems, forStack: .bottom, animated: false)
    }
    
    private func setupCameraButton(){
        let items = [
            makeButton(named: "right").onTextViewDidChange{ button, textView in
                button.tintColor = UIColor.lightGray
                button.isEnabled = textView.text.isEmpty
            }
        ]
        items.forEach{ $0.tintColor = .lightGray }
        messageInputBar.setStackViewItems(items, forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 35, animated: false)
        
    }
    
    func makeButton(named: String) -> InputBarButtonItem{
        return InputBarButtonItem()
            .configure{
                $0.spacing = .fixed(10)
                if #available(iOS 13.0, *) {
                    $0.image = UIImage(systemName: "camera.fill")?.withRenderingMode(.alwaysTemplate)
                } else {
                    $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                }
                $0.setSize(CGSize(width: 30, height: 30), animated: true)
            }.onSelected{
                $0.tintColor = UIColor.green
            }.onDeselected{
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside{ _ in
                print("item Tapped!")
                //画像選択
                self.showAlert()
            }
    }

    func createMessage(text: String, id: String, name: String, date: Date) -> MockMessage {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white]
        )
        return MockMessage(attributedText: attributedText, sender: otherSender(senderID: id, displayName: name) as! MockUser, messageId: UUID().uuidString, date: date)
    }
    
    //image用
    func createImageMessage(url: String, id: String, name: String, date: Date) -> MockMessage{
        let photoURL = URL(string: url)!
        
        //urlからimageに変換
        do{
            let data = try Data(contentsOf: photoURL)
            let image = UIImage(data: data)!
            return MockMessage(image: image, sender: otherSender(senderID: id, displayName: name) as! MockUser, messageId: UUID().uuidString, date: date)
        }
        catch{
            print("error")
        }
        return MockMessage(image: UIImage(named: "home")!, sender: otherSender(senderID: id, displayName: name) as! MockUser, messageId: UUID().uuidString, date: date)
    }
    
    //MARK: - Select Image(ここで画像を選択保存の処理を行う)
    func doCamera(){
        
        let sourceType:UIImagePickerController.SourceType = .camera
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.allowsEditing = true
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func doAlbum(){
        
        let sourceType:UIImagePickerController.SourceType = .photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let cameraPicker = UIImagePickerController()
            cameraPicker.allowsEditing = true
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if info[.originalImage] as? UIImage != nil{
            //indicator回す
            if indicator.isAnimating == false{
                showIndicator()
            }
            let selectedImage = info[.originalImage] as! UIImage
            
            //非同期対応
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
            dispatchQueue.async(group: dispatchGroup) {
                
                //ルームのメンバーの一員ではない状態で、チャットを送った場合、ルームのメンバーに追加する
                let updateRoom = self.database.collection("rooms").document(self.room.roomID)
                if  self.roomMemberArray.firstIndex(of: self.me.userID) == nil{
                    self.meInfo["\(self.me.userID!)"] = [
                        "userID": self.me.userID,
                        "userName": self.me.userName,
                        //"userDescription": me.userDescription,
                        "userIcon": self.me.userIcon
                    ]
                    updateRoom.setData([
                        "members": self.meInfo
                    ], merge: true)
                }
                
                //ここで画像をfireStoreに保存&&messageList配列に入れる
                let saveImageMessage = self.database.collection("rooms").document(self.room.roomID).collection("messages").document()
                let profileImage = selectedImage.jpegData(compressionQuality: 0.1)
                let storageRef = Storage.storage().reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("rooms").child(self.room.roomID).child("\(saveImageMessage.documentID).jpg")
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpg"
                
                storageRef.putData(profileImage!, metadata: metaData) { (metaData, error) in
                    
                    if error != nil {
                        print("error: \(error!.localizedDescription)")
                        return
                    }
                    storageRef.downloadURL(completion: { (url, error) in
                        
                        if error != nil{
                            print("error: \(error!.localizedDescription)")
                            return
                        }
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        
                        if let photoURL = URL(string: url!.absoluteString){
                            changeRequest?.photoURL = photoURL
                            //fireStoreのbodyにurlとして保存
                            saveImageMessage.setData([
                                "from": self.currentSender().senderId,
                                //"senderName": currentSender().displayName,
                                "body": url!.absoluteString,
                                "messageID": saveImageMessage.documentID,
                                //"timeStamp": FieldValue.serverTimestamp()
                                "timeStamp": NSDate(),
                                "type": "image"
                            ],merge: true)
                            
                            //ルームの情報を更新
                            updateRoom.setData([
                                "updatedAt": FieldValue.serverTimestamp(),
                                "recentMessage": [
                                    "from": self.currentSender().senderId,
                                    "body": "画像が送信されました。",
                                    "messageID": saveImageMessage.documentID,
                                    "timeStamp": NSDate(),
                                    "type": "image"
                                ]
                            ], merge: true)
                            
                            
                        }
                        //ここちょっと自信がないです
                        changeRequest?.commitChanges(completion: nil)
                        
                    })
                }
            }
            
            dispatchGroup.notify(queue: .main){
                if self.indicator.isAnimating == true{
                    self.hideIndicator()
                }
                picker.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //アラート
    func showAlert(){
        let alertController = UIAlertController(title: "選択", message: "どちらを使用しますか?", preferredStyle: .actionSheet)
        let action1 = UIAlertAction(title: "カメラ", style: .default) { (alert) in
            self.doCamera()
        }
        let action2 = UIAlertAction(title: "アルバム", style: .default) { (alert) in
            self.doAlbum()
        }
        let action3 = UIAlertAction(title: "キャンセル", style: .cancel)
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Helpers

    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }

    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section - 1].user
    }

    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messageList.count else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section + 1].user
    }
    
}

// MARK: - MessagesDataSource
extension roomChatViewController: MessagesDataSource {
    
    //自分を認識
    func currentSender() -> SenderType {
        //idは既に持っているためmeNameのみ
        return MockUser(senderId: Auth.auth().currentUser!.uid, displayName: meName)
    }

    //相手を認識改自分も認識している説
    func otherSender(senderID: String, displayName: String) -> SenderType {
        return MockUser(senderId: senderID, displayName: displayName)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    // メッセージの上に文字を表示
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
            )
        }
        return nil
    }
    
    // メッセージの上に文字を表示（名前）
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下に文字を表示（日付）
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// MARK: - MessagesDisplayDelegate
extension roomChatViewController: MessagesDisplayDelegate {
    
    // メッセージの色を変更
    func textColor(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        isFromCurrentSender(message: message) ? .white : .darkGray
    }
    
    // メッセージの背景色を変更している
    func backgroundColor(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        isFromCurrentSender(message: message) ? .darkGray : .cyan
    }
    
    // メッセージの枠にしっぽを付ける
    func messageStyle(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコンをセット
    func configureAvatarView(
        _ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) {
        
        //冗長ではあるが、クロージャの関係上メソッド化しづらい
        //今後改良の余地あり
        if message.sender.senderId == auth.currentUser?.uid{
            let storageRef = userProfileImageStorageRef(userID: auth.currentUser!.uid)
            SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
            //urlを取ってくる
            storageRef.downloadURL(completion: {(url, error) in
                if error != nil{
                    print("error: \(error!.localizedDescription)")
                    return
                }
                //URL型に代入
                if let photoURL = URL(string: url!.absoluteString){
                    //data型→image型に代入して、returnを返す
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        avatarView.set( avatar: Avatar(image: image) )
                    }
                    catch{
                        print("error")
                        return
                    }
                    
                }
            })
        }
        else{
            let storageRef = userProfileImageStorageRef(userID: message.sender.senderId)
            SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
            //urlを取ってくる
            storageRef.downloadURL(completion: {(url, error) in
                if error != nil{
                    print("error: \(error!.localizedDescription)")
                    return
                }
                //URL型に代入
                if let photoURL = URL(string: url!.absoluteString){
                    //data型→image型に代入して、returnを返す
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        avatarView.set( avatar: Avatar(image: image) )
                    }
                    catch{
                        print("error")
                        return
                    }
                    
                }
            })
        }
    }
    
    //ここでfireStoreからパスを得る
    func userProfileImageStorageRef(userID: String) -> StorageReference{
        //let storageRef = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child("profileImage").child("\(userID).jpg")
        let storageRef = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child(userID).child("icon.jpg")
        return storageRef
    }
    
    //画像を表示する設定?
    //2021/11/07時点では必要ないと判断したため、コメントアウトしている
//    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
//        switch message.kind{
//        case .photo(let photoItem):
//            //urlを持っていなければ、それはただのテキスト
//            guard let url = photoItem.url else { return }
//            imageView.contentMode = .scaleAspectFit
//            //読み込むまでの画像を表示
//            do{
//                let data = try Data(contentsOf: url)
//                let image = UIImage(data: data)
//                imageView.image = image
//            }
//            catch{
//                print("error")
//                return
//            }
//        default:
//            break
//        }
//    }
}


// 各ラベルの高さを設定（デフォルト0なので必須）
// MARK: - MessagesLayoutDelegate
extension roomChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        indexPath.section % 3 == 0 ? 10 : 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        16
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        16
    }
}

// MARK: - MessageCellDelegate
extension roomChatViewController: MessageCellDelegate {
    
    //MARK: - Cellのバックグラウンドをタップした時の処理
    func didTapBackground(in cell: MessageCollectionViewCell) {
        print("バックグラウンドタップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージをタップした時の処理
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("メッセージタップ")
        closeKeyboard()
    }
    
    //MARK: - アバターをタップした時の処理
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("アバタータップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージ上部をタップした時の処理
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ上部タップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージ下部をタップした時の処理
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ下部タップ")
        closeKeyboard()
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension roomChatViewController: InputBarAccessoryViewDelegate {
    // 送信ボタンをタップした時の挙動
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //let attributedText = NSAttributedString(
            //string: text, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
        //let message = MockMessage(attributedText: attributedText, sender: currentSender(), messageId: UUID().uuidString, date: Date())
        //self.messageList.append(message)
        //インディケータを回す
        if indicator.isAnimating == false{
            showIndicator()
        }
        self.messageInputBar.inputTextView.text = String()
        self.messageInputBar.invalidatePlugins()
        self.messagesCollectionView.scrollToLastItem()
        
        //ルームのメンバーの一員ではない状態で、チャットを送った場合、ルームのメンバーに追加する
        let updateRoom = database.collection("rooms").document(room.roomID)
        if  roomMemberArray.firstIndex(of: me.userID) == nil{
            meInfo["\(me.userID!)"] = [
                "userID": me.userID,
                "userName": me.userName,
                //"userDescription": me.userDescription,
                "userIcon": me.userIcon
            ]
            updateRoom.setData([
                "members": meInfo
            ], merge: true)
        }
        
        //送信したデータをFireStoreに保存
        let saveMessage = database.collection("rooms").document(room.roomID).collection("messages").document()
        
        saveMessage.setData([
            "from": currentSender().senderId,
            //"senderName": currentSender().displayName,
            "body": text,
            "messageID": saveMessage.documentID,
            //"timeStamp": FieldValue.serverTimestamp()
            "timeStamp": NSDate(),
            "type": "text"
        ])
        
        //送信したメッセージの日時を部屋のupdateAtに対して適用
        //最新のメッセージを登録
        //部屋の消滅機能に関わる←廃止になった
        updateRoom.setData([
            "updatedAt": FieldValue.serverTimestamp(),
            "recentMessage": [
                "from": currentSender().senderId,
                "body": text,
                "messageID": saveMessage.documentID,
                "timeStamp": NSDate(),
                "type": "text"
            ]
        ], merge: true)
        
        DispatchQueue.main.async{
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
}

extension roomChatViewController {
    func closeKeyboard(){
        self.messageInputBar.inputTextView.resignFirstResponder()
        self.messagesCollectionView.scrollToLastItem()
    }
}

