import UIKit
import Firebase

class invitationToRommViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var room:Room!
    var database: Firestore!
    var followerArray: [AppUser] = []
    //followerからルーム関係者を除外した場合、stringにならざるを得ない
    var sinFollowerArray: [AppUser] = []
    //ルーム関係者を配列に入れる
    var invitationArray: [AppUser] = []
    var inviteSelectUser: [AppUser] = []
    var inviteMap: [String:Any] = [:]
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        tableView.delegate = self
        tableView.dataSource = self
        
        
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        inviteSelectUser = []
        invitationArray = []
        followerArray = []
        sinFollowerArray = []
        
        if let follower = me.follower{
            for data in follower.values{
                let user = AppUser(data: data as! [String : Any])
                followerArray.append(user)
            }
        }
        
        database.collection("rooms").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.room = Room(data: data)
                //すでに招待されている・参加者であるユーザをフォロワー一覧から除外する・招待者に限り最後の登録に使うので配列に入れる
                if let invitations = data["invitations"] as? [String:Any]{
                    for invite in invitations.values{
                        let user = AppUser(data: invite as! [String : Any])
                        
                        //自分のフォロワーの中から部屋にすでに招待さえれていない人をsinFollowerArrayに
                        for follower in self.followerArray{
                            if follower.userID != user.userID{
                                self.sinFollowerArray.append(follower)
                            }
                        }
                        self.invitationArray.append(user)
                    }
                }
                if let members = data["members"] as? [String:Any]{
                    for member in members.values{
                        let user = AppUser(data: member as! [String : Any])
                        for follower in self.followerArray{
                            if follower.userID != user.userID{
                                self.sinFollowerArray.append(follower)
                            }
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonToInvitateUser(_ sender: Any) {
        if inviteSelectUser.count > 0{
            
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            dispatchQueue.async(group: dispatchGroup) {
                //既に招待されているユーザが格納されたinvitationArrayをinviteSelectUserに入れる
                self.inviteSelectUser.append(contentsOf: self.invitationArray)
                
                
                for invite in self.inviteSelectUser{
                    self.inviteMap["\(invite.userID!)"] = [
                        "userID": invite.userID,
                        "userName": invite.userName,
                        "userIcon": invite.userIcon
                    ]
                }
                
                let updateRoom = self.database.collection("rooms").document(self.room.roomID)
                updateRoom.updateData([
                    "invitations": self.inviteMap
                ])
            }
            
            dispatchGroup.notify(queue: .main){
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //選択してセルにチェックマークがない場合=選択処理
        if(cell?.accessoryType == UITableViewCell.AccessoryType.none){
            cell?.accessoryType = .checkmark
            inviteSelectUser.append(sinFollowerArray[indexPath.row])
        }else{
            cell?.accessoryType = .none
            if let index = inviteSelectUser.firstIndex(where: { $0.userID == sinFollowerArray[indexPath.row].userID }) {
                inviteSelectUser.remove(at: index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sinFollowerArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
        cell.userNameLabel.text = sinFollowerArray[indexPath.row].userName
        
        if let icon = sinFollowerArray[indexPath.row].userIcon{
            if let photoURL = URL(string: icon){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.profileImageView.image = image
                }
                catch{
                    print("error")
                }
            }
        }
        return cell
    }
    
}
