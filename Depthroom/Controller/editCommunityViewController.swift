//
//  editCommunityViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/15.
//

import UIKit
import Firebase

class editCommunityViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var me: AppUser!
    var community: Community!
    var database: Firestore!
    var storage: Storage!
    
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var customButton: UIButton!
    
    var selectColorCode: String!
    //アイコンかヘッダーか区別する際に使う
    var iconOrHeader: String!
    @IBOutlet weak var communityHeaderImageView: UIImageView!
    @IBOutlet weak var communityIconImageView: UIImageView!
    @IBOutlet weak var communityNameLabel: UITextField!
    //色選択ボタンを置くためにも使う
    @IBOutlet weak var communityDescriptionLabel: UITextField!
    
    @IBOutlet weak var selectColorCodeLabel: UILabel!
    @IBOutlet weak var colorCodeLabel: UITextField!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        //アイコンを丸く
        communityIconImageView.layer.borderWidth = 1
        communityIconImageView.layer.cornerRadius = communityIconImageView.frame.height/2
        communityIconImageView.layer.masksToBounds = true
        
        //ここに色選択のための図形を描画
        //赤色
        redButton.layer.borderColor = UIColor.black.cgColor
        redButton.layer.borderWidth = 1.0
        redButton.layer.backgroundColor = UIColor(hex: "#EF7779")?.cgColor
        //黄色
        yellowButton.layer.borderColor = UIColor.black.cgColor
        yellowButton.layer.borderWidth = 1.0
        yellowButton.layer.backgroundColor = UIColor(hex: "#FEF77C")?.cgColor
        //オレンジ色
        orangeButton.layer.borderColor = UIColor.black.cgColor
        orangeButton.layer.borderWidth = 1.0
        orangeButton.layer.backgroundColor = UIColor(hex: "#F7A654")?.cgColor
        //青色
        blueButton.layer.borderColor = UIColor.black.cgColor
        blueButton.layer.borderWidth = 1.0
        blueButton.layer.backgroundColor = UIColor(hex: "#B9EAED")?.cgColor
        //緑色
        greenButton.layer.borderColor = UIColor.black.cgColor
        greenButton.layer.borderWidth = 1.0
        greenButton.layer.backgroundColor = UIColor(hex: "#99FF94")?.cgColor
        //カスタム色(紫色)
        customButton.layer.borderColor = UIColor.black.cgColor
        customButton.layer.borderWidth = 1.0
        customButton.layer.backgroundColor = UIColor(hex: "#D0C4FC")?.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //初期化
        iconOrHeader = ""
        communityNameLabel.text = community.communityName
        communityDescriptionLabel.text = community.communityDescription
        
        //アイコンを設定
        if let icon = community.communityIcon{
            if let photoURL = URL(string: icon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    self.communityIconImageView.image = image
                }
                catch{
                    print("error")
                    return
                }
            }
        }
        //ヘッダーを設定
        if let header = community.communityHeader{
            if let photoURL = URL(string: header){
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
            let color: UIColor = UIColor(hex: community.communityColor)!
            communityHeaderImageView.backgroundColor = color
        }
        //アイコンのborderにテーマカラーを適応
        let communityIconBorder: UIColor = UIColor(hex: community.communityColor)!
        communityIconImageView.layer.borderColor = communityIconBorder.cgColor
        //現在テーマカラー設定している色を選択させる
        if let color = community.communityColor{
            switch color{
            //赤色
            case "#EF7779":
                redButton.isSelected = true
                selectColorCode = "#EF7779"
                redButton.layer.borderColor = UIColor.yellow.cgColor
                redButton.layer.borderWidth = 1.0
                colorCodeLabel.isHidden = true
                selectColorCodeLabel.isHidden = true
            //黄色
            case "#FEF77C":
                yellowButton.isSelected = true
                selectColorCode = "#FEF77C"
                yellowButton.layer.borderColor = UIColor.yellow.cgColor
                yellowButton.layer.borderWidth = 1.0
                colorCodeLabel.isHidden = true
                selectColorCodeLabel.isHidden = true
            //オレンジ色
            case "#F7A654":
                orangeButton.isSelected = true
                selectColorCode = "#F7A654"
                orangeButton.layer.borderColor = UIColor.yellow.cgColor
                orangeButton.layer.borderWidth = 1.0
                colorCodeLabel.isHidden = true
                selectColorCodeLabel.isHidden = true
            //青色
            case "#B9EAED":
                blueButton.isSelected = true
                selectColorCode = "#B9EAED"
                blueButton.layer.borderColor = UIColor.yellow.cgColor
                blueButton.layer.borderWidth = 1.0
                colorCodeLabel.isHidden = true
                selectColorCodeLabel.isHidden = true
            //緑色
            case "#99FF94":
                greenButton.isSelected = true
                selectColorCode = "#99FF94"
                greenButton.layer.borderColor = UIColor.yellow.cgColor
                greenButton.layer.borderWidth = 1.0
                colorCodeLabel.isHidden = true
                selectColorCodeLabel.isHidden = true
            default:
                customButton.isSelected = true
                selectColorCode = color
                customButton.layer.borderColor = UIColor.yellow.cgColor
                colorCodeLabel.isHidden = false
                selectColorCodeLabel.isHidden = false
                colorCodeLabel.text = color
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        //カラーtextFieldのy座標を取得
        //スクロールの高さを決める
        let y = colorCodeLabel.frame.origin.y + colorCodeLabel.frame.height
        let height = colorCodeLabel.frame.height
        let sum = y+height+10
        contentView.heightAnchor.constraint(equalToConstant: sum).isActive = true
        scrollView.contentSize = contentView.frame.size
        scrollView.flashScrollIndicators()
    }
    
    @IBAction func buttonToCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonToCompleteEdit(_ sender: Any) {
        let communityName = communityNameLabel.text!
        let communityDescription = communityDescriptionLabel.text!
        //コミュニティの名前とアイコンは必須のため
        if communityName.isEmpty != true, selectColorCode.isEmpty != true, let iconImage = communityIconImageView.image{
            
            //カスタムボタンにカラーコードが入力されていたら、selectColorCodeに代入
            if customButton.isSelected == true && colorCodeLabel.text?.isEmpty != true{
                selectColorCode = colorCodeLabel.text
            }else if customButton.isSelected == true && colorCodeLabel.text?.isEmpty == false{
                return
            }
            
            let data = iconImage.jpegData(compressionQuality: 1.0)
            self.sendProfileImageData(data: data!, iconOrHeader: "icon")
            let communityRef = database.collection("communities").document(community.communityID)
            communityRef.setData([
                "communityName": communityName,
                "communityDescription": communityDescription,
                "communityColor": selectColorCode!
            ], merge: true)
            
            //もしヘッダーに画像が入っていたら
            if let headerImage = communityHeaderImageView.image{
                let data = headerImage.jpegData(compressionQuality: 1.0)
                self.sendProfileImageData(data: data!, iconOrHeader: "header")
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func redButtonTapped(_ sender: Any) {
        redButton.layer.borderColor = UIColor.yellow.cgColor
        redButton.isSelected = true
        selectColorCode = "#EF7779"
        if yellowButton.isSelected == true{
            yellowButton.isSelected = false
            yellowButton.layer.borderColor = UIColor.black.cgColor
        }
        if orangeButton.isSelected == true{
            orangeButton.isSelected = false
            orangeButton.layer.borderColor = UIColor.black.cgColor
        }
        if blueButton.isSelected == true{
            blueButton.isSelected = false
            blueButton.layer.borderColor = UIColor.black.cgColor
        }
        if greenButton.isSelected == true{
            greenButton.isSelected = false
            greenButton.layer.borderColor = UIColor.black.cgColor
        }
        if customButton.isSelected == true{
            customButton.isSelected = false
            customButton.layer.borderColor = UIColor.black.cgColor
            colorCodeLabel.isHidden = true
            selectColorCodeLabel.isHidden = true
        }
    }
    @IBAction func yellowButtonTapped(_ sender: Any) {
        yellowButton.layer.borderColor = UIColor.yellow.cgColor
        yellowButton.isSelected = true
        selectColorCode = "#FEF77C"
        if redButton.isSelected == true{
            redButton.isSelected = false
            redButton.layer.borderColor = UIColor.black.cgColor
        }
        if orangeButton.isSelected == true{
            orangeButton.isSelected = false
            orangeButton.layer.borderColor = UIColor.black.cgColor
        }
        if blueButton.isSelected == true{
            blueButton.isSelected = false
            blueButton.layer.borderColor = UIColor.black.cgColor
        }
        if greenButton.isSelected == true{
            greenButton.isSelected = false
            greenButton.layer.borderColor = UIColor.black.cgColor
        }
        if customButton.isSelected == true{
            customButton.isSelected = false
            customButton.layer.borderColor = UIColor.black.cgColor
            colorCodeLabel.isHidden = true
            selectColorCodeLabel.isHidden = true
        }
    }
    @IBAction func orangeButtonTapped(_ sender: Any) {
        orangeButton.layer.borderColor = UIColor.yellow.cgColor
        orangeButton.isSelected = true
        selectColorCode = "#F7A654"
        if redButton.isSelected == true{
            redButton.isSelected = false
            redButton.layer.borderColor = UIColor.black.cgColor
        }
        if yellowButton.isSelected == true{
            yellowButton.isSelected = false
            yellowButton.layer.borderColor = UIColor.black.cgColor
        }
        if blueButton.isSelected == true{
            blueButton.isSelected = false
            blueButton.layer.borderColor = UIColor.black.cgColor
        }
        if greenButton.isSelected == true{
            greenButton.isSelected = false
            greenButton.layer.borderColor = UIColor.black.cgColor
        }
        if customButton.isSelected == true{
            customButton.isSelected = false
            customButton.layer.borderColor = UIColor.black.cgColor
            colorCodeLabel.isHidden = true
            selectColorCodeLabel.isHidden = true
        }
    }
    @IBAction func blueButtonTapped(_ sender: Any) {
        blueButton.layer.borderColor = UIColor.yellow.cgColor
        blueButton.isSelected = true
        selectColorCode = "#B9EAED"
        if redButton.isSelected == true{
            redButton.isSelected = false
            redButton.layer.borderColor = UIColor.black.cgColor
        }
        if yellowButton.isSelected == true{
            yellowButton.isSelected = false
            yellowButton.layer.borderColor = UIColor.black.cgColor
        }
        if orangeButton.isSelected == true{
            orangeButton.isSelected = false
            orangeButton.layer.borderColor = UIColor.black.cgColor
        }
        if greenButton.isSelected == true{
            greenButton.isSelected = false
            greenButton.layer.borderColor = UIColor.black.cgColor
        }
        if customButton.isSelected == true{
            customButton.isSelected = false
            customButton.layer.borderColor = UIColor.black.cgColor
            colorCodeLabel.isHidden = true
            selectColorCodeLabel.isHidden = true
        }
    }
    @IBAction func greenButtonTapped(_ sender: Any) {
        greenButton.layer.borderColor = UIColor.yellow.cgColor
        greenButton.isSelected = true
        selectColorCode = "#99FF94"
        if redButton.isSelected == true{
            redButton.isSelected = false
            redButton.layer.borderColor = UIColor.black.cgColor
        }
        if yellowButton.isSelected == true{
            yellowButton.isSelected = false
            yellowButton.layer.borderColor = UIColor.black.cgColor
        }
        if orangeButton.isSelected == true{
            orangeButton.isSelected = false
            orangeButton.layer.borderColor = UIColor.black.cgColor
        }
        if blueButton.isSelected == true{
            blueButton.isSelected = false
            blueButton.layer.borderColor = UIColor.black.cgColor
        }
        if customButton.isSelected == true{
            customButton.isSelected = false
            customButton.layer.borderColor = UIColor.black.cgColor
            colorCodeLabel.isHidden = true
            selectColorCodeLabel.isHidden = true
        }
    }
    @IBAction func customButtonTapped(_ sender: Any) {
        customButton.layer.borderColor = UIColor.yellow.cgColor
        customButton.isSelected = true
        selectColorCode = "#D0C4FC"
        colorCodeLabel.isHidden = false
        selectColorCodeLabel.isHidden = false
        if redButton.isSelected == true{
            redButton.isSelected = false
            redButton.layer.borderColor = UIColor.black.cgColor
        }
        if yellowButton.isSelected == true{
            yellowButton.isSelected = false
            yellowButton.layer.borderColor = UIColor.black.cgColor
        }
        if orangeButton.isSelected == true{
            orangeButton.isSelected = false
            orangeButton.layer.borderColor = UIColor.black.cgColor
        }
        if blueButton.isSelected == true{
            blueButton.isSelected = false
            blueButton.layer.borderColor = UIColor.black.cgColor
        }
        if greenButton.isSelected == true{
            greenButton.isSelected = false
            greenButton.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    @IBAction func tapHeaderImageView(_ sender: Any) {
        iconOrHeader = "header"
        showHeaderAlert()
        print("headerです")
    }
    
    @IBAction func tapIconImageView(_ sender: Any) {
        iconOrHeader = "icon"
        showIconAlert()
        print("アイコンです")
    }
    
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
                
                let selectedImage = info[.originalImage] as! UIImage
                //アイコンかヘッダーかで適応先を変える
                switch iconOrHeader{
                case "header":
                    communityHeaderImageView.image = selectedImage
                case "icon":
                    communityIconImageView.image = selectedImage
                default:
                    return
                }
                picker.dismiss(animated: true, completion: nil)
            }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //headerアラート
    func showHeaderAlert(){
        print("アラート呼ばれた")
        
        let alertController = UIAlertController(title: "ヘッダーを選択", message: "どちらを使用しますか?", preferredStyle: .actionSheet)
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
        print("プレゼント")
        self.present(alertController, animated: true, completion: nil)
    }
    //iconアラート
    func showIconAlert(){
        print("アラート呼ばれた")
        
        let alertController = UIAlertController(title: "アイコンを選択", message: "どちらを使用しますか?", preferredStyle: .actionSheet)
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
    
    func sendProfileImageData(data:Data, iconOrHeader: String){
        
        let image = UIImage(data: data)
        let profileImage = image?.jpegData(compressionQuality: 0.1)
        var storageRef = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("communities")
        //アイコンかヘッダーかで処理を分けるため
        if iconOrHeader == "icon"{
            storageRef = storageRef.child(community.communityID).child("icon.jpg")
        }else if iconOrHeader == "header"{
            storageRef = storageRef.child(community.communityID).child("header.jpg")
        }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        if profileImage != nil {
            
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
                        
                        if iconOrHeader == "icon"{
                            //コミュニティ名などの前にアイコンのurlをstring更新する
                            self.database.collection("communities").document(self.community.communityID).updateData([
                                "communityIcon": url!.absoluteString,
                            ])
                            
                            self.database.collection("users").document(self.me.userID).updateData([
                                "communities": [
                                    self.community.communityID:[
                                        "communityIcon": url?.absoluteString
                                    ]
                                ]
                            ])
                        }else if iconOrHeader == "header"{
                            self.database.collection("communities").document(self.community.communityID).updateData([
                                "communityheader": url!.absoluteString,
                            ])
                            
                            self.database.collection("users").document(self.me.userID).updateData([
                                "communities": [
                                    self.community.communityID:[
                                        "communityheader": url?.absoluteString
                                    ]
                                ]
                            ])
                        }
                    }
                    //ここちょっと自信がないです
                    changeRequest?.commitChanges(completion: nil)
                    
                })
            }
            
        }
    }
    
    
}
