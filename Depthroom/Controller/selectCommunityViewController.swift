import UIKit
import Firebase

class selectCommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var state = "open"
    var myCommunity: [Community] = []
    var database: Firestore!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonToCreateCommunity: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        database = Firestore.firestore()
        tableView.register(UINib(nibName: "communityCreateCell", bundle: nil), forCellReuseIdentifier: "communityCreate")
        //コミュニティ作成ボタン
        buttonToCreateCommunity.backgroundColor = UIColor(hex: "#97B90C")
        buttonToCreateCommunity.setTitleColor(.white, for: .normal)
        buttonToCreateCommunity.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        buttonToCreateCommunity.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        buttonToCreateCommunity.layer.cornerRadius = 15.0
        buttonToCreateCommunity.layer.shadowColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor
        buttonToCreateCommunity.layer.shadowOffset = CGSize(width: 3, height: 3)
        buttonToCreateCommunity.layer.shadowOpacity = 0.3
        buttonToCreateCommunity.layer.shadowRadius = 5
        
        database.collection("communities").whereField("members.\(self.me.userID!).userID", isEqualTo: self.me.userID!).addSnapshotListener { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                self.myCommunity = []
                snapshot.documentChanges.forEach{ diff in
                    if (diff.type == .added){
                        let data = diff.document.data()
                        let community = Community(data: data)
                        self.myCommunity.append(community)
                    }
                    if (diff.type == .modified){
                        print("Modified city: \(diff.document.data())")
                    }
                    if (diff.type == .removed){
                        print("Removed city: \(diff.document.data())")
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
        super.viewWillAppear(animated)
        database.collection("users").document(me.userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.me = AppUser(data: data)
            }
        }
    }
    
    @IBAction func buttonToCreateCommunity(_ sender: Any) {
        performSegue(withIdentifier: "createCommunity", sender: me)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createCommunity"{
            let nextViewcontroller = segue.destination as! newCommunityViewController
            nextViewcontroller.me = me
        }
        if segue.identifier == "selectCommunity"{
            let nextViewController = segue.destination as! newRoomViewController2
            nextViewController.me = me
            nextViewController.state = state
            nextViewController.myCommunity = myCommunity[sender as! Int]
            
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "selectCommunity", sender: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myCommunity.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "communityCreate", for: indexPath) as! communityCreateCell
        
        cell.communityNameLabel.text = myCommunity[indexPath.row].communityName
        
        if let icon = myCommunity[indexPath.row].communityIcon{
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}
