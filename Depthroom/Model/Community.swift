import Foundation
import Firebase

struct Community {
    let communityID: String!
    let communityName: String!
    let communityDescription: String!
    let owner: [String:Any]!
    let createdAt: Timestamp!
    let updatedAt: Timestamp!
    let communityIcon: String!
    let communityHeader: String!
    let members: [String:Any]!
    let communityColor: String!
    let weeklyMembersCount: Int!



    init(data: [String: Any]) {
        communityID = data["communityID"] as? String
        communityName = data["communityName"] as? String
        communityDescription = data["communityDescription"] as? String
        owner = data["owner"] as? [String:Any]
        createdAt = data["createdAt"] as? Timestamp
        updatedAt = data["updatedAt"] as? Timestamp
        communityIcon = data["communityIcon"] as? String
        communityHeader = data["communityHeader"] as? String
        members = data["members"] as? [String:Any]
        communityColor = data["communityColor"] as? String
        weeklyMembersCount = data["weeklyMembersCount"] as? Int
    }
}
