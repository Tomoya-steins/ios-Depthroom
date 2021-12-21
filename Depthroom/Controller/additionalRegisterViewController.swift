//
//  additionalRegisterViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import UIKit
import Firebase

class additionalRegisterViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var auth: Auth!
    var me: AppUser!
    var database: Firestore!
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var additionalRegisterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        nameTextField.delegate = self
        additionalRegisterButtonSet()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //ユーザネームをすでに登録していれば、遷移する
        let userNameRef = database.collection("users").document(me.userID)
        userNameRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.performSegue(withIdentifier: "tabBar", sender: self.me)
            }
        }
    }
    
    func additionalRegisterButtonSet(){
        additionalRegisterButton.backgroundColor = UIColor(hex: "#FF6A6A")
        additionalRegisterButton.setTitleColor(.white, for: .normal)
        additionalRegisterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        additionalRegisterButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        additionalRegisterButton.layer.cornerRadius = 15.0
        additionalRegisterButton.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        additionalRegisterButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        additionalRegisterButton.layer.shadowOpacity = 0.3
        additionalRegisterButton.layer.shadowRadius = 5
    }
    
    @IBAction func additionalRegister(_ sender: Any) {
        
            if nameTextField.text?.isEmpty != true, let image = profileImageView.image {
                
                let newUserName = nameTextField.text!
                //非同期処理に対応
                let dispatchGroup = DispatchGroup()
                let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
                dispatchQueue.async(group: dispatchGroup) {
                    //プロフィール画像を登録
                    let data = image.jpegData(compressionQuality: 1.0)
                    self.sendProfileImageData(data: data!)
                }
                
                //ユーザネームとIDを登録
                //事前にアイコンを保存しているため、set ではなく update
                //登録時は全員非鍵アカウントであるので、lockedはfalse
                database.collection("users").document(me.userID).setData([
                    "userID": me.userID!,
                    "userName": newUserName,
                    "locked": false
                ], merge: true)
                
                dispatchGroup.notify(queue: .main){
                    self.performSegue(withIdentifier: "tabBar", sender: self.me)
                }
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tabBar"{
            let nextViewController = segue.destination as! tabBarViewController
            nextViewController.me = me
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
                profileImageView.image = selectedImage
                picker.dismiss(animated: true, completion: nil)
            
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
    
    func sendProfileImageData(data:Data){
        
        let image = UIImage(data: data)
        let profileImage = image?.jpegData(compressionQuality: 0.1)
        
//        let imageRef = Storage.storage().reference().child("profileImage")
        //let storageRef = Storage.storage().reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child("profileImage").child("\(me.userID!).jpg")
        let storageRef = Storage.storage().reference(forURL: "gs://depthroom-ios-21786.appspot.com").child("users").child(me.userID).child("icon.jpg")
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
                        
                        //名前などの前にアイコンのurlをstringで保存する
                        self.database.collection("users").document(self.me.userID).setData([
                            "userIcon": url!.absoluteString
                        ],merge: true)
                    }
                    //ここちょっと自信がないです
                    changeRequest?.commitChanges(completion: nil)
                    
                })
            }
            
        }
    }
}

extension additionalRegisterViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
