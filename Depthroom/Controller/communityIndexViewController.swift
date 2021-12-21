//
//  communityIndexViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/12.
//

import UIKit
import Firebase
import FirebaseStorageUI

class communityIndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    var myCommunityArray: [Community] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "communityShow"{
            let nextViewController = segue.destination as! communityShowViewController
            //コミュニティのIDとオーナーのIDのみ値を渡す
            //他の情報は変更される恐れがあるため
            nextViewController.community = Community(data: ["communityID": myCommunityArray[sender as! Int].communityID!, "owner": myCommunityArray[sender as! Int].owner!])
            nextViewController.me = me
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "communityShow", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myCommunityArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = myCommunityArray[indexPath.row].communityName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //適当に
        return 75
    }
}
