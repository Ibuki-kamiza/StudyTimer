import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var isShowingEdit = false
    @State private var displayedDate = Date()   // カレンダーに表示する月
    private let calendar = Calendar.current

    // 整数入力用フォーマッタ（TextFieldで使用）
    private let intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.minimum = 0
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // ───────────────── プロフィールカード ─────────────────
                    HStack(alignment: .top, spacing: 16) {
                        Button { isShowingEdit = true } label: {
                            if let data = store.profileImageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.white)
                                    )
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            // 名前を押すと編集シート
                            Button { isShowingEdit = true } label: {
                                Text(store.profileName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            // 表示はストアの値を使う
                            Text("毎日の目標: \(formatMinutes(store.dailyGoalMinutes))")
                            Text("志望校: \(store.targetSchool)")
                            if !store.targetQualifications.isEmpty {
                                Text("資格: \(store.targetQualifications)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 1)

                    // ──────────────── 学習目標（直接編集） ────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学習目標")
                            .font(.headline)

                        HStack {
                            Text("月間の学習時間")
                            Spacer()
                            // hours = minutes / 60 を相互バインド
                            TextField(
                                "時間",
                                value: Binding<Int>(
                                    get: { store.monthlyGoalMinutes / 60 },
                                    set: { store.monthlyGoalMinutes = max(0, $0) * 60 }
                                ),
                                formatter: intFormatter
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 64)
                            Text("時間")
                        }

                        HStack {
                            Text("週間の学習時間")
                            Spacer()
                            TextField(
                                "時間",
                                value: Binding<Int>(
                                    get: { store.weeklyGoalMinutes / 60 },
                                    set: { store.weeklyGoalMinutes = max(0, $0) * 60 }
                                ),
                                formatter: intFormatter
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 64)
                            Text("時間")
                        }

                        Text("※ ここで設定した目標はホーム画面にも反映されます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ───────────────── カレンダー ─────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button { changeMonth(by: -1) } label: {
                                Image(systemName: "chevron.left")
                            }
                            Spacer()
                            Text(monthTitle(for: displayedDate))
                                .font(.headline)
                            Spacer()
                            Button { changeMonth(by: 1) } label: {
                                Image(systemName: "chevron.right")
                            }
                        }

                        // 曜日
                        let weekdays = ["S","M","T","W","T","F","S"]
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            ForEach(weekdays.indices, id: \.self) { i in
                                Text(weekdays[i])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // 日付＋勉強チェック
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysInMonth(for: displayedDate), id: \.self) { day in
                                let hasStudy = (store.studyMinutesByDay[day] ?? 0) > 0
                                VStack(spacing: 2) {
                                    Text("\(day)")
                                        .font(.body)
                                    if hasStudy {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    } else {
                                        Color.clear.frame(height: 10)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .sheet(isPresented: $isShowingEdit) {
                ProfileEditSheet()   // ← 名前・写真・毎日目標・志望校・資格をここで編集
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Helpers
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedDate) {
            displayedDate = newDate
        }
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    private func daysInMonth(for date: Date) -> [Int] {
        if let range = calendar.range(of: .day, in: .month, for: date) {
            return Array(range)
        } else {
            return Array(1...30)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)時間\(m)分" }
        if h > 0           { return "\(h)時間" }
        return "\(m)分"
    }
}

