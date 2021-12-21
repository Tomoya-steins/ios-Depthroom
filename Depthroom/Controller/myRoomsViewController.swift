import UIKit
import Firebase
import FirebaseStorageUI
import FloatingPanel
import ActiveLabel

class myRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var me: AppUser!
    var myName: String!
    var myIcon: String!
    var myDescription: String!
    var ownerUser: AppUser!
    var database: Firestore!
    var storage: Storage!
    //var listener: ListenerRegistration?
    //ルーム作成ボタン
    let createRoomButton = UIButton()
    //サイドメニューボタン
    let sideMenuButton = UIButton()
    //sideMenuを導入
    let sideMenu = sideMenuViewController()
    let contentViewController = UINavigationController()
    private var isShownSidemenu: Bool {
        return sideMenu.parent == self
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    var roomArray:[Room] = []
    //招待されたルーム情報を入れる
    var inviteMeArray: [Room] = []
    //clipRoomArrayとmyCommunityArrayはサイドメニューで
    var clipRoomButton: [String] = []
    var myCommunityArray: [Community] = []
    var recentMessage = "noTextData"
    var tagsArray: [String] = []
    //人気のコミュニティを10個ぶん配列に入れる
    var popularCommunityArray: [Community] = []
    //自身がブロックしているユーザ情報
    var blockedUserArray: [AppUser] = []
    //セミモーダル(部屋作成の際に出現)
    var fpc: FloatingPanelController!
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    //招待と所属を分ける
    var sections: [String] = ["invitationa", "myRoom"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //ルーム作成ボタン
        createRoomButton.frame = CGRect(x: 5*view.frame.width/7, y: 7*view.frame.height/9, width: view.frame.height/10, height: view.frame.height/10)
        createRoomButton.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        createRoomButton.tintColor = UIColor.green
        createRoomButton.imageView?.contentMode = .scaleAspectFit
        createRoomButton.contentHorizontalAlignment = .fill
        createRoomButton.contentVerticalAlignment = .fill
        createRoomButton.addTarget(self, action: #selector(self.buttonToCreateRoom), for: .touchUpInside)
        view.addSubview(createRoomButton)
        
        //カスタムしたセルを登録(roomCell)
        tableView.register(UINib(nibName: "roomsCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //collectionセルを登録
        let nib = UINib(nibName: "communityCollectionViewCell", bundle: nil)
        collectionView!.register(nib, forCellWithReuseIdentifier: "Cell")
        collectionSetup()
        
        //部屋作成のオプション周り
        semiModal()
        fpc.delegate = self
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        
        //sideMenuボタン
        sideMenuButton.frame = CGRect(x: view.frame.width/11, y: view.frame.width/10, width:35, height:35)
        sideMenuButton.setImage(UIImage(systemName: "text.justify"), for: .normal)
        sideMenuButton.imageView?.contentMode = .scaleAspectFit
        sideMenuButton.contentHorizontalAlignment = .fill
        sideMenuButton.contentVerticalAlignment = .fill
        sideMenuButton.addTarget(self, action: #selector(self.buttonToSideMenu), for: .touchUpInside)
        view.addSubview(sideMenuButton)
        
        
        
        //buttonToSideMenu.imageView?.contentMode = .scaleAspectFit
        //buttonToSideMenu.contentHorizontalAlignment = .fill
        //buttonToSideMenu.contentVerticalAlignment = .fill
        //sideMenu周り
        addChild(contentViewController)
        //view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        sideMenu.delegate = self
        sideMenu.startPanGestureRecognizing()
        
        //インディケータを動かす
        if indicator.isAnimating == false{
            showIndicator()
        }
        
        roomInfo()
        //ルームの情報を取得
        roomInfoFromFirebase()
        //コミュニティ関係
        communityInfo()
        //インディケータが動いていたら、止める
        DispatchQueue.main.async{
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
    
    //部屋作成ボタンを押した際に、openかcloseかの選択オプションを表示
    func semiModal(){
        fpc = FloatingPanelController()
        //モーダルを角丸にする
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 10.0
        fpc.surfaceView.appearance = appearance
        //セミモーダルビューとなるコントローラを生成、ルームのオプションを表示
        let roomOptionViewController = roomOptionViewController()
        fpc.set(contentViewController: roomOptionViewController)
    }
    
//    func configureRefreshControl(){
//        tableView.refreshControl = UIRefreshControl()
//        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
//    }
    
//    @objc func handleRefreshControl(){
//        roomInfo()
//        roomInfoFromFirebase()
//
//        DispatchQueue.main.async{
//            //self.tableView.reloadData()
//            self.tableView.refreshControl?.endRefreshing()  //これを必ず記載すること
//        }
//    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        //self.tableView.reloadData()
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //セミモーダルビューを非表示に
        fpc.removePanelFromParent(animated: true)
    }
    
    
    @objc func buttonToCreateRoom(_ sender: Any){
        fpc.addPanel(toParent: self, animated: true, completion: nil)
    }
    
    //コレクションの準備
    private func collectionSetup(){
        let cellWidth = UIScreen.main.bounds.width/2 - 90
        let layout = PagingPerCellFlowLayout()
        layout.headerReferenceSize = CGSize(width: 20, height: collectionView.frame.height)
        layout.footerReferenceSize = CGSize(width: 20, height: collectionView.frame.height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.itemSize = CGSize(width: cellWidth, height: collectionView.frame.height-10)
        collectionView.collectionViewLayout = layout
    }
    
    //ユーザの名前の情報を取得し、roomInfoFromFirebaseに渡す
    func roomInfo(){
        database.collection("users").document(me.userID).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.blockedUserArray = []
                self.me = AppUser(data: data)
                //ルームをクリップしていたら配列に情報が入る
                if self.me.clips != nil{
                    //1個のみ入れる
                    if self.clipRoomButton.count == 0{
                        self.clipRoomButton.append("お気に入り")
                        self.tableView.reloadData()
                    }
                }
                //自身がブロックしているユーザを配列に入れる
                //自身を招待しているルームの中から、自身がブロックしていないルームのみを表示させるため
                if let blocked = self.me.blocked{
                    for block in blocked.values{
                        let user = AppUser(data: block as! [String:Any])
                        self.blockedUserArray.append(user)
                    }
                }
            }
        }
        //listener?.remove()
    }
    
    //fireStoreからルーム情報を取得するためのメソッド
    func roomInfoFromFirebase(){
        //ドキュメントに何かあったら初期化
        inviteMeArray = []
       //自身が所属するルームの内容をFireStoreから取得
        database.collection("rooms").whereField("members.\(me.userID!).userID", isEqualTo: me.userID!).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                //ドキュメントが変更されたら初期化
                self.roomArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let room = Room(data: data)
                    self.roomArray.append(room)
                }
                //更新順にソート2021/12/14一旦停止
//                if self.roomArray.isEmpty != true{
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
//                        self.roomArray.sort(by: {$0.updatedAt.dateValue().compare($1.updatedAt.dateValue()) == .orderedDescending})
//                    }
//                }
                self.tableView.reloadData()
            }
        }
        
        //roomsのinvitationから自身データを含むドキュメントを取得、invitationArrayに格納
        //inviteMeArrayにルームの情報を取得、その後roomArrayにappendする
        database.collection("rooms").whereField("invitations.\(me.userID!).userID", isEqualTo: me.userID!).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                //ドキュメントが変更されたら初期化
                self.inviteMeArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let room = Room(data: data)
                    //ここで、このルームのオーナを自身がブロックしているかどうかで処理を分ける
                    //自分が相手をブロックしていなければ表示する
                    let user = AppUser(data: room.owner)
                    if self.blockedUserArray.firstIndex(where: { $0.userID == user.userID}) == nil{
                        self.inviteMeArray.append(room)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func communityInfo(){
        //自身の所属しているコミュニティ情報を取得
        database.collection("communities").whereField("members.\(me.userID!).userID", isEqualTo: me.userID!).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.myCommunityArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let community = Community(data: data)
                    self.myCommunityArray.append(community)
                }
            }
        }
        //人気のコミュニティを10件取得
        database.collection("communities").order(by: "weeklyMembersCount", descending: true).limit(to: 10).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.popularCommunityArray = []
                for document in snapshot.documents{
                    let data = document.data()
                    let community = Community(data: data)
                    self.popularCommunityArray.append(community)
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    //ソートを行う
    func sortArray(){
        //自身を招待している部屋があるのなら、roomArrayに追加
        if inviteMeArray.isEmpty != true{
            //この順番
            if roomArray.isEmpty != true{
                //招待ルーム→所属ルームの更新早い順を実現させるために必要
                roomArray.sort(by: {$0.updatedAt.dateValue().compare($1.updatedAt.dateValue()) == .orderedDescending})
                
                roomArray.reverse()
                roomArray.append(contentsOf: inviteMeArray)
                roomArray.reverse()
            }else{
                roomArray.append(contentsOf: inviteMeArray)
            }
        }else if roomArray.isEmpty != true{
            roomArray.sort(by: {$0.updatedAt.dateValue().compare($1.updatedAt.dateValue()) == .orderedDescending})
        }
        tableView.reloadData()
    }
    
    //キャンセル・参加・拒否の3つを提示する
    func inviteAlert(room: Room){
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        let semaphore = DispatchSemaphore(value: 0)
        let confirmJoin = UIAlertController(title: "参加確認", message: "「\(room.roomName!)」に参加しますか?", preferredStyle: .alert)
        
        confirmJoin.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        confirmJoin.addAction(UIAlertAction(title: "参加", style: .default, handler: { (action) in
            self.showIndicator()
            dispatchQueue.async(group: dispatchGroup) {
                let meInfo = [
                    "userID": self.me.userID,
                    "userIcon": self.me.userIcon,
                    "userName": self.me.userName
                ]
                self.database.collection("rooms").document(room.roomID).updateData([
                    "invitations.\(self.me.userID!)": FieldValue.delete(),
                    "members.\(self.me.userID!)": meInfo
                ])
                semaphore.signal()
            }
            dispatchGroup.notify(queue: .main){
                semaphore.wait()
                if self.indicator.isAnimating == true{
                    self.hideIndicator()
                }
                self.tableView.reloadData()
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
                nextViewController.room = room
                self.navigationController?.pushViewController(nextViewController, animated: true)
            }
        }))
        confirmJoin.addAction(UIAlertAction(title: "辞退", style: .default, handler: { (action) in
            self.showIndicator()
            dispatchQueue.async(group: dispatchGroup) {
                self.database.collection("rooms").document(room.roomID).updateData([
                    "invitations.\(self.me.userID!)": FieldValue.delete()
                ])
                semaphore.signal()
            }
            dispatchGroup.notify(queue: .main){
                semaphore.wait()
                if self.indicator.isAnimating == true{
                    self.hideIndicator()
                }
                self.tableView.reloadData()
                self.dismiss(animated: true, completion: nil)
            }
        }))
        present(confirmJoin, animated: true, completion: nil)
    }
    
    //sideMenuをタップした時
    @objc func buttonToSideMenu(_ sender: Any){
        showSideMenu(animated: true)
    }
    
    private func showSideMenu(contentAvailability: Bool = true, animated: Bool){
        if isShownSidemenu {return}
        
        self.addChild(sideMenu)
        sideMenu.view.autoresizingMask = .flexibleHeight
        sideMenu.view.frame = contentViewController.view.bounds
        sideMenu.communityArray = myCommunityArray
        sideMenu.me = me
        sideMenu.clipRoomButton = clipRoomButton
        view.insertSubview(sideMenu.view, aboveSubview: contentViewController.view)
        sideMenu.didMove(toParent: self)
        if contentAvailability{
            sideMenu.showContentView(animated: animated)
        }
    }
    
    private func hideSideMenu(animated: Bool){
        if !isShownSidemenu {return}
        
        sideMenu.hideContentView(animated: animated, complection: { (_) in
            self.sideMenu.willMove(toParent: nil)
            self.sideMenu.removeFromParent()
        })
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section{
        case 0:
            //アラートを表示
            inviteAlert(room: inviteMeArray[indexPath.row])
        case 1:
            //ルームチャットへの遷移
            let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
            nextViewController.room = roomArray[indexPath.row]
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return inviteMeArray.count
        case 1:
            return roomArray.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomsCell
        switch indexPath.section{
        //招待者
        case 0:
            //ルームの名前を表示
            cell.roomNameLabel.text = inviteMeArray[indexPath.row].roomName
            //ルームにおける最新のメッセージを表示
            if inviteMeArray[indexPath.row].recentMessage != nil{
                let recentMessage = GroupChat(data: inviteMeArray[indexPath.row].recentMessage)
                cell.messageLabel.text = recentMessage.body
            }else{
                cell.messageLabel.text = recentMessage
            }
            //更新時間
            if inviteMeArray[indexPath.row].updatedAt != nil{
                let time = inviteMeArray[indexPath.row].updatedAt.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
            }
            //タグ
            if let tags = inviteMeArray[indexPath.row].tags{
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
            //ルームのオーナーの画像を取得・表示
            if inviteMeArray[indexPath.row].owner != nil{
                let owner = AppUser(data: inviteMeArray[indexPath.row].owner)
                if let icon = owner.userIcon{
                    if let photoURL = URL(string: icon){
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
            }
            //ルームオーナのborderを黒色に
            let color: UIColor = UIColor.black
            cell.roomOwnerImageView.layer.borderColor = color.cgColor
            return cell
        //所属
        case 1:
            //ルームの名前を表示
            cell.roomNameLabel.text = roomArray[indexPath.row].roomName
            //ルームにおける最新のメッセージを表示
            if roomArray[indexPath.row].recentMessage != nil{
                let recentMessage = GroupChat(data: roomArray[indexPath.row].recentMessage)
                cell.messageLabel.text = recentMessage.body
            }else{
                cell.messageLabel.text = recentMessage
            }
            //更新時間
            if roomArray[indexPath.row].updatedAt != nil{
                let time = roomArray[indexPath.row].updatedAt.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
            }
            //タグ
            if let tags = roomArray[indexPath.row].tags{
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
            //コミュニティとしてルームを作成していた場合
            if let communities = roomArray[indexPath.row].community{
                let community = Community(data: communities)
                if let icon = community.communityIcon{
                    if let photoURL = URL(string: icon){
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
                //ルームオーナのborderをcommunityColorに
                let color: UIColor = UIColor(hex: community.communityColor)!
                cell.roomOwnerImageView.layer.borderColor = color.cgColor
            }else{
                //ルームのオーナーの画像を取得・表示
                if roomArray[indexPath.row].owner != nil{
                    let owner = AppUser(data: roomArray[indexPath.row].owner)
                    if let icon = owner.userIcon{
                        if let photoURL = URL(string: icon){
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
                }
                //ルームオーナのborderを黒色に
                let color: UIColor = UIColor.black
                cell.roomOwnerImageView.layer.borderColor = color.cgColor
            }
            return cell
        default:
            cell.roomNameLabel.text = ""
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/9
    }
    
    //コレクション
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader"{
            let section = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath)
            return section
        }else{
            let section = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer", for: indexPath)
            return section
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "communityPage") as! communityShowViewController
        nextViewController.community = popularCommunityArray[indexPath.row]
        nextViewController.me = me
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularCommunityArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! communityCollectionViewCell
        cell.backgroundColor = UIColor.white
        cell.layer.cornerRadius = 5
        cell.layer.shadowOpacity = 0.4
        cell.layer.shadowRadius = 5
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 8, height: 8)
        cell.layer.masksToBounds = false
        
        cell.communityNameLabel.text = popularCommunityArray[indexPath.row].communityName
        cell.communityMembersCount.text = "\(popularCommunityArray[indexPath.row].weeklyMembersCount!)人が参加中!"
        if let icon = popularCommunityArray[indexPath.row].communityIcon{
            if let photoURL = URL(string: icon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.communityIconImage.image = image
                }
                catch{
                    print("error")
                }
            }
        }
        let iconColor: UIColor = UIColor(hex: popularCommunityArray[indexPath.row].communityColor)!
        cell.communityIconImage.layer.borderColor = iconColor.cgColor
        let headerColor: UIColor = UIColor(hex: self.popularCommunityArray[indexPath.row].communityColor)!
        cell.communityMainColor.backgroundColor = headerColor
        
        return cell
    }
}

//部屋をタップした時にポップアップさせるために必要
extension myRoomsViewController: UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?{
        return customPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

//sideMenu周り
extension myRoomsViewController: FloatingPanelControllerDelegate{
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout{
        return CustomFloatingPanelLayout()
    }
}

extension myRoomsViewController: sideMenuViewControllerDelegate{
    func sidemenuViewController(_ sidemenuViewController: sideMenuViewController, didSelectItemAt indexPath: IndexPath) {
        hideSideMenu(animated: true)
    }
    func parentViewControllerForSideMenuViewController(_ sidemenuViewController: sideMenuViewController) -> UIViewController {
        return self
    }
    func shouldPresentForSideMenuViewController(_ sidemenuViewController: sideMenuViewController) -> Bool {
        return true
    }
    func sideMenuViewControllerDidRequestShowing(_ sidemenuViewController: sideMenuViewController, contentAvailability: Bool, animated: Bool) {
        showSideMenu(contentAvailability: contentAvailability, animated: animated)
    }
    func sideMenuViewControllerDidRequestHiding(_ sidemenuViewController: sideMenuViewController, animated: Bool) {
        hideSideMenu(animated: animated)
    }
}


class CustomFloatingPanelLayout: FloatingPanelLayout{
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .half
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]{
        return [
            //.tip: FloatingPanelLayoutAnchor(absoluteInset: 100, edge: .bottom, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 230.0, edge: .bottom, referenceGuide: .safeArea),
            //.full: FloatingPanelLayoutAnchor(absoluteInset: 20, edge: .top, referenceGuide: .safeArea)
        ]
    }
    
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        switch state {
        //case .full:
            //return 0.3
        case .half:
            return 0.3
        default:
            return 0.0
        }
    }
}
