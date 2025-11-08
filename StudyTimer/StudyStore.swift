import Foundation
import SwiftUI
import Combine

class StudyStore: ObservableObject {
    // プロフィール
    @Published var profileName: String = "なとり るか さん"
    @Published var profileImageData: Data? = nil   // 画像は Data で保持しておく

    // 日ごとの学習時間（分）
    @Published var studyMinutesByDay: [Int: Int] = [:]

    // 教材の記録一覧
    @Published var materials: [StudyMaterial] = []

    func addRecord(date: Date, minutes: Int) {
        let day = Calendar.current.component(.day, from: date)
        let current = studyMinutesByDay[day] ?? 0
        studyMinutesByDay[day] = current + minutes
    }

    func addMaterial(title: String, date: Date, comment: String) {
        let item = StudyMaterial(title: title, finishedAt: date, comment: comment)
        materials.insert(item, at: 0)
    }
}

struct StudyMaterial: Identifiable {
    let id = UUID()
    let title: String
    let finishedAt: Date
    let comment: String
}

