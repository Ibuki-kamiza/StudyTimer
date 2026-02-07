import Foundation
import Combine
@preconcurrency import UserNotifications

@MainActor
final class PomodoroTimerStore: ObservableObject {

    enum Phase: String, Codable {
        case focus
        case `break`
    }

    // MARK: - Public state

    @Published var isRunning: Bool = false
    @Published var phase: Phase = .focus

    /// 現在フェーズの所要時間（秒）
    @Published var durationSeconds: Int = 25 * 60

    /// UI表示用（残り秒）
    @Published var remainingSeconds: Int = 25 * 60

    /// 集中フェーズを何回終えたか（最大4想定）
    @Published var focusCount: Int = 0

    /// 保存される基準時刻
    @Published private(set) var startDate: Date? = nil
    @Published private(set) var endDate: Date? = nil

    // MARK: - Private

    private var tickSource: DispatchSourceTimer?

    private let focusDurationDefault = 25 * 60
    private let breakDurationDefault = 5 * 60

    // MARK: - Public API

    func startFocus() {
        start(durationSeconds: focusDurationDefault, phase: .focus)
    }

    func startBreak() {
        start(durationSeconds: breakDurationDefault, phase: .break)
    }

    func start(durationSeconds: Int? = nil, phase: Phase? = nil) {
        if let d = durationSeconds { self.durationSeconds = d }
        if let p = phase { self.phase = p }

        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(self.durationSeconds))

        self.startDate = now
        self.endDate = end
        self.isRunning = true

        saveState()

        // 通知は「できたら出す」程度にして、失敗してもタイマーは正常動作させる
        scheduleEndNotification(endDate: end, phase: self.phase)

        startTicking()
        refreshRemaining()
    }

    func pause() {
        stopTicking()
        removeEndNotification()
        isRunning = false
        saveState()
    }

    func stop() {
        stopTicking()
        removeEndNotification()

        isRunning = false
        phase = .focus
        durationSeconds = focusDurationDefault
        remainingSeconds = focusDurationDefault
        focusCount = 0

        startDate = nil
        endDate = nil

        clearState()
    }

    func restoreIfNeeded() {
        loadState()

        if isRunning {
            // endDateから再計算（保存済みremainingSecondsに依存しない）
            refreshRemaining()
            if remainingSeconds > 0 {
                startTicking()
            } else {
                // もし復元時点で既に0なら完了処理へ
                handlePhaseFinished()
            }
        } else {
            stopTicking()
            if endDate == nil {
                phase = .focus
                durationSeconds = focusDurationDefault
                remainingSeconds = focusDurationDefault
            } else {
                // 一時停止中でも表示は endDate から再計算しておくとズレに強い
                refreshRemaining()
            }
        }
    }

    // MARK: - Time calc

    func refreshRemaining() {
        guard let endDate else {
            remainingSeconds = durationSeconds
            return
        }

        let now = Date()
        let diff = Int(endDate.timeIntervalSince(now).rounded(.down))
        remainingSeconds = max(0, diff)

        // isRunning の時だけ自動遷移
        if isRunning, remainingSeconds == 0 {
            handlePhaseFinished()
        }
    }

    private func handlePhaseFinished() {
        stopTicking()
        removeEndNotification()

        switch phase {
        case .focus:
            focusCount = min(focusCount + 1, 4)
            start(durationSeconds: breakDurationDefault, phase: .break)

        case .break:
            start(durationSeconds: focusDurationDefault, phase: .focus)
        }
    }

    // MARK: - Ticking (GCD Timer)

    private func startTicking() {
        stopTicking()

        let source = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        source.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(120))

        source.setEventHandler { [weak self] in
            // MainActorへ寄せて状態更新
            Task { @MainActor in
                self?.refreshRemaining()
            }
        }

        source.resume()
        tickSource = source
    }

    private func stopTicking() {
        tickSource?.cancel()
        tickSource = nil
    }

    // MARK: - Notification

    private var notificationId: String {
        "pomodoro_end_\(phase.rawValue)" // フェーズごとに分けて衝突を避ける
    }

    private func scheduleEndNotification(endDate: Date, phase: Phase) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "ポモドーロ終了"
        content.body = (phase == .focus) ? "集中時間が終了！休憩しよう。" : "休憩が終了！次の集中へ。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, endDate.timeIntervalSince(Date())),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        // 権限がない場合は握りつぶす（アプリの挙動を壊さない）
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            center.add(request) { error in
                if let error {
                    print("Failed to add notification: \(error)")
                }
            }
        }
    }

    private func removeEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    // MARK: - Persistence

    private let key = "pomodoro_state_v3"

    private struct SavedState: Codable {
        var isRunning: Bool
        var phase: Phase
        var durationSeconds: Int
        var focusCount: Int
        var startDate: Date?
        var endDate: Date?
    }

    private func saveState() {
        let state = SavedState(
            isRunning: isRunning,
            phase: phase,
            durationSeconds: durationSeconds,
            focusCount: focusCount,
            startDate: startDate,
            endDate: endDate
        )

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadState() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let state = try? JSONDecoder().decode(SavedState.self, from: data)
        else { return }

        self.isRunning = state.isRunning
        self.phase = state.phase
        self.durationSeconds = state.durationSeconds
        self.focusCount = state.focusCount
        self.startDate = state.startDate
        self.endDate = state.endDate

        // ここで remainingSeconds は endDate から再計算する
        refreshRemaining()
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

