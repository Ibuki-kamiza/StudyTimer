import SwiftUI
import Combine   // ←これを追加

struct TimerScreen: View {
    @State private var isRunning = false
    @State private var remaining = 25 * 60
    @State private var currentDate = Date()

    // 1秒ごとのタイマー
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            backgroundView(for: currentDate)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Text(format(remaining))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(isRunning ? "集中中…" : "停止中")
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button {
                    if !isRunning && remaining == 0 {
                        remaining = 25 * 60
                    }
                    isRunning.toggle()
                } label: {
                    Text(isRunning ? "ストップ" : "スタート")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                        .frame(width: 180, height: 180)
                        .background(Circle().fill(.black.opacity(0.8)))
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onReceive(ticker) { now in
            currentDate = now  // 背景用に時刻更新

            guard isRunning else { return }

            if remaining > 0 {
                remaining -= 1
            } else {
                isRunning = false
            }
        }
    }

    private func format(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }

    @ViewBuilder
    private func backgroundView(for date: Date) -> some View {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 4...9:
            LinearGradient(colors: [.orange, .yellow, .blue.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
        case 10...15:
            LinearGradient(colors: [.blue.opacity(0.6), .cyan, .white],
                           startPoint: .top, endPoint: .bottom)
        case 16...18:
            LinearGradient(colors: [.orange, .pink, .purple.opacity(0.5)],
                           startPoint: .top, endPoint: .bottom)
        case 19...23:
            LinearGradient(colors: [.black, .indigo.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
        default:
            LinearGradient(colors: [.black, .indigo.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

#Preview {
    TimerScreen()
}

