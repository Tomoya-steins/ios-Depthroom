//
//  newRegisterViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import UIKit
import Firebase

class newRegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var registerAccountButton: UIButton!
    
    var auth: Auth!
    var me: AppUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        registerAccountButtonSet()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func registerAccountButtonSet(){
        registerAccountButton.backgroundColor = UIColor(displayP3Red: 79/255, green: 172/255, blue: 254/255,alpha: 1.0)
        registerAccountButton.setTitleColor(.white, for: .normal)
        registerAccountButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        registerAccountButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        registerAccountButton.layer.cornerRadius = 15.0
        registerAccountButton.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        registerAccountButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        registerAccountButton.layer.shadowOpacity = 0.3
        registerAccountButton.layer.shadowRadius = 5
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addition"{
          let nextViewController = segue.destination as! additionalRegisterViewController
            let user = sender as! User
            nextViewController.me = AppUser(data: ["userID" : user.uid])
        }
      }
    
    @IBAction func registerAccount(_ sender: Any) {
        
        if emailTextField.text?.isEmpty != true && passwordTextField.text?.isEmpty != true{
            
            auth.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { result, error in

                if error == nil, let result = result{

                    self.performSegue(withIdentifier: "addition", sender: result.user)
                }
                self.showErrorIfNeeded(error)
            }
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
            case .emailAlreadyInUse: message = "このメールアドレスは既に使われています"
            case .wrongPassword: message = "入力した認証情報でサインインできません"
            case .userDisabled: message = "このアカウントは無効です"
            case .weakPassword: message = "パスワードが脆弱すぎます"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
}

extension newRegisterViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
