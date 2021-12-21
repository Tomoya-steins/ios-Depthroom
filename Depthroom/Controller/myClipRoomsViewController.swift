//
//  myClipRoomsViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/27.
//

import UIKit

class myClipRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var me: AppUser!
    var myClips: [Room] = []
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "roomCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        if let clips = me.clips{
            myClips = []
            for clip in clips.values{
                let room = Room(data: clip as! [String:Any])
                myClips.append(room)
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "roomChat") as! roomChatViewController
        nextViewController.room = myClips[indexPath.row]
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myClips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCell
        cell.roomNameLabel.text = myClips[indexPath.row].roomName
        //cell.messageLabel.text = ""
        cell.tagLabel.text =  ""
        
        let time = myClips[indexPath.row].updatedAt.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        cell.updatedTimeLabel.text = "\(formatter.string(from: time))"
        
        let owner = AppUser(data: myClips[indexPath.row].owner)
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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
}
