//
//  GroupChat.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/16.
//

import Foundation
import Firebase

struct GroupChat {
    let body: String!
    let messageID: String!
    let from: String!
    let timeStamp: Timestamp!
    let type: String!

    init(data: [String: Any]) {
        body = data["body"] as? String
        messageID = data["messageID"] as? String
        from = data["from"] as? String
        timeStamp = data["timeStamp"] as? Timestamp
        type = data["type"] as? String
    }
}
