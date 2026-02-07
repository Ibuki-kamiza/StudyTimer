import SwiftUI
import UIKit

struct TimerScreen: View {

    // ポモドーロのロジック担当
    @StateObject private var timerStore = PomodoroTimerStore()

    // プロフィール / 背景データ
    @EnvironmentObject var store: StudyStore

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {

        // 1分ごとに時間帯を再評価
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let slot = TimeSlot.current(for: context.date)

            ZStack {
                // 重要
                backgroundView(slot: slot)

                VStack(spacing: 28) {

                    // 上部バー
                    HStack {
                        Image(systemName: "chevron.left").opacity(0)
                        Spacer()
                        Text("ポモドーロ")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "gearshape").opacity(0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()

                    // 状態表示
                    Text(timerStore.phase == .focus ? "集中タイム" : "休憩タイム")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))

                    // 残り時間
                    Text(format(timerStore.remainingSeconds))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    // ポモドーロ回数
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                                .background(
                                    Circle()
                                        .fill(index < timerStore.focusCount ? .white : .clear)
                                )
                                .frame(width: 16, height: 16)
                        }
                    }

                    Spacer()

                    // スタート / ストップ
                    Button {
                        if timerStore.isRunning {
                            timerStore.stop()
                        } else {
                            timerStore.startFocus()
                        }
                    } label: {
                        Text(timerStore.isRunning ? "ストップ" : "スタート")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 200)
                            .background(
                                Circle().fill(Color.black.opacity(0.6))
                            )
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .onAppear {
            requestNotificationPermission()
            timerStore.restoreIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerStore.restoreIfNeeded()
            }
        }
    }

    // MARK: - 背景（時間帯画像 → プロフ画像 → グラデ）

    @ViewBuilder
    private func backgroundView(slot: TimeSlot) -> some View {

        // 時間帯ごとの背景（最優先）
        if let data = store.pomodoroBackgroundData(for: slot),
           let uiImage = UIImage(data: data) {

            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35))

        // プロフィール画像（次点）
        } else if let data = store.profileImageData,
                  let uiImage = UIImage(data: data) {

            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35))

        // それも無ければ時間帯グラデーション
        } else {
            TimerBackgroundView(slot: slot)
                .overlay(Color.black.opacity(0.25))
        }
    }

    // MARK: - Utility

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func format(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    TimerScreen()
        .environmentObject(StudyStore())
}

