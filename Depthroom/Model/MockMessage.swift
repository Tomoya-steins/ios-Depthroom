import MessageKit
import UIKit
import InputBarAccessoryView
import Firebase

private struct ImageMediaItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }

    init(imageURL: URL) {
        self.url = imageURL
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage(imageLiteralResourceName: "image_message_placeholder")
    }
}

internal struct MockMessage: MessageType {
    
    var messageId: String
    var sender: SenderType {
        return user
    }
    var user: MockUser
    var sentDate: Date
    //MessageKindはテキストや画像や動画絵文字の区別
    var kind: MessageKind
    
    private init(kind: MessageKind, sender: MockUser, messageId: String, date: Date) {
        self.kind = kind
        self.user = sender
        self.messageId = messageId
        self.sentDate = date
    }
    
    //kind によって、テキストか画像か動画かを見分ける
    init(text: String, sender: MockUser, messageId: String, date: Date) {
        self.init(kind: .text(text), sender: sender, messageId: messageId, date: date)
    }
    
    init(attributedText: NSAttributedString, sender: MockUser, messageId: String, date: Date) {
        self.init(kind: .attributedText(attributedText), sender: sender, messageId: messageId, date: date)
    }
    
    init(image: UIImage, sender: MockUser, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .photo(mediaItem), sender: sender, messageId: messageId, date: date)
    }
    
    init(imageURL: URL, sender: MockUser, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(imageURL: imageURL)
        self.init(kind: .photo(mediaItem), sender: sender, messageId: messageId, date: date)
    }
}
