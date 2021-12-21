//
//  newCommunityViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/10.
//

import UIKit
import Firebase
import FirebaseStorageUI

class newCommunityViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var customButton: UIButton!
    var selectColorCode: String!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var communityNameLabel: UITextField!
    @IBOutlet weak var communityDescriptionLabel: UITextField!
    @IBOutlet weak var colorCodeLabel: UITextField!
    //「テーマカラーを選択」の下に色選択ボタンを置くため
    @IBOutlet weak var selectThemeColorLabel: UILabel!
    @IBOutlet weak var colorCode: UILabel!
    @IBOutlet weak var createCommunityButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        communityNameLabel.delegate = self
        communityDescriptionLabel.delegate = self
        //コミュニティ作成ボタン
        createCommunityButton.backgroundColor = UIColor(displayP3Red: 79/255, green: 172/255,     blue: 254/255,alpha: 1.0)
        createCommunityButton.setTitleColor(.white, for: .normal)
        createCommunityButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        createCommunityButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        createCommunityButton.layer.cornerRadius = 15.0
        createCommunityButton.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        createCommunityButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        createCommunityButton.layer.shadowOpacity = 0.3
        createCommunityButton.layer.shadowRadius = 5
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
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

        colorCodeLabel.isHidden = true
        colorCode.isHidden = true
        //最初は赤が選択されている
        redButton.isSelected = true
        redButton.layer.borderColor = UIColor.yellow.cgColor
        selectColorCode = "#EF7779"
    }
    override func viewDidLayoutSubviews() {
        //作成ボタンのy座標を取得
        //スクロールの高さを決める
        let y = createCommunityButton.frame.origin.y + createCommunityButton.frame.height
        let height = createCommunityButton.frame.height
        //contentView.frame = CGRect(x: contentView.frame.origin.x, y: contentView.frame.origin.y, width: contentView.frame.width, height: y+height+10)
        let sum = y+height+10
        contentView.heightAnchor.constraint(equalToConstant: sum).isActive = true
        scrollView.contentSize = contentView.frame.size
        scrollView.flashScrollIndicators()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createCommunity(_ sender: Any) {
        let communityName = communityNameLabel.text!
        let communityDescription = communityDescriptionLabel.text!
        
        if communityName.isEmpty != true && communityDescription.isEmpty != true && selectColorCode.isEmpty != true{
            //カスタムボタンにコードが入力されていたら、selectColorCodeに代入
            if customButton.isSelected == true && colorCodeLabel.text!.isEmpty != true{
                selectColorCode = colorCodeLabel.text
            }else if customButton.isSelected == true && colorCodeLabel.text?.isEmpty == false{
                return
            }
            
            let saveCommunity = database.collection("communities").document()
            saveCommunity.setData([
                "communityID": saveCommunity.documentID,
                "communityName": communityName,
                "communityDescription": communityDescription,
                "communityColor": selectColorCode!,
                "weeklyMembersCount": 1,
                "owner": [
                    "userID": me.userID,
                    "userName": me.userName,
                    "userIcon": me.userIcon
                ],
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "members": [
                    me.userID: [
                        "userID": me.userID,
                        "userName": me.userName,
                        "userDescription": me.userDescription,
                        "userIcon": me.userIcon
                    ]
                ]
            ]){err in
                if let err = err{
                    print("Error writing document: \(err)")
                }else{
                    print("Document successfully written!")
                }
            }
            
            if let image = imageView.image{
                //プロフィール画像を保存
                let data = image.jpegData(compressionQuality: 1.0)
                sendProfileImageData(data: data!, communityID: saveCommunity.documentID)
            }
            
            //全て終わったら画面遷移
            dismiss(animated: true, completion: nil)
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
            colorCode.isHidden = true
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
            colorCode.isHidden = true
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
            colorCode.isHidden = true
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
            colorCode.isHidden = true
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
            colorCode.isHidden = true
        }
    }
    @IBAction func customButtonTapped(_ sender: Any) {
        customButton.layer.borderColor = UIColor.yellow.cgColor
        customButton.isSelected = true
        selectColorCode = "#D0C4FC"
        colorCodeLabel.isHidden = false
        colorCode.isHidden = false
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
    
    @IBAction func tapImageView(_ sender: Any) {
        showAlert()
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
                imageView.image = selectedImage
                picker.dismiss(animated: true, completion: nil)
            
            }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //アラート
    func showAlert(){
        print("アラート呼ばれた")
        
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
        print("プレゼント")
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func sendProfileImageData(data:Data, communityID: String){
        
        let image = UIImage(data: data)
        let profileImage = image?.jpegData(compressionQuality: 0.1)
        
        //FireStoreからルームのIDを取得、storageのルームのサムネイル画像の名前に使用(roomID)
        //ルーム画像の保存先の指定
        //let storageRef = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("communities").child("communityThumbnail").child("\(communityID).jpg")
        let storageRef = storage.reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("communities").child(communityID).child("icon.jpg")
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
                        
                        //コミュニティ名などの前にアイコンのurlをstringで保存する
                        self.database.collection("communities").document(communityID).setData([
                            "communityIcon": url!.absoluteString,
                        ], merge: true)
                    }
                    //ここちょっと自信がないです
                    changeRequest?.commitChanges(completion: nil)
                    
                })
            }
            
        }
    }
}

extension newCommunityViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
