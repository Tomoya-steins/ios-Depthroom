//
//  communityShowViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/12.
//

import UIKit
import Firebase
import FirebaseStorageUI
import ActiveLabel

class communityShowViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    //communityID ownerIDの情報が入っている
    var community: Community!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    //ルーム
    var communityRoomArray: [Room] = []
    var communityRoomDocumentArray: [QueryDocumentSnapshot] = []
    var communityRoomQuery: Query!
    var communityRoomDocumentCount = 0
    //ユーザ
    var communityMemberArray: [AppUser] = []
    
    var settingBarButtonItem: UIBarButtonItem!
    var tagsArray: [String] = []
    var currentMembersCount: Int!
    //ルーム作成ボタン
    let createRoomButton = UIButton()
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    
    @IBOutlet weak var communityNameLabel: UILabel!
    @IBOutlet weak var communityImageView: UIImageView!
    @IBOutlet weak var communityDescriptionLabel: UILabel!
    @IBOutlet weak var buttonToJoinCommunity: UIButton!
    @IBOutlet weak var selectSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var communityHeaderImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //今回はナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        
        //初期化
        communityRoomArray = []
        communityRoomQuery = database.collection("rooms").whereField("community.communityID", isEqualTo: community.communityID!).limit(to: 10)
        
        //ルーム作成ボタン
        createRoomButton.frame = CGRect(x: 5*view.frame.width/7, y: 7*view.frame.height/9, width: view.frame.height/10, height: view.frame.height/10)
        createRoomButton.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        createRoomButton.imageView?.contentMode = .scaleAspectFit
        createRoomButton.contentHorizontalAlignment = .fill
        createRoomButton.contentVerticalAlignment = .fill
        createRoomButton.addTarget(self, action: #selector(self.buttonToCreateRoom), for: .touchUpInside)
        view.addSubview(createRoomButton)
        
        //カスタムしたセルを登録(roomCell)
        tableView.register(UINib(nibName: "roomCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "userNameAndIconCell", bundle: nil), forCellReuseIdentifier: "userNameAndIcon")
        
        //コミュニティのオーナではなかったら、編集への遷移を防ぐ
        //自身がコミュニティのオーナーならば、参加ボタンはいらない
        let owner = AppUser(data: community.owner)
        if auth.currentUser?.uid == owner.userID{
            buttonToJoinCommunity.isHidden = true
        }
        buttonToJoinCommunity.setTitle("コミュニティに参加する", for: UIControl.State.normal)
        buttonToJoinCommunity.setTitleColor(.black, for: .normal)
        buttonToJoinCommunity.layer.cornerRadius = 10
        buttonToJoinCommunity.layer.borderWidth = 0.1
        buttonToJoinCommunity.layer.borderColor = UIColor.black.cgColor
        buttonToJoinCommunity.backgroundColor = UIColor.green
        //コミュニティに参加しているときはselectedはtrueです
        buttonToJoinCommunity.isSelected = false
        
        
        //アイコン画像を丸く
        communityImageView.layer.borderWidth = 1
        communityImageView.layer.cornerRadius = communityImageView.frame.height/2
        communityImageView.layer.masksToBounds = true
        
        //設定をナビゲーションバーに表示
        settingBarButtonItem = UIBarButtonItem(title: "設定", style: .done, target: self, action: #selector(settingBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItems = [settingBarButtonItem]
        //インディケータを動かす
        if indicator.isAnimating == false{
            showIndicator()
        }
        //コミュニティの情報
        communityInfo()
        //コミュニティの持っているルームの情報を載せる
        roomInfo()
        //インディケータが動いていたら、止める
        DispatchQueue.main.async {
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    private func showIndicator(){
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
    private func hideIndicator(){
        indicator.stopAnimating()
        backView.removeFromSuperview()
    }
    
    func communityInfo(){
        //コミュニティ情報を取得
        database.collection("communities").document(community.communityID).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.community = Community(data: data)
                //配列を初期化
                //self.communityRoomArray = []
                self.communityMemberArray = []
                //名前・画像・紹介文を表示
                //メンバーや部屋を配列に格納
                self.communityNameLabel.text = self.community.communityName
                self.communityDescriptionLabel.text = self.community.communityDescription
                if let icon = self.community.communityIcon{
                    let storageRef = icon
                    if let photoURL = URL(string: storageRef){
                        do{
                            let data = try Data(contentsOf: photoURL)
                            let image = UIImage(data: data)
                            self.communityImageView.image = image
                        }
                        catch{
                            print("error")
                            return
                        }
                    }
                }
                //ヘッダーに画像を入れる
                //なければテーマカラーが入る
                if let header = self.community.communityHeader{
                    let storageRef = header
                    if let photoURL = URL(string: storageRef){
                        do{
                            let data = try Data(contentsOf: photoURL)
                            let image = UIImage(data: data)
                            self.communityHeaderImageView.image = image
                        }
                        catch{
                            print("error")
                            return
                        }
                    }
                }else{
                    let color: UIColor = UIColor(hex: self.community.communityColor)!
                    self.communityHeaderImageView.backgroundColor = color
                }
                //コミュニティのメンバーやルームをそれぞれの配列に格納
                if let member = data["members"] as? [String:Any]{
                    for member in member.values{
                        //表示するメンバー数を30人に制限
                        if self.communityMemberArray.count <= 30{
                            let userInfo = AppUser(data: member as! [String:Any])
                            //メンバー情報を入れる
                            //この配列はcellForRowAtで直接使用しない
                            self.communityMemberArray.append(userInfo)
                            //コミュニティ所属しているかそうでないかを判別
                            //判別結果はコミュニティ参加ボタンに反映される
                            if self.me.userID == userInfo.userID{
                                self.buttonToJoinCommunity.setTitle("コミュニティを抜ける", for: UIControl.State.normal)
                                self.buttonToJoinCommunity.setTitleColor(.white, for: .normal)
                                self.buttonToJoinCommunity.layer.cornerRadius = 10
                                self.buttonToJoinCommunity.layer.borderWidth = 0.1
                                self.buttonToJoinCommunity.layer.borderColor = UIColor.black.cgColor
                                self.buttonToJoinCommunity.backgroundColor = UIColor.link
                                //コミュニティに参加しているときはselectedはtrueです
                                self.buttonToJoinCommunity.isSelected = true
                            }
                        }
                    }
                }
                self.tableView.reloadData()
            }
            let communityColor: UIColor = UIColor(hex: self.community.communityColor)!
            self.communityImageView.layer.borderColor = communityColor.cgColor
            //ルーム作成ボタンの色変更
            self.createRoomButton.tintColor = communityColor
            //今週のコミュニティの参加者を変数に入れる
            self.currentMembersCount = self.community.weeklyMembersCount
        }
    }
    
    func roomInfo(){
        communityRoomQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let room = Room(data: data)
                    self.communityRoomArray.append(room)
                    self.communityRoomDocumentArray.append(document)
                })
                self.tableView.reloadData()
            }
        }
    }
    //paginateして更新
    func communituyRoomPaginate(){
        communityRoomQuery = communityRoomQuery.start(afterDocument: communityRoomDocumentArray.last!)
        roomInfo()
    }
    
    @objc func buttonToCreateRoom(_sender: Any){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let nextViewController = storyboard.instantiateViewController(identifier: "newRoom2") as? newRoomViewController2 else {
            return
        }
        nextViewController.modalPresentationStyle = .fullScreen
        nextViewController.me = me
        //nextViewController.reserve = ""
        nextViewController.state = "open"
        nextViewController.myCommunity = community
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @objc func settingBarButtonTapped(_ sender: UIBarButtonItem){
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "communitySetting") as! communitySettingViewController
        nextViewController.community = community
        nextViewController.me = me
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    @IBAction func buttonToJoinCommunity(_ sender: Any) {
        //参加している状態でボタンを押した時
        if buttonToJoinCommunity.isSelected == true{
            //退会処理
            //確認のためにアラートも
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            
            let confirmGetout = UIAlertController(title: "確認", message: "このコミュニティから抜けますか?", preferredStyle: .alert)
            confirmGetout.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            confirmGetout.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                dispatchQueue.async(group: dispatchGroup) {
                    dispatchGroup.enter()
                    //コミュニティのメンバーから自身を削除
                    self.database.collection("communities").document(self.community.communityID).updateData([
                        "members.\(self.me.userID!)": FieldValue.delete()
                    ])
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main){
                    self.dismiss(animated: true, completion: nil)
                    self.buttonToJoinCommunity.isSelected = false
                    self.buttonToJoinCommunity.setTitle("コミュニティに参加する", for: UIControl.State.normal)
                    self.buttonToJoinCommunity.setTitleColor(.black, for: .normal)
                    self.buttonToJoinCommunity.layer.cornerRadius = 10
                    self.buttonToJoinCommunity.layer.borderWidth = 0.1
                    self.buttonToJoinCommunity.layer.borderColor = UIColor.black.cgColor
                    self.buttonToJoinCommunity.backgroundColor = UIColor.green
                    
                }
            }))
            self.present(confirmGetout, animated: true, completion: nil)
        }
        //参加していない状態でボタンを押した時
        else if buttonToJoinCommunity.isSelected == false{
            //参加処理
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            dispatchQueue.async(group: dispatchGroup) {
                dispatchGroup.enter()
                //今週のコミュニティ参加者のカウントに1追加する
                self.currentMembersCount += 1
                let userInfo = [
                    "userID": self.me.userID,
                    "userName": self.me.userName,
                    "userDescription": self.me.userDescription,
                    "userIcon": self.me.userIcon
                ]
                self.database.collection("communities").document(self.community.communityID).updateData([
                    "members.\(self.me.userID!)": userInfo,
                    "weeklyMembersCount": self.currentMembersCount!
                ])
                dispatchGroup.leave()
            }
            dispatchGroup.notify(queue: .main){
                self.buttonToJoinCommunity.isSelected = true
                self.buttonToJoinCommunity.setTitle("コミュニティを抜ける", for: UIControl.State.normal)
                self.buttonToJoinCommunity.setTitleColor(.white, for: .normal)
                self.buttonToJoinCommunity.layer.cornerRadius = 10
                self.buttonToJoinCommunity.layer.borderWidth = 0.1
                self.buttonToJoinCommunity.layer.borderColor = UIColor.black.cgColor
                self.buttonToJoinCommunity.backgroundColor = UIColor.link
            }
        }
    }
    
    
    
    @IBAction func tappedSegmentControl(_ sender: Any) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //タブの切り替え
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        case 0:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
            nextViewController.room = communityRoomArray[indexPath.row]
            nextViewController.me = me
            self.navigationController?.pushViewController(nextViewController, animated: true)
        case 1:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
            nextViewController.user = communityMemberArray[indexPath.row]
            nextViewController.me = me
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //タブの切り替え
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            return communityRoomArray.count
        case 1:
            return communityMemberArray.count
        default:
            return 1000
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell")!
        switch segmentIndex{
        //ルームについて
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCell
            //ルームの名前
            cell.roomNameLabel.text = communityRoomArray[indexPath.row].roomName
            //ルームの最新メッセージ
//            if communityRoomArray[indexPath.row].recentMessage != nil{
//                let recentMessage = GroupChat(data: communityRoomArray[indexPath.row].recentMessage)
//                cell.messageLabel.text = recentMessage.body
//            }else{
//                cell.messageLabel.text = ""
//            }
            //更新時間
            if communityRoomArray[indexPath.row].updatedAt != nil{
                let time = communityRoomArray[indexPath.row].updatedAt.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
            }
            //タグ
            if let tags = communityRoomArray[indexPath.row].tags{
                //ここで配列を初期化
                tagsArray = []
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
            
            //ルームのオーナーの画像を取得・表示
            let owner = AppUser(data: communityRoomArray[indexPath.row].owner)
            if let photoURL = URL(string: owner.userIcon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.roomOwnerImageView.image = image
                }
                catch{
                    print("error")
                }
            }
            return cell
            
        //メンバーについて
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon", for: indexPath) as! userNameAndIconCell
            cell.userNameLabel.text = communityMemberArray[indexPath.row].userName
            //メンバーのアイコンを取得・表示
            if let photoURL = URL(string: communityMemberArray[indexPath.row].userIcon){
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
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/7
    }
    
    //スクロールが画面一番下に来たときに検知する
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y: Float = Float(offset.y) + Float(bounds.size.height) + Float(inset.bottom)
        let height: Float = Float(size.height)
        let distance: Float = 10
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        case 0:
            if y > height + distance{
                //無駄に呼ばれないための対策
                if communityRoomDocumentCount != communityRoomDocumentArray.count{
                    //30件を超える時はリロードしない
                    if communityRoomDocumentCount <= 30{
                        if indicator.isAnimating == false{
                            showIndicator()
                        }
                        communituyRoomPaginate()
                        DispatchQueue.main.async {
                            if self.indicator.isAnimating == true{
                                //ドキュメント数を更新
                                self.communityRoomDocumentCount = self.communityRoomDocumentArray.count
                                self.hideIndicator()
                            }
                        }
                    }
                }
            }
        case 1:
            break
        default:
            break
        }
    }
    
}
