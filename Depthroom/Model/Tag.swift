//
//  Tag.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/10/22.
//

import Foundation
import Firebase

struct Tag {
    let tagID: String!
    let tagName: String!

    init(data: [String: Any]) {
        tagID = data["tagID"] as? String
        tagName = data["tagName"] as? String
    }
}
