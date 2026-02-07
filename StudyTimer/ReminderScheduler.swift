import Foundation
import UserNotifications

enum ReminderScheduler {

    private static let identifier = "studyRecordReminder"

    // 権限リクエスト
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // 毎日通知を設定
    static func scheduleDailyRecordReminder(hour: Int, minute: Int) async {

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "学習記録の時間です"
        content.body = "今日の勉強内容を記録しましょう "
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: date,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("通知登録失敗: \(error)")
        }
    }

    // 通知キャンセル
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

