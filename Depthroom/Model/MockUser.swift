//
//  MockUser.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/11/06.
//

import Foundation
import MessageKit

struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
}
