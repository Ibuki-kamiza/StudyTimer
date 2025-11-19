import SwiftUI
import Combine

struct TimerScreen: View {
    @EnvironmentObject var store: StudyStore

    // ポモドーロの状態
    enum Phase {
        case focus      // 勉強 25分
        case breakTime  // 休憩 5分
    }

    @State private var phase: Phase = .focus
    @State private var isRunning = false
    @State private var remaining = 25 * 60        // 残り時間（秒）
    @State private var focusCount = 0             // 何回目のポモドーロか

    // 1秒ごとにイベントを流すタイマー
    private let timer = Timer.publish(every: 1,
                                      on: .main,
                                      in: .common)
        .autoconnect()

    var body: some View {
        ZStack {
            // 背景：プロフィール画像があればそれを使う
            backgroundView

            VStack(spacing: 28) {
                // 上のバー
                HStack {
                    Image(systemName: "chevron.left")
                        .opacity(0) // 今はダミー
                    Spacer()
                    Text("ポモドーロ")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "gearshape")
                        .opacity(0) // 設定はあとで
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // 状態テキスト
                Text(phase == .focus ? "集中タイム" : "休憩タイム")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                // 残り時間
                Text(formatTime(remaining))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                // 何回目かを ◯ で表示（最大4個）
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                            .background(
                                Circle()
                                    .fill(index < focusCount ? Color.white : Color.clear)
                            )
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.top, 4)

                Spacer()

                // スタート / ストップ ボタン
                Button {
                    isRunning.toggle()
                } label: {
                    Text(isRunning ? "ストップ" : "スタート")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 200)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        // 1秒ごとに残り時間を減らす
        .onReceive(timer) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    // MARK: - 背景

    private var backgroundView: some View {
        Group {
            if let data = store.profileImageData,
               let uiImage = UIImage(data: data) {
                // プロフィール画像を背景に
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.35)) // 見やすくするため暗くする
                    .ignoresSafeArea()
            } else {
                // 画像がないときはグラデーション
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.75, blue: 0.40),
                        Color(red: 0.95, green: 0.50, blue: 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - タイマーの進行

    private func tick() {
        if remaining > 0 {
            remaining -= 1
            return
        }

        // 0秒になったらフェーズを切り替える
        switch phase {
        case .focus:
            // 勉強25分が終わった
            focusCount += 1
            phase = .breakTime
            remaining = 5 * 60     // 5分休憩
        case .breakTime:
            // 休憩が終わったら次の集中タイムへ
            phase = .focus
            remaining = 25 * 60
        }
    }

    // MARK: - 表示用フォーマット

    private func formatTime(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    TimerScreen()
        .environmentObject(StudyStore())
}

