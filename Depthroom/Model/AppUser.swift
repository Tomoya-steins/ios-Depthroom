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
    let userDescription: String!
    let userName: String!
    let follow: [String:Any]!
    let follower: [String:Any]!
    let clips: [String:Any]!
    let communities: [String:Any]!
    let userIcon: String!
    let blocked: [String:Any]!
    let locked: Bool!
    
    init(data: [String:Any]) {
        
        userID = data["userID"] as? String
        userDescription = data["userDescription"] as? String
        userName = data["userName"] as? String
        follow = data["follow"] as? [String:Any]
        follower = data["follower"] as? [String:Any]
        userIcon = data["userIcon"] as? String
        clips = data["clips"] as? [String:Any]
        communities = data["communities"] as? [String:Any]
        blocked = data["blocked"] as? [String:Any]
        locked = data["locked"] as? Bool
    }
}
