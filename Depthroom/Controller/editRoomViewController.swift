//
//  editRoomViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/10.
//

import UIKit
import Firebase

class editRoomViewController: UIViewController {

    var me: AppUser!
    var room: Room!
    var database: Firestore!
    @IBOutlet weak var roomNameLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ここまでルームについてfireStoreで問い合わせてなかったので
        database.collection("rooms").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.room = Room(data: data)
                self.roomNameLabel.text = self.room.roomName
            }
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editComplete(_ sender: Any) {
        if roomNameLabel.text != nil{
            let updateRoom = database.collection("rooms").document(room.roomID)
            updateRoom.updateData([
                "roomName": roomNameLabel.text!
            ])
            dismiss(animated: true, completion: nil)
        }
    }
    
}
