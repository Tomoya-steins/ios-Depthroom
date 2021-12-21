//
//  communitySettingViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/12.
//

import UIKit
import Firebase

class communitySettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var auth: Auth!
    var community: Community!
    var me: AppUser!
    var owner: AppUser!
    var communityIndex: [String] = ["通知"]
    var sectionTitle: [String] = []
    var communityOwnerIndex: [String] = ["編集", "退会させる", "コミュニティを削除"]
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "roomSettingIndexCell", bundle: nil), forCellReuseIdentifier: "indexCell")
        tableView.register(UINib(nibName: "roomSettingNoticeCell", bundle: nil), forCellReuseIdentifier: "noticeCell")
        tableView.register(UINib(nibName: "roomSettingNextCell", bundle: nil), forCellReuseIdentifier: "nextCell")
        
        if let data = community.owner{
            let user = AppUser(data: data)
            owner = user
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //今回はナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        //コミュニティのオーナかどうかで配列が変化する
        sectionTitle = []
        if owner.userID == auth.currentUser?.uid{
            sectionTitle = ["コミュニティオプション", "作成者オプション"]
        }else{
            sectionTitle = ["コミュニティオプション"]
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section{
        case 0:
            switch communityIndex[indexPath.row]{
            case "通知":
                return
            default:
                break
            }
        case 1:
            switch communityOwnerIndex[indexPath.row]{
            case "編集":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "editCommunity") as! editCommunityViewController
                nextViewController.me = me
                nextViewController.community = community
                self.present(nextViewController, animated: true, completion: nil)
            case "退会させる":
                let nextViewController = self.storyboard?.instantiateViewController(identifier: "getoutCommunityMember") as! getoutCommunityMemberViewController
                nextViewController.me = me
                nextViewController.community = community
                self.present(nextViewController, animated: true, completion: nil)
            case "コミュニティを削除":
                return
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return communityIndex.count
        case 1:
            return communityOwnerIndex.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section{
        case 0:
            switch communityIndex[indexPath.row]{
            case "通知":
                let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell") as! roomSettingNoticeCell
                cell.roomSettingLabel.text = communityIndex[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        case 1:
            switch communityOwnerIndex[indexPath.row]{
            case "編集":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = communityOwnerIndex[indexPath.row]
                return cell
            case "退会させる":
                let cell = tableView.dequeueReusableCell(withIdentifier: "nextCell") as! roomSettingNextCell
                cell.roomSettingLabel.text = communityOwnerIndex[indexPath.row]
                return cell
            case "コミュニティを削除":
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = communityOwnerIndex[indexPath.row]
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
                cell.roomSettingLabel.text = ""
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "indexCell") as! roomSettingIndexCell
            cell.roomSettingLabel.text = ""
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height/10
    }
}
