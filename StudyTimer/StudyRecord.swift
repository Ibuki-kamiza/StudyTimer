import Foundation

struct StudyRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var materialName: String
    var date: Date
    var minutes: Int
}

