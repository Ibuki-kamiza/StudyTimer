import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject var store: StudyStore

    // 今表示している月（カレンダー用）
    @State private var displayedDate = Date()
    // 下スワイプ更新用（デバッグ表示）
    @State private var lastUpdated = Date()

    private let calendar = Calendar.current

    // 今月の合計学習時間（時間）
    private var monthlyTotalHours: Double {
        let totalMinutes = store.studyMinutesByDay.values.reduce(0, +)
        return Double(totalMinutes) / 60.0
    }

    // 今週の合計学習時間（分）
    private var weeklyTotalMinutes: Int {
        let today = Date()
        guard let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else { return 0 }

        var total = 0
        for offset in 0..<7 {
            guard let d = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            // 今月以外は無視（store が「今月の日数」で持っている前提）
            guard calendar.isDate(d, equalTo: today, toGranularity: .month) else { continue }
            let day = calendar.component(.day, from: d)
            total += store.studyMinutesByDay[day] ?? 0
        }
        return total
    }

    // 今日の学習時間（分）
    private var todayMinutes: Int {
        let day = calendar.component(.day, from: Date())
        return store.studyMinutesByDay[day] ?? 0
    }

    // 月間目標に対する進捗（0〜1）
    private var monthlyProgress: Double {
        guard store.monthlyGoalMinutes > 0 else { return 0 }
        let totalMinutes = store.studyMinutesByDay.values.reduce(0, +)
        return min(1.0, Double(totalMinutes) / Double(store.monthlyGoalMinutes))
    }

    // 週間目標に対する進捗（0〜1）
    private var weeklyProgress: Double {
        guard store.weeklyGoalMinutes > 0 else { return 0 }
        return min(1.0, Double(weeklyTotalMinutes) / Double(store.weeklyGoalMinutes))
    }

    // 大事な日まであと何日か（StudyStore の importantDate を使用）
    private var daysToImportant: Int {
        let from = calendar.startOfDay(for: Date())
        let to   = calendar.startOfDay(for: store.importantDate)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ① 今日の学習予定時間・実績
                    todaySection

                    // ② カレンダー（1ヶ月 & 日ごとの学習時間）
                    calendarSection

                    // ③ 大事な日のカウントダウン
                    countdownSection

                    // ④ 月間 / 週間の学習目標
                    goalSection

                    // ⑤ 科目別円グラフ
                    chartSection

                    // デバッグ用：最終更新
                    Text("最終更新：\(lastUpdated.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .refreshable {
                await reloadData()
            }
        }
    }

    // MARK: - セクション表示

    /// ① 今日の予定 & 実績
    private var todaySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日の勉強予定時間")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // 予定は「毎日の学習目標」を流用
                let h = store.dailyGoalMinutes / 60
                let m = store.dailyGoalMinutes % 60
                Text("\(h)時間\(String(format: "%02d", m))分")
                    .font(.title2)
                    .bold()
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("実績")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(todayMinutes / 60)時間\(String(format: "%02d", todayMinutes % 60))分")
                    .font(.title2)
                    .bold()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// ② カレンダー
    private var calendarSection: some View {
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
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付 + 学習時間 00:00
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(for: displayedDate), id: \.self) { day in
                    let minutes = store.studyMinutesByDay[day] ?? 0
                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.body)
                        Text(String(format: "%02d:%02d", minutes / 60, minutes % 60))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
    }

    /// ③ 大事な日のカウントダウン
    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タイトルはプロフィール編集で設定したものを使う
            Text(store.importantTitle.isEmpty
                 ? "大事な日のカウントダウン"
                 : store.importantTitle)
                .font(.headline)

            // 日付も表示
            Text(store.importantDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("まであと")
                Text("\(max(0, daysToImportant))日")
                    .font(.title)
                    .bold()
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// ④ 月間 / 週間目標
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目標")
                .font(.headline)

            // 月間
            HStack {
                let monthlyHours = store.monthlyGoalMinutes / 60
                Text("今月の目標：\(monthlyHours)時間")
                Spacer()
                ProgressView(value: monthlyProgress)
                    .frame(width: 120)
                Image(systemName: monthlyProgress >= 1.0 ? "checkmark.square.fill" : "square")
            }

            // 週間
            HStack {
                let weeklyHours = store.weeklyGoalMinutes / 60
                Text("今週の目標：\(weeklyHours)時間")
                Spacer()
                ProgressView(value: weeklyProgress)
                    .frame(width: 120)
                Image(systemName: weeklyProgress >= 1.0 ? "checkmark.square.fill" : "square")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// ⑤ 円グラフ
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("科目別学習割合")
                .font(.headline)

            Chart(sampleData) { item in
                SectorMark(
                    angle: .value("時間", item.value),
                    innerRadius: .ratio(0.6)
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 220)

            // 凡例
            ForEach(sampleData) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)
                    Text("\(item.category)：\(String(format: "%.1f", item.value)) 時間")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 共通ヘルパー

    private func reloadData() async {
        // 今はダミーで0.5秒待つだけ
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            lastUpdated = Date()
        }
    }

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
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        return Array(range)
    }
}

// MARK: - 円グラフ用ダミーデータ

struct StudyCategory: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
}

let sampleData: [StudyCategory] = [
    .init(category: "英語", value: 40, color: .yellow),
    .init(category: "数学", value: 30, color: .blue),
    .init(category: "国語", value: 15, color: .green),
    .init(category: "理科", value: 10, color: .orange),
    .init(category: "社会", value: 5,  color: .pink)
]

#Preview {
    HomeView()
        .environmentObject(StudyStore())
}

