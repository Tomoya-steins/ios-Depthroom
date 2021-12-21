//
//  loginViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/02.
//

import UIKit
import Firebase

class loginViewController: UIViewController {

    var me: AppUser!
    var auth: Auth!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var remindPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        loginAndRemindButtonSet()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func loginAndRemindButtonSet(){
        //ログインボタン
        loginButton.backgroundColor = UIColor(displayP3Red: 79/255, green: 172/255,     blue: 254/255,alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        loginButton.layer.cornerRadius = 15.0
        loginButton.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        loginButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        loginButton.layer.shadowOpacity = 0.3
        loginButton.layer.shadowRadius = 5
        //レマインドボタン
        remindPasswordButton.backgroundColor = UIColor.white
        remindPasswordButton.setTitleColor( UIColor(displayP3Red: 79/255, green: 172/255, blue: 254/255,alpha: 1.0), for: .normal)
        remindPasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        remindPasswordButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        remindPasswordButton.layer.cornerRadius = 15.0
        remindPasswordButton.layer.borderColor =  UIColor(displayP3Red: 79/255, green: 172/255, blue: 254/255,alpha: 1.0).cgColor
        remindPasswordButton.layer.borderWidth = 2
    }
    
    @IBAction func loginButton(_ sender: Any) {
        
        if emailTextField.text?.isEmpty != true && passwordTextField.text?.isEmpty != true{
            
            auth.signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { [weak self] result, error in
                    guard let self = self else { return }
                if let user = result?.user {
                    self.performSegue(withIdentifier: "tabBar", sender: user)
                }
                self.showErrorIfNeeded(error)
            }
        }
    }
    
    @IBAction func remindPassword(_ sender: Any) {
        let remindPasswordAlert = UIAlertController(title: "パスワードをリセット", message: "メールアドレスを入力してください", preferredStyle: .alert)
        remindPasswordAlert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        remindPasswordAlert.addAction(UIAlertAction(title: "リセット", style: .default, handler: { (action) in
            let resetEmail = remindPasswordAlert.textFields?.first?.text
            Auth.auth().sendPasswordReset(withEmail: resetEmail!, completion: { (error) in
                DispatchQueue.main.async {
                    if error != nil {
                        let alert = UIAlertController(title: "メールを送信しました。", message: "パスワードの再設定を行ってください。", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }
                        alert.addAction(ok)
                    } else {
                        let alert = UIAlertController(title: "エラー", message: "このメールアドレスは登録されていません。", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }
                        alert.addAction(ok)
                    }
                }
            })
        }))
        remindPasswordAlert.addTextField { (textField) in
            textField.placeholder = "test@gmail.com"
        }
        self.present(remindPasswordAlert, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tabBar"{
          let nextViewController = segue.destination as! tabBarViewController
          let user = sender as! User
            nextViewController.me = AppUser(data: ["userID": user.uid])
        }
    }
    
    //エラーに関する記述
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error) // エラーメッセージを取得
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func errorMessage(of error: Error) -> String {
        var message = "エラーが発生しました"
        guard let errcd = AuthErrorCode(rawValue: (error as NSError).code) else {
            return message
        }
        
        switch errcd {
        case .networkError: message = "ネットワークに接続できません"
        case .userNotFound: message = "ユーザが見つかりません"
        case .invalidEmail: message = "不正なメールアドレスです"
        case .wrongPassword: message = "入力した認証情報でサインインできません"
        case .userDisabled: message = "このアカウントは無効です"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
        
}

extension loginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
    
