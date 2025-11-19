import Foundation
import UserNotifications
import SwiftUI
import Combine

// 教材1件ぶん
struct StudyMaterial: Identifiable {
    let id = UUID()
    let title: String
    let finishedAt: Date
    let comment: String
}

class StudyStore: ObservableObject {

    // MARK: - プロフィール

    @Published var profileName: String = "なまえ さん"
    @Published var profileImageData: Data? = nil
    @Published var targetSchool: String = "〇〇高校"
    @Published var targetQualifications: String = ""

    // ★タイマー背景に使う画像（プロフィールと同じでも別でもOK）
    @Published var timerBackgroundImageData: Data? = nil

    // MARK: - 目標（分単位で保持）

    @Published var dailyGoalMinutes: Int   = 120        // 毎日
    @Published var weeklyGoalMinutes: Int  = 10 * 60    // 週
    @Published var monthlyGoalMinutes: Int = 40 * 60    // 月

    // MARK: - 学習記録

    /// その月の日にちごとの学習時間（分）
    @Published var studyMinutesByDay: [Int: Int] = [:]

    /// 追加した教材一覧
    @Published var materials: [StudyMaterial] = []

    // ===== 以下、addRecord / addMaterial / 通知のメソッドは今まで通り =====
    // （あなたが最後に貼ってくれた StudyStore のメソッド部分はそのまま残してOK）
}

