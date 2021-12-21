//
//  searchViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/18.
//

import UIKit
import Firebase
import FirebaseStorageUI
import ActiveLabel

class searchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var selectSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var openRoomArray:[Room] = []
    var userArray: [AppUser] = []
    var communityArray: [Community] = []
    var tagArray: [Tag] = []
    //searchは検索の際に使われる配列、そのままcellForRowAtで使う
    var searchRoomArray: [Room] = []
    var openRoomDocumentArray: [QueryDocumentSnapshot] = []
    var openRoomQuery: Query!
    //ユーザ関係
    var searchUserArray: [AppUser] = []
    var userDocumentArray: [QueryDocumentSnapshot] = []
    var userQuery: Query!
    //コミュニティ関係
    var searchCommunityArray: [Community] = []
    var communityDocumentArray: [QueryDocumentSnapshot] = []
    var communityQuery: Query!
    //タグ関係
    var searchTagArray: [Tag] = []
    var tagDocumentArray: [QueryDocumentSnapshot] = []
    var tagQuery: Query!
    //スクロールしすぎで無駄にfireStoreを呼ばないためにドキュメント数で管理
    //scrollViewDidScrollで使う
    var userDocumentCount = 0
    var openRoomDocumentCount = 0
    var communityDocumentCount = 0
    var tagDocumentCount = 0
    
    var tagsArray: [String] = []
    
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        search.delegate = self
        
        //room
        openRoomDocumentArray = []
        searchRoomArray = []
        openRoomQuery = database.collection("rooms").limit(to: 10)
        //user
        userDocumentArray = []
        searchUserArray = []
        userQuery = database.collection("users").limit(to: 10)
        //community
        communityDocumentArray = []
        searchCommunityArray = []
        communityQuery = database.collection("communities").limit(to: 10)
        //2021/12/06テストtag
        tagDocumentArray = []
        searchTagArray = []
        tagQuery = database.collection("tags").limit(to: 10)
        
        //カスタムしたセルを登録(roomCell)
        tableView.register(UINib(nibName: "roomCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "userNameAndIconCell", bundle: nil), forCellReuseIdentifier: "userNameAndIcon")
        tableView.register(UINib(nibName: "communityCreateCell", bundle: nil), forCellReuseIdentifier: "communityCreate")
        if indicator.isAnimating == false{
            showIndicator()
        }
        //openRoom()
        //user()
        //community()
        //tag()
        getLimitUser()
        getLimitOpenRoom()
        getLimitCommunity()
        getLimitTag()
        DispatchQueue.main.async {
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func showIndicator(){
        backView.frame = self.view.frame
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
    
    func openRoom(){
        //オープンなルームを取得する
        database.collection("rooms").whereField("state", isEqualTo: "open").addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.openRoomArray = []
                //self.searchRoomArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let room = Room(data: data)
                    self.openRoomArray.append(room)
                }
            }
            //検索用配列に追加
            //self.searchRoomArray.append(contentsOf: self.openRoomArray)
            //self.tableView.reloadData()
        }
    }
    func user(){
        //ユーザを取得
        database.collection("users").addSnapshotListener{ (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.userArray = []
                //self.searchUserArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let user = AppUser(data: data)
                    self.userArray.append(user)
                }
            }
            //検索用配列に追加
            //self.searchUserArray.append(contentsOf: self.userArray)
            //self.tableView.reloadData()
        }
    }
    func community(){
        //コミュニティを取得
        database.collection("communities").addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.communityArray = []
                //self.searchCommunityArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let community = Community(data: data)
                    self.communityArray.append(community)
                }
            }
            //検索用配列に追加
            //self.searchCommunityArray.append(contentsOf: self.communityArray)
            //self.tableView.reloadData()
        }
    }
    func tag(){
        //タグを取得
        database.collection("tags").addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.tagArray = []
                //self.searchTagArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let tag = Tag(data: data)
                    self.tagArray.append(tag)
                }
            }
            //検索用配列に追加
            //self.searchTagArray.append(contentsOf: self.tagArray)
            //self.tableView.reloadData()
        }
    }
    //paginateして更新
    func openRoomPaginate(){
        openRoomQuery = openRoomQuery.start(afterDocument: openRoomDocumentArray.last!)
        getLimitOpenRoom()
    }
    func userPaginate(){
        userQuery = userQuery.start(afterDocument: userDocumentArray.last!)
        getLimitUser()
    }
    func communityPaginate(){
        communityQuery = communityQuery.start(afterDocument: communityDocumentArray.last!)
        getLimitCommunity()
    }
    func tagPaginate(){
        tagQuery = tagQuery.start(afterDocument: tagDocumentArray.last!)
        getLimitTag()
    }
    
    func getLimitOpenRoom(){
        openRoomQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let openRoom = Room(data: data)
                    self.searchRoomArray.append(openRoom)
                    self.openRoomDocumentArray.append(document)
                })
                self.tableView.reloadData()
            }
        }
    }
    func getLimitUser(){
        userQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let user = AppUser(data: data)
                    self.searchUserArray.append(user)
                    self.userDocumentArray.append(document)
                })
                self.tableView.reloadData()
            }
        }
    }
    func getLimitCommunity(){
        communityQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let community = Community(data: data)
                    self.searchCommunityArray.append(community)
                    self.communityDocumentArray.append(document)
                })
                self.tableView.reloadData()
            }
        }
    }
    func getLimitTag(){
        tagQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let tag = Tag(data: data)
                    self.searchTagArray.append(tag)
                    self.tagDocumentArray.append(document)
                })
                //self.tagDocumentCount = self.tagDocumentArray.count
                self.tableView.reloadData()
            }
        }
    }
    
    
    @IBAction func tappedSegmentControl(_ sender: Any) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        //ユーザ詳細ページへ
        case 0:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "userPage") as! myPageViewController
            nextViewController.user = searchUserArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        //オープンルームのチャット画面へ
        case 1:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
            nextViewController.room = searchRoomArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        //コミュニティ詳細画面へ
        case 2:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "communityPage") as! communityShowViewController
            nextViewController.community = searchCommunityArray[indexPath.row]
            nextViewController.me = me
            self.navigationController?.pushViewController(nextViewController, animated: true)
        //タグルーム一覧へ
        case 3:
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "hashTagRooms") as! hashTagRoomsViewController
            //nextViewController.tag = tagArray[indexPath.row]
            nextViewController.gettag = searchTagArray[indexPath.row].tagName
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        case 0:
            return searchUserArray.count
        case 1:
            return searchRoomArray.count
        case 2:
            return searchCommunityArray.count
        case 3:
            return searchTagArray.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell")!
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userNameAndIcon", for: indexPath) as! userNameAndIconCell
            cell.userNameLabel.text = searchUserArray[indexPath.row].userName
            //メンバーのアイコンを取得・表示
            if let photoURL = URL(string: searchUserArray[indexPath.row].userIcon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.userIcon.image = image
                }
                catch{
                    print("error")
                }
            }
            //ロックされているユーザかどうか
            if searchUserArray[indexPath.row].locked == true{
                //ロックアイコン
                cell.lockedOrUnlockedImage.image = UIImage(systemName: "lock.fill")
                cell.lockedOrUnlockedImage.tintColor = UIColor.black
            }else{
                //アンロックアイコン
                cell.lockedOrUnlockedImage.image = UIImage(systemName: "lock.open.fill")
                cell.lockedOrUnlockedImage.tintColor = UIColor.black
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCell
            //ルームの名前を表示
            cell.roomNameLabel.text = searchRoomArray[indexPath.row].roomName
//            if openRoomArray[indexPath.row].recentMessage != nil{
//                let recentMessage = GroupChat(data: searchRoomArray[indexPath.row].recentMessage)
//                cell.messageLabel.text = recentMessage.body
//            }else{
//                cell.messageLabel.text = "noText"
//            }
            //更新時間
            if searchRoomArray[indexPath.row].updatedAt != nil{
                let time = searchRoomArray[indexPath.row].updatedAt.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
            }
            //タグ
            if let tags = searchRoomArray[indexPath.row].tags{
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
            if searchRoomArray[indexPath.row].owner != nil{
                let owner = AppUser(data: searchRoomArray[indexPath.row].owner)
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
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "communityCreate", for: indexPath) as! communityCreateCell
            cell.communityNameLabel.text = searchCommunityArray[indexPath.row].communityName
            if let photoURL = URL(string: searchCommunityArray[indexPath.row].communityIcon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.communityIcon.image = image
                }
                catch{
                    print("error")
                }
            }
            let color: UIColor = UIColor(hex: searchCommunityArray[indexPath.row].communityColor)!
            cell.communityIcon.layer.borderColor = color.cgColor
            return cell
        case 3:
            cell.textLabel?.text = searchTagArray[indexPath.row].tagName
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
            if y > height + distance {
                //無駄に呼ばれないための対策
                if userDocumentCount != userDocumentArray.count{
                    if userDocumentCount <= 30{
                        if indicator.isAnimating == false{
                            showIndicator()
                        }
                        userPaginate()
                        DispatchQueue.main.async {
                            if self.indicator.isAnimating == true{
                                //ドキュメント数を更新
                                self.userDocumentCount = self.userDocumentArray.count
                                self.hideIndicator()
                            }
                        }
                    }
                }
            }
        case 1:
            if y > height + distance {
                //無駄に呼ばれないための対策
                if openRoomDocumentCount != openRoomDocumentArray.count{
                    if openRoomDocumentCount <= 30{
                        if indicator.isAnimating == false{
                            showIndicator()
                        }
                        openRoomPaginate()
                        DispatchQueue.main.async {
                            if self.indicator.isAnimating == true{
                                //ドキュメント数を更新
                                self.openRoomDocumentCount = self.openRoomDocumentArray.count
                                self.hideIndicator()
                            }
                        }
                    }
                }
            }
        case 2:
            if y > height + distance {
                //無駄に呼ばれないための対策
                if communityDocumentCount != communityDocumentArray.count{
                    if communityDocumentCount <= 30{
                        if indicator.isAnimating == false{
                            showIndicator()
                        }
                        communityPaginate()
                        DispatchQueue.main.async {
                            if self.indicator.isAnimating == true{
                                //ドキュメント数を更新
                                self.communityDocumentCount = self.communityDocumentArray.count
                                self.hideIndicator()
                            }
                        }
                    }
                }
            }
        case 3:
            if y > height + distance {
                //無駄に呼ばれないための対策
                if tagDocumentCount != tagDocumentArray.count{
                    if tagDocumentCount <= 30{
                        if indicator.isAnimating == false{
                            showIndicator()
                        }
                        tagPaginate()
                        DispatchQueue.main.async {
                            if self.indicator.isAnimating == true{
                                //ドキュメント数を更新
                                self.tagDocumentCount = self.tagDocumentArray.count
                                self.hideIndicator()
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
}


extension searchViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex{
        case 0:
            searchUser(searchText)
        case 1:
            searchRoom(searchText)
        case 2:
            searchCommunity(searchText)
        case 3:
            searchTag(searchText)
        default:
            break
        }
    }
    
    private func searchRoom(_ text: String) {
        var currentOpenRoomArray: [Room] = []
        if text.isEmpty != true{
            //値が入っている時
            currentOpenRoomArray = openRoomArray.filter({ item -> Bool in
                item.roomName.lowercased().contains(text.lowercased())
            })
            searchRoomArray = currentOpenRoomArray
        }else{
            //入っていない時
            searchRoomArray = openRoomArray
        }
        tableView.reloadData()
    }
    
    private func searchUser(_ text: String) {
        var currentUserArray: [AppUser] = []
        if text.isEmpty != true{
            //値が入っている時
            currentUserArray = userArray.filter({ item -> Bool in
                item.userName.lowercased().contains(text.lowercased())
            })
            searchUserArray = currentUserArray
        }else{
            //入っていない時
            searchUserArray = userArray
        }
        tableView.reloadData()
    }
    
    private func searchCommunity(_ text: String) {
        var currentCommunityArray: [Community] = []
        if text.isEmpty != true{
            //値が入っている時
            currentCommunityArray = communityArray.filter({ item -> Bool in
                item.communityName.lowercased().contains(text.lowercased())
            })
            searchCommunityArray = currentCommunityArray
        }else{
            //入っていない時
            searchCommunityArray = communityArray
        }
        tableView.reloadData()
    }
    
    private func searchTag(_ text: String){
        var currentTagArray: [Tag] = []
        if text.isEmpty != true{
            //値が入っている時
            currentTagArray = tagArray.filter({ item -> Bool in
                item.tagName.lowercased().contains(text.lowercased())
            })
            searchTagArray = currentTagArray
        }else{
            //入っていない時
            searchTagArray = tagArray
        }
        tableView.reloadData()
    }
}
