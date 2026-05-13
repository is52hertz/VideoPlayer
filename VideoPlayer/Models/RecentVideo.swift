import Foundation
import SwiftData

@Model
final class RecentVideo {
    var id: UUID
    var url: URL
    var title: String
    var lastOpened: Date
    
    init(id: UUID = UUID(), url: URL, title: String, lastOpened: Date = Date()) {
        self.id = id
        self.url = url
        self.title = title
        self.lastOpened = lastOpened
    }
}
