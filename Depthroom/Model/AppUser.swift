//
//  AppUser.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import Foundation
import Firebase

struct AppUser {
    
    let userID: String!
    let userProfile: String!
    let userName: String!
    let follow: [String:Any]!
    let follower: [String:Any]!
    
    init(data: [String:Any]) {
        
        userID = data["userID"] as? String
        userProfile = data["userProfile"] as? String
        userName = data["userName"] as? String
        follow = data["follow"] as? [String:Any]
        follower = data["follower"] as? [String:Any]
    }
}
