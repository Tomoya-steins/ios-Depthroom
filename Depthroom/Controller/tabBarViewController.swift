//
//  tabBarViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/29.
//

import UIKit

class tabBarViewController: UITabBarController {

    var me: AppUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let viewControllers  = self.viewControllers,
           viewControllers.count >= 1{
            
            //各タブにユーザIDを与えていく
            if let roomsNavigationController = viewControllers[0] as? UINavigationController{
                for controller in roomsNavigationController.viewControllers {
                    if let myRoomsViewController = controller as? myRoomsViewController {
                        myRoomsViewController.me = me
                    }
                }
            }
            if let searchNavigationController = viewControllers[1] as? UINavigationController{
                for controller in searchNavigationController.viewControllers{
                    if let searchViewController = controller as? searchViewController{
                        searchViewController.me = me
                    }
                }
            }
            if let noticeNavigationController = viewControllers[2] as? UINavigationController{
                for controller in noticeNavigationController.viewControllers{
                    if let noticeViewController = controller as? noticeViewController{
                        noticeViewController.me = me
                    }
                }
            }
            if let myPageNavigationController = viewControllers[3] as? UINavigationController{
                for controller in myPageNavigationController.viewControllers{
                    if let myPageViewController = controller as? myPageViewController{
                        myPageViewController.user = me
                    }
                }
            }
        }
    }
}
