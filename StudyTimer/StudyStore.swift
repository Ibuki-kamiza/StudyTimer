import Foundation
import UserNotifications
import SwiftUI
import Combine

// 既存：教材1件分（コメントなど用途があるので残す）
struct StudyMaterial: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var finishedAt: Date
    var comment: String

    init(id: UUID = UUID(), title: String, finishedAt: Date = Date(), comment: String = "") {
        self.id = id
        self.title = title
        self.finishedAt = finishedAt
        self.comment = comment
    }
}

@MainActor
final class StudyStore: ObservableObject {

    // MARK: - プロフィール

    @Published var profileName: String = "なまえ さん"
    @Published var profileImageData: Data? = nil { didSet { saveProfile() } }
    @Published var targetSchool: String = "〇〇高校" { didSet { saveProfile() } }
    @Published var targetQualifications: String = "" { didSet { saveProfile() } }

    // MARK: - ポモドーロ背景（時間帯ごと）
    // ※ ここが今回の追加：5枠（4-8 / 9-11 / 12-15 / 16-19 / 20-3）
    @Published var pomodoroBgDawnData: Data? = nil { didSet { savePomodoroBackgrounds() } }      // 4-8
    @Published var pomodoroBgMorningData: Data? = nil { didSet { savePomodoroBackgrounds() } }   // 9-11
    @Published var pomodoroBgNoonData: Data? = nil { didSet { savePomodoroBackgrounds() } }      // 12-15
    @Published var pomodoroBgEveningData: Data? = nil { didSet { savePomodoroBackgrounds() } }   // 16-19
    @Published var pomodoroBgNightData: Data? = nil { didSet { savePomodoroBackgrounds() } }     // 20-3

    // 既存：タイマー背景に使う画像（残すなら残してOK / 使わないなら後で削除OK）
    @Published var timerBackgroundImageData: Data? = nil { didSet { saveProfile() } }

    // MARK: - 大事な日（HomeView / ProfileEditSheet で使用）

    @Published var importantTitle: String = "" { didSet { saveProfile() } }
    @Published var importantDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date() { didSet { saveProfile() } }

    // MARK: - 目標（分単位で保持）

    @Published var dailyGoalMinutes: Int   = 120        { didSet { saveProfile() } } // 毎日（2時間）
    @Published var weeklyGoalMinutes: Int  = 10 * 60    { didSet { saveProfile() } } // 週（10時間）
    @Published var monthlyGoalMinutes: Int = 40 * 60    { didSet { saveProfile() } } // 月（40時間）

    // MARK: - 学習記録（ここがマスター）

    //学習記録の本体（教材名・日付・分数）
    @Published var records: [StudyRecord] = [] {
        didSet { saveRecords() }
    }

    //教材名履歴（サジェスト用：重複なし・最新順）
    @Published private(set) var materialHistory: [String] = [] {
        didSet { saveMaterialHistory() }
    }

    // 既存：教材一覧（コメント用途などがあるなら残せる）
    @Published var materials: [StudyMaterial] = [] {
        didSet { saveMaterials() }
    }

    // MARK: - 初期化（保存データ読込）

    init() {
        loadProfile()
        loadPomodoroBackgrounds()

        loadRecords()
        loadMaterialHistory()
        loadMaterials()
    }

    // MARK: - 時間帯背景の取得/設定

    func pomodoroBackgroundData(for slot: TimeSlot) -> Data? {
        switch slot {
        case .dawn: return pomodoroBgDawnData
        case .morning: return pomodoroBgMorningData
        case .noon: return pomodoroBgNoonData
        case .evening: return pomodoroBgEveningData
        case .night: return pomodoroBgNightData
        }
    }

    func setPomodoroBackgroundData(_ data: Data?, for slot: TimeSlot) {
        switch slot {
        case .dawn: pomodoroBgDawnData = data
        case .morning: pomodoroBgMorningData = data
        case .noon: pomodoroBgNoonData = data
        case .evening: pomodoroBgEveningData = data
        case .night: pomodoroBgNightData = data
        }
    }

    // MARK: - 集計（HomeView / ProfileView が使う）

    /// 「今月」の日ごとの学習時間（分）
    var studyMinutesByDay: [Int: Int] {
        let cal = Calendar.current
        let now = Date()
        let ym = cal.dateComponents([.year, .month], from: now)

        return records.reduce(into: [Int: Int]()) { dict, r in
            let rc = cal.dateComponents([.year, .month, .day], from: r.date)
            guard rc.year == ym.year, rc.month == ym.month else { return }
            let day = rc.day ?? 0
            dict[day, default: 0] += r.minutes
        }
    }

    /// 今日の学習分数（records から計算）
    var todayMinutes: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return records.reduce(0) { sum, r in
            cal.isDate(r.date, inSameDayAs: today) ? (sum + r.minutes) : sum
        }
    }

    /// 今日の達成率（0.0〜1.0）
    var todayProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(Double(todayMinutes) / Double(dailyGoalMinutes), 1.0)
    }

    /// 全期間の合計（プロフィール用など）
    var totalMinutesAllTime: Int {
        records.reduce(0) { $0 + $1.minutes }
    }

    // MARK: - 記録追加（◯時間◯分入力から呼ぶ）

    func addRecord(materialName: String, date: Date = Date(), hours: Int, minutes: Int) {
        let name = materialName.trimmingCharacters(in: .whitespacesAndNewlines)
        let total = max(0, hours * 60 + minutes)
        guard !name.isEmpty, total > 0 else { return }

        records.insert(StudyRecord(materialName: name, date: date, minutes: total), at: 0)
        upsertMaterialHistory(name)
    }

    func addRecord(materialName: String, date: Date = Date(), totalMinutes: Int) {
        let name = materialName.trimmingCharacters(in: .whitespacesAndNewlines)
        let total = max(0, totalMinutes)
        guard !name.isEmpty, total > 0 else { return }

        records.insert(StudyRecord(materialName: name, date: date, minutes: total), at: 0)
        upsertMaterialHistory(name)
    }

    func updateRecord(_ record: StudyRecord) {
        guard record.minutes > 0 else { return }
        if let i = records.firstIndex(where: { $0.id == record.id }) {
            records[i] = record
            upsertMaterialHistory(record.materialName)
        }
    }

    func deleteRecord(_ record: StudyRecord) {
        records.removeAll { $0.id == record.id }
    }

    private func upsertMaterialHistory(_ name: String) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        materialHistory.removeAll { $0.caseInsensitiveCompare(n) == .orderedSame }
        materialHistory.insert(n, at: 0)
        if materialHistory.count > 30 {
            materialHistory = Array(materialHistory.prefix(30))
        }
    }

    // MARK: - 既存API（互換）

    func addStudyMinutes(_ minutes: Int, date: Date = Date()) {
        guard minutes > 0 else { return }
        addRecord(materialName: "学習", date: date, totalMinutes: minutes)
    }

    func addMaterial(title: String, comment: String = "", finishedAt: Date = Date()) {
        let material = StudyMaterial(title: title, finishedAt: finishedAt, comment: comment)
        materials.insert(material, at: 0)
    }

    func removeMaterial(_ material: StudyMaterial) {
        materials.removeAll { $0.id == material.id }
    }

    // MARK: - 通知（目標リマインド）

    func scheduleGoalNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["goal_reminder"])

        var date = DateComponents()
        date.hour = 21
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "今日の学習目標"
        content.body = "今日の目標、あと少し！タイマーを回してみよう。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "goal_reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - 永続化（UserDefaults）

    private let recordsKey = "study_records_v1"
    private let materialHistoryKey = "material_history_v1"
    private let materialsKey = "materials_v1"

    // プロフィール系
    private let profileKey = "profile_v1"

    //ポモドーロ背景（時間帯ごと）
    private let pomodoroBgKey = "pomodoro_bgs_v1"

    private struct ProfilePersist: Codable {
        var profileName: String
        var profileImageBase64: String?
        var targetSchool: String
        var targetQualifications: String
        var importantTitle: String
        var importantDate: Date
        var dailyGoalMinutes: Int
        var weeklyGoalMinutes: Int
        var monthlyGoalMinutes: Int
        var timerBackgroundBase64: String?
    }

    private struct PomodoroBgsPersist: Codable {
        var dawn: String?
        var morning: String?
        var noon: String?
        var evening: String?
        var night: String?
    }

    private func saveProfile() {
        let obj = ProfilePersist(
            profileName: profileName,
            profileImageBase64: profileImageData?.base64EncodedString(),
            targetSchool: targetSchool,
            targetQualifications: targetQualifications,
            importantTitle: importantTitle,
            importantDate: importantDate,
            dailyGoalMinutes: dailyGoalMinutes,
            weeklyGoalMinutes: weeklyGoalMinutes,
            monthlyGoalMinutes: monthlyGoalMinutes,
            timerBackgroundBase64: timerBackgroundImageData?.base64EncodedString()
        )

        if let data = try? JSONEncoder().encode(obj) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let obj = try? JSONDecoder().decode(ProfilePersist.self, from: data)
        else { return }

        profileName = obj.profileName
        profileImageData = obj.profileImageBase64.flatMap { Data(base64Encoded: $0) }
        targetSchool = obj.targetSchool
        targetQualifications = obj.targetQualifications
        importantTitle = obj.importantTitle
        importantDate = obj.importantDate
        dailyGoalMinutes = obj.dailyGoalMinutes
        weeklyGoalMinutes = obj.weeklyGoalMinutes
        monthlyGoalMinutes = obj.monthlyGoalMinutes
        timerBackgroundImageData = obj.timerBackgroundBase64.flatMap { Data(base64Encoded: $0) }
    }

    private func savePomodoroBackgrounds() {
        let obj = PomodoroBgsPersist(
            dawn: pomodoroBgDawnData?.base64EncodedString(),
            morning: pomodoroBgMorningData?.base64EncodedString(),
            noon: pomodoroBgNoonData?.base64EncodedString(),
            evening: pomodoroBgEveningData?.base64EncodedString(),
            night: pomodoroBgNightData?.base64EncodedString()
        )
        if let data = try? JSONEncoder().encode(obj) {
            UserDefaults.standard.set(data, forKey: pomodoroBgKey)
        }
    }

    private func loadPomodoroBackgrounds() {
        guard let data = UserDefaults.standard.data(forKey: pomodoroBgKey),
              let obj = try? JSONDecoder().decode(PomodoroBgsPersist.self, from: data)
        else { return }

        pomodoroBgDawnData = obj.dawn.flatMap { Data(base64Encoded: $0) }
        pomodoroBgMorningData = obj.morning.flatMap { Data(base64Encoded: $0) }
        pomodoroBgNoonData = obj.noon.flatMap { Data(base64Encoded: $0) }
        pomodoroBgEveningData = obj.evening.flatMap { Data(base64Encoded: $0) }
        pomodoroBgNightData = obj.night.flatMap { Data(base64Encoded: $0) }
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey),
              let saved = try? JSONDecoder().decode([StudyRecord].self, from: data)
        else { return }
        records = saved
    }

    private func saveMaterialHistory() {
        if let data = try? JSONEncoder().encode(materialHistory) {
            UserDefaults.standard.set(data, forKey: materialHistoryKey)
        }
    }

    private func loadMaterialHistory() {
        guard let data = UserDefaults.standard.data(forKey: materialHistoryKey),
              let saved = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        materialHistory = saved
    }

    private func saveMaterials() {
        if let data = try? JSONEncoder().encode(materials) {
            UserDefaults.standard.set(data, forKey: materialsKey)
        }
    }

    private func loadMaterials() {
        guard let data = UserDefaults.standard.data(forKey: materialsKey),
              let saved = try? JSONDecoder().decode([StudyMaterial].self, from: data)
        else { return }
        materials = saved
    }
}

