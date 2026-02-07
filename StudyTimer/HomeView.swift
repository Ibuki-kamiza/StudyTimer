import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject var store: StudyStore

    @State private var displayedDate = Date()
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

    // 月間目標の進捗（0〜1）
    private var monthlyProgress: Double {
        guard store.monthlyGoalMinutes > 0 else { return 0 }
        let totalMinutes = store.studyMinutesByDay.values.reduce(0, +)
        return min(1.0, Double(totalMinutes) / Double(store.monthlyGoalMinutes))
    }

    // 週間目標の進捗（0〜1）
    private var weeklyProgress: Double {
        guard store.weeklyGoalMinutes > 0 else { return 0 }
        return min(1.0, Double(weeklyTotalMinutes) / Double(store.weeklyGoalMinutes))
    }

    // 大事な日まであと何日か
    private var daysToImportant: Int {
        let from = calendar.startOfDay(for: Date())
        let to   = calendar.startOfDay(for: store.importantDate)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    todaySection
                    monthlyTotalSection
                    calendarSection
                    countdownSection
                    goalSection
                    chartSection

                    Text("最終更新：\(lastUpdated.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .onAppear {
                //最初に月初に丸める（表示安定）
                displayedDate = startOfMonth(displayedDate)
            }
            .refreshable { await reloadData() }
        }
    }

    // MARK: - ① 今日の予定 & 実績

    private var todaySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日の勉強予定時間")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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

    // MARK: - ② 今月合計

    private var monthlyTotalSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今月の合計学習時間")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f 時間", monthlyTotalHours))
                .font(.title3)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ③ カレンダー（どの月でもズレない＆欠損しにくい）

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

            //曜日ヘッダー（firstWeekdayに合わせる）
            let week = weekdaySymbolsAlignedToFirstWeekday()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(week, id: \.self) { d in
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(
                            d == "日" ? Color.red :
                            (d == "土" ? Color.blue : Color.secondary)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                }
            }

            //月のセル（日付 or nil を 42マスで作る）
            let cells = monthGridDays(for: displayedDate) // [Int?] 42個

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<cells.count, id: \.self) { i in
                    if let day = cells[i] {
                        let minutes = minutesForDisplayedMonth(day: day)

                        VStack(spacing: 2) {
                            Text("\(day)")
                                .font(.body)
                                .monospacedDigit()

                            Text(String(format: "%02d:%02d", minutes / 60, minutes % 60))
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        //文字欠損防止（固定サイズ＋余白）
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Color.clear.frame(height: 54)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// 表示中の月の day に紐づく minutes を取る（別月に行ったら0にする）
    private func minutesForDisplayedMonth(day: Int) -> Int {
        let today = Date()
        if calendar.isDate(displayedDate, equalTo: today, toGranularity: .month) {
            return store.studyMinutesByDay[day] ?? 0
        } else {
            return 0
        }
    }

    // MARK: - ④ カウントダウン

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.importantTitle.isEmpty ? "大事な日のカウントダウン" : store.importantTitle)
                .font(.headline)

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

    // MARK: - ⑤ 目標（グレー→緑＋達成で自動チェック）

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目標")
                .font(.headline)

            // 月間
            HStack(alignment: .center, spacing: 12) {
                let monthlyHours = store.monthlyGoalMinutes / 60
                VStack(alignment: .leading, spacing: 6) {
                    Text("今月の目標：\(monthlyHours)時間")
                    GoalBar(progress: monthlyProgress)
                        .frame(height: 8)
                }
                Spacer()
                Image(systemName: monthlyProgress >= 1.0 ? "checkmark.square.fill" : "square")
                    .foregroundStyle(monthlyProgress >= 1.0 ? Color.green : Color.secondary)
            }

            // 週間
            HStack(alignment: .center, spacing: 12) {
                let weeklyHours = store.weeklyGoalMinutes / 60
                VStack(alignment: .leading, spacing: 6) {
                    Text("今週の目標：\(weeklyHours)時間")
                    GoalBar(progress: weeklyProgress)
                        .frame(height: 8)
                }
                Spacer()
                Image(systemName: weeklyProgress >= 1.0 ? "checkmark.square.fill" : "square")
                    .foregroundStyle(weeklyProgress >= 1.0 ? Color.green : Color.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ⑥ 円グラフ

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

    // MARK: - Helpers

    private func reloadData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run { lastUpdated = Date() }
    }

    ///月移動：必ず月初に丸めて表示を安定させる
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedDate) {
            displayedDate = startOfMonth(newDate)
        }
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    //月初に丸める
    private func startOfMonth(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    // firstWeekdayに合わせて曜日を並び替える（日本語）
    private func weekdaySymbolsAlignedToFirstWeekday() -> [String] {
        let symbols = ["日","月","火","水","木","金","土"]
        let first = calendar.firstWeekday - 1 // 0-based
        return Array(symbols[first...] + symbols[..<first])
    }

    //月のカレンダーセルを作る（Int? / 42個）
    /// - nil: 空白セル
    private func monthGridDays(for date: Date) -> [Int?] {
        let monthStart = startOfMonth(date)
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart) // 1..7

        // ⭐️ ここがズレ修正の核心：firstWeekday基準でoffset計算
        let offset = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        var cells: [Int?] = Array(repeating: nil, count: offset)
        for d in range { cells.append(d) }

        // 表示を安定：常に 6週(42マス)
        while cells.count < 42 { cells.append(nil) }
        return cells
    }

    // MARK: - Chart sample data

    private struct StudyCategory: Identifiable {
        let id = UUID()
        let category: String
        let value: Double
        let color: Color
    }

    private let sampleData: [StudyCategory] = [
        .init(category: "英語", value: 40, color: .yellow),
        .init(category: "数学", value: 30, color: .blue),
        .init(category: "国語", value: 15, color: .green),
        .init(category: "理科", value: 10, color: .orange),
        .init(category: "社会", value: 5,  color: .pink)
    ]
}

// 目標バー（グレー→緑）
private struct GoalBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color.gray.opacity(0.25))

                RoundedRectangle(cornerRadius: 99)
                    .fill(Color.green)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    HomeView()
        .environmentObject(StudyStore())
}

