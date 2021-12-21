//
//  Room.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/08.
//

import Foundation
import Firebase

struct Room {
    let roomID: String!
    let roomName: String!
    let owner: [String:Any]!
    let createdAt: Timestamp!
    let updatedAt: Timestamp!
    //let visible: Bool!
    let state: String!
    let invitations: [String:Any]!
    let members: [String:Any]!
    let recentMessage: [String:Any]!
    let tags: [String:Any]!
    let community: [String:Any]!



    init(data: [String: Any]) {
        roomID = data["roomID"] as? String
        roomName = data["roomName"] as? String
        owner = data["owner"] as? [String:Any]
        createdAt = data["createdAt"] as? Timestamp
        updatedAt = data["updatedAt"] as? Timestamp
        //visible = data["visible"] as? Bool
        state = data["state"] as? String
        invitations = data["invitations"] as? [String:Any]
        members = data["members"] as? [String:Any]
        recentMessage = data["recentMessage"] as? [String:Any]
        tags = data["tags"] as? [String:Any]
        community = data["community"] as? [String:Any]
    }
}
