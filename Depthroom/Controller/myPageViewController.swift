//
//  myPageViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/06.
//

import UIKit
import Firebase
import FirebaseStorageUI

class myPageViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    //自分のマイページだけではなく、他人のマイページも兼ねているためmeではなく、userで
    var user: AppUser!
    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    var communityArray: [Community] = []
    //スクロール関係
    var communityDocumentArray: [QueryDocumentSnapshot] = []
    var communityQuery: Query!
    //スクロール数管理
    var communityDocumentCount = 0
    //フォロー・フォロワー数管理
    var followCount: Int!
    var followerCount: Int!
    //ぼかし
    let blurEffect = UIBlurEffect(style: .light)
    //ぼかされている理由を表示(理由: ブロックor鍵垢)
    let blurReason = UILabel()
    //クルクル
    var indicator = UIActivityIndicatorView()
    //背景になるview
    var backView = UIView()
    
    //var listener: ListenerRegistration?
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myUserNameLabel: UILabel!
    @IBOutlet weak var myProfileImage: UIImageView!
    @IBOutlet weak var profileContent: UILabel!
    @IBOutlet weak var buttonToSetting: UIButton!
    @IBOutlet weak var buttonToEditOrFollow: UIButton!
    @IBOutlet weak var buttonToFollowAndFollower: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "communityCreateCell", bundle: nil), forCellReuseIdentifier: "communityCreate")
        //community
        communityDocumentArray = []
        communityArray = []
        communityQuery = database.collection("communities").whereField("members.\(user.userID!).userID", isEqualTo: user.userID!).limit(to: 10)

        //プロフィール画像について
        myProfileImage.layer.cornerRadius = 75
        myProfileImage.layer.masksToBounds = true
        myProfileImage.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        myProfileImage.layer.shadowColor = UIColor.black.cgColor
        myProfileImage.layer.borderWidth = 0.2
        myProfileImage.layer.shadowOpacity = 1.0
        myProfileImage.layer.shadowRadius = 10
        //設定アイコンについて
        buttonToSetting.imageView?.contentMode = .scaleAspectFit
        buttonToSetting.contentHorizontalAlignment = .fill
        buttonToSetting.contentVerticalAlignment = .fill
        
        //自分のマイページであれば、編集を表示
        //違う場合は、フォローボタンを表示(unフォローはuserInfoで明記)
        if auth.currentUser?.uid == user.userID{
            buttonToEditOrFollow.setTitle("編集する", for: UIControl.State.normal)
            buttonToEditOrFollow.setTitleColor(.black, for: .normal)
            buttonToEditOrFollow.layer.cornerRadius = 10
            buttonToEditOrFollow.layer.borderWidth = 0.1
            buttonToEditOrFollow.layer.borderColor = UIColor.black.cgColor
            buttonToEditOrFollow.backgroundColor = UIColor.yellow
            buttonToEditOrFollow.addTarget(self, action: #selector(self.buttonToEdit), for: .touchUpInside)
            self.view.addSubview(buttonToEditOrFollow)
        }else{
            buttonToEditOrFollow.isSelected = false
            //相手をフォローしているかどうかかかわらず、タイトルはとりあえず「フォローする」
            buttonToEditOrFollow.setTitle("フォローする", for: UIControl.State.normal)
            buttonToEditOrFollow.setTitleColor(.black, for: .normal)
            buttonToEditOrFollow.layer.cornerRadius = 10
            buttonToEditOrFollow.layer.borderWidth = 0.1
            buttonToEditOrFollow.layer.borderColor = UIColor.black.cgColor
            buttonToEditOrFollow.backgroundColor = UIColor.green
            buttonToEditOrFollow.addTarget(self, action: #selector(self.doFollowOrUnfollow), for: .touchUpInside)
        }
        //インディケータを動かす
        if indicator.isAnimating == false{
            showIndicator()
        }
        userInfo()
        userCommunityInfo()
        meInfo()
        //インディケータが動いていたら、止める
        DispatchQueue.main.async {
            if self.indicator.isAnimating == true{
                self.hideIndicator()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if auth.currentUser?.uid == user.userID{
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }else{
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
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
    
    //対象ユーザの情報を載せる
    func userInfo(){
        //ユーザネームと自己紹介を表示
        database.collection("users").document(user.userID).addSnapshotListener{ (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.user = AppUser(data: data)
                self.myUserNameLabel.text = self.user.userName
                self.profileContent.text = self.user.userDescription
                
                //アイコンの情報を渡して画像を表示
                if let photoURL = URL(string: self.user.userIcon){
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        self.myProfileImage.image = image
                    }
                    catch{
                        print("error")
                    }
                }
                
                //フォロー・フォロワー数を取得
                //値を初期化
                self.followCount = 0
                self.followerCount = 0
                let dispatchGroup = DispatchGroup()
                let dispatchQueue = DispatchQueue(label: "queue")
                dispatchQueue.async(group: dispatchGroup) {
                    if let follow = self.user.follow{
                        self.followCount = follow.count
                    }
                    if let follower = self.user.follower{
                        self.followerCount = follower.count
                    }
                }
                //取得した値をボタンに反映
                dispatchGroup.notify(queue: .main){
                    self.buttonToFollowAndFollower.setTitle("フォロー: \(self.followCount!) | フォロワー: \(self.followerCount!)", for: UIControl.State.normal)
                }
                //もし相手のフォロワーに自分がいたら
                if self.auth.currentUser?.uid != self.user.userID{
                    if let follower = self.user.follower{
                        for follower in follower.values{
                            let user = AppUser(data: follower as! [String:Any])
                            //もし相手のフォロワーに自分がいたら = 自分が既に相手をフォローしていたら
                            if self.auth.currentUser?.uid == user.userID{
                                self.buttonToEditOrFollow.isSelected = true
                                self.buttonToEditOrFollow.setTitle("フォローを解除する", for: UIControl.State.normal)
                                self.buttonToEditOrFollow.setTitleColor(.white, for: .normal)
                                self.buttonToEditOrFollow.layer.cornerRadius = 10
                                self.buttonToEditOrFollow.layer.borderWidth = 0.1
                                self.buttonToEditOrFollow.layer.borderColor = UIColor.black.cgColor
                                self.buttonToEditOrFollow.backgroundColor = UIColor.link
                                self.buttonToEditOrFollow.addTarget(self, action: #selector(self.doFollowOrUnfollow), for: .touchUpInside)
                            }
                        }
                    }
                }
                //もし相手にブロックされていたら
                if let block = self.user.blocked{
                    for block in block.values{
                        let blockUser = AppUser(data: block as! [String:Any])
                        if self.auth.currentUser?.uid == blockUser.userID{
                            //相手にブロックされているときの描画制限を行う
                            self.ifBlocked()
                        }
                    }
                }
                //もし相手が鍵アカウント状態だったら
                //さらに自身が相手からフォローされていない場合
                if self.user.locked == true && self.auth.currentUser?.uid != self.user.userID{
                    //相手が自身をフォローしているかの確認のために用いる
                    var userFollowMe = false
                    //さらに自身が相手からフォローされていない場合
                    if let follow = self.user.follow{
                        for follow in follow.values{
                            let user = AppUser(data: follow as! [String:Any])
                            //相手が自身をフォローしていたらuserFollowMeをtrueに
                            if self.auth.currentUser?.uid == user.userID{
                                userFollowMe = true
                            }
                        }
                        if userFollowMe == false{
                            //相手の設定画面・相手の所属コミュニティ一覧への遷移を防ぐ
                            self.lockUI()
                        }
                    }else{
                        //相手の設定画面・相手の所属コミュニティ一覧への遷移を防ぐ
                        self.lockUI()
                    }
                }
            }
        }
        //listener?.remove()
    }
    
    //対象ユーザの所属コミュニティを取得
    //スクロール下でリロードするたびに呼ばれる
    func userCommunityInfo(){
        communityQuery.addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                snapshot.documents.forEach ({ (document) in
                    let data = document.data()
                    let community = Community(data: data)
                    self.communityArray.append(community)
                    self.communityDocumentArray.append(document)
                })
                self.tableView.reloadData()
            }
        }
    }
    
    func meInfo(){
        //他人をフォローした時の処理に使う
        //他人のfollowerに自身の情報を載せる必要があるため
        if auth.currentUser?.uid != user.userID{
            database.collection("users").document(auth.currentUser!.uid).addSnapshotListener{ (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    self.me = AppUser(data: data)
                }
            }
            //listener?.remove()
        }
    }
    
    //リロード開始
    func communityPaginate(){
        communityQuery = communityQuery.start(afterDocument: communityDocumentArray.last!)
        userCommunityInfo()
    }
    
    func ifBlocked(){
        //コミュニティ一覧に対してぼかしを入れる
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.tableView.frame
        view.addSubview(blurEffectView)
       //ぼかしの上にテキスト表示
        blurReason.frame = CGRect(x: 0, y: 2*self.view.frame.height/3, width: self.view.frame.width, height: 20)
        blurReason.textAlignment = NSTextAlignment.center
        blurReason.text = "「\(user.userName!)」にブロックされています"
        blurReason.textColor = UIColor.black
        blurReason.font = UIFont(name: "HiraKakuProN-W6", size: 17)
        self.view.addSubview(blurReason)
    }
    func lockUI(){
        //設定ボタンを非表示に
        buttonToSetting.isHidden = true
        
        //コミュニティ一覧に対してぼかしをかける
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.tableView.frame
        view.addSubview(blurEffectView)
        //ぼかしの上にテキスト表示
        blurReason.frame = CGRect(x: 0, y: 2*self.view.frame.height/3, width: self.view.frame.width, height: 20)
        blurReason.textAlignment = NSTextAlignment.center
        blurReason.text = "表示するためには「\(user.userName!)」にフォローされる必要があります"
        blurReason.textColor = UIColor.black
        blurReason.font = UIFont(name: "HiraKakuProN-W6", size: 13)
        self.view.addSubview(blurReason)
    }
    
    //プロフィール編集画面へ遷移
    @objc func buttonToEdit(_ sender: Any){
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "edit") as! myProfileEditViewController
        nextViewController.me = user
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @IBAction func buttonToFollowAndFollower(_ sender: Any) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "followAndFollower") as! followsViewController
        nextViewController.user = user
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    @objc func doFollowOrUnfollow(_ sender: Any){
        //一応
        if me.userID != user.userID{
            //フォロー処理
            if buttonToEditOrFollow.isSelected == false{
                let dispatchGroup = DispatchGroup()
                let dispatchQueue = DispatchQueue(label: "queue")
                dispatchQueue.async(group: dispatchGroup){
                    dispatchGroup.enter()
                    //フォローした人(自分)の follow に相手の情報を保存
                    let meRef = self.database.collection("users").document(self.me.userID)
                    let otherInfo = [
                        "userID": self.user.userID,
                        "userName": self.user.userName,
                        "userDescription": self.user.userDescription,
                        "userIcon": self.user.userIcon
                    ]
                    meRef.updateData([
                        "follow.\(self.user.userID!)": otherInfo
                    ])
                    //フォローされた人(相手)の follower に自分の情報を保存
                    let you = self.database.collection("users").document(self.user.userID)
                    let meInfo = [
                        "userID": self.me.userID,
                        "userName": self.me.userName,
                        "userDescription": self.me.userDescription,
                        "userIcon": self.me.userIcon
                    ]
                    you.updateData([
                        "follower.\(self.me.userID!)": meInfo
                    ])
                    self.followCount = self.followCount + 1
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main){
                    //フォローボタン→フォローを解除するボタン
                    self.buttonToEditOrFollow.isSelected = true
                    self.buttonToEditOrFollow.setTitle("フォローを解除する", for: UIControl.State.normal)
                    self.buttonToEditOrFollow.setTitleColor(.white, for: .normal)
                    self.buttonToEditOrFollow.layer.cornerRadius = 10
                    self.buttonToEditOrFollow.layer.borderWidth = 0.1
                    self.buttonToEditOrFollow.layer.borderColor = UIColor.black.cgColor
                    self.buttonToEditOrFollow.backgroundColor = UIColor.link
                    //現在のフォロワーを反映
                    self.buttonToFollowAndFollower.setTitle("フォロー: \(self.followCount!) | フォロワー: \(self.followerCount!)", for: UIControl.State.normal)
                }
            }else if buttonToEditOrFollow.isSelected == true{
                //アンフォロー処理
                let dispatchGroup = DispatchGroup()
                let dispatchQueue = DispatchQueue(label: "queue")
                let confirmUnfollow = UIAlertController(title: "確認", message: "フォローを解除しますか?", preferredStyle: .alert)
                confirmUnfollow.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                confirmUnfollow.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    dispatchQueue.async(group: dispatchGroup) {
                        dispatchGroup.enter()
                        //自身のfollowから相手の情報を削除
                        self.database.collection("users").document(self.me.userID).updateData([
                            "follow.\(self.user.userID!)": FieldValue.delete()
                        ])
                        //相手のfollowerから自身の情報を削除
                        self.database.collection("users").document(self.user.userID).updateData([
                            "follower.\(self.me.userID!)": FieldValue.delete()
                        ])
                        //フォロワーのカウントを1減らす
                        self.followerCount = self.followerCount - 1
                        dispatchGroup.leave()
                    }
                    dispatchGroup.notify(queue: .main){
                        self.dismiss(animated: true, completion: nil)
                        self.buttonToEditOrFollow.isSelected = false
                        self.buttonToEditOrFollow.setTitle("フォローする", for: UIControl.State.normal)
                        self.buttonToEditOrFollow.setTitleColor(.black, for: .normal)
                        self.buttonToEditOrFollow.layer.cornerRadius = 10
                        self.buttonToEditOrFollow.layer.borderWidth = 0.1
                        self.buttonToEditOrFollow.layer.borderColor = UIColor.black.cgColor
                        self.buttonToEditOrFollow.backgroundColor = UIColor.green
                        self.buttonToFollowAndFollower.setTitle("フォロー: \(self.followCount!) | フォロワー: \(self.followerCount!)", for: UIControl.State.normal)
                    }
                }))
                self.present(confirmUnfollow, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func buttonToSetting(_ sender: Any) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "userSetting") as! userSettingViewController
        nextViewController.user = user
        //相手の設定画面に飛ぶときに自身の値を持たせる
        if auth.currentUser?.uid != user.userID{
            nextViewController.me = me
        }
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "communityPage") as! communityShowViewController
        //コミュニティのIDとオーナーのIDのみ値を渡す
        //他の情報は変更される恐れがあるため
        nextViewController.community = communityArray[indexPath.row]
        //見ているページが自分か相手かで処理を分ける必要がある
        if auth.currentUser?.uid == user.userID{
            nextViewController.me = user
        }else{
            nextViewController.me = me
        }
        //選択した跡が残らない
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return communityArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "communityCreate", for: indexPath) as! communityCreateCell
        cell.communityNameLabel.text = communityArray[indexPath.row].communityName
        //該当コミュニティの参加人数をラベルに反映
        if let members = communityArray[indexPath.row].members{
            cell.memberCountLabel.text = "\(members.count)人が参加中"
        }
        if let icon = communityArray[indexPath.row].communityIcon{
            if let photoURL = URL(string: icon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.communityIcon.image = image
                }
                catch{
                    print("error")
                }
            }
        }
        let color: UIColor = UIColor(hex: communityArray[indexPath.row].communityColor)!
        cell.communityIcon.layer.borderColor = color.cgColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/9
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
        
        if y > height + distance{
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
    }
}
