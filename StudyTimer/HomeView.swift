import SwiftUI
import Charts

struct HomeView: View {
    @State private var lastUpdated = Date()
    // 日にちごとの学習時間（分）
    @State private var studyMinutesByDay: [Int: Int] = [
        1: 90, 3: 45, 5: 120, 10: 30
    ]
    // 今表示している月
    @State private var displayedDate = Date()

    private let calendar = Calendar.current

    // 円グラフ用データの合計（時間）
    private var totalStudyHours: Double {
        sampleData.map { $0.value }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ① 今日の勉強予定・実績
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("今日の勉強予定時間")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("3時間00分")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("実績")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("2時間45分")
                                .font(.title2)
                                .bold()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ② カレンダー（月切り替え付き）
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
                            ForEach(weekdays.indices, id: \.self) { idx in
                                Text(weekdays[idx])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // 日付 ＋ 学習時間
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysInMonth(for: displayedDate), id: \.self) { day in
                                VStack(spacing: 2) {
                                    Text("\(day)")
                                        .font(.body)
                                    Text(formattedTime(for: day))
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

                    // ③ カウントダウン
                    VStack(alignment: .leading, spacing: 8) {
                        Text("大事な日のカウントダウン")
                            .font(.headline)
                        HStack {
                            Text("試験日まであと")
                            Text("10日")
                                .font(.title)
                                .bold()
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ④ 目標
                    VStack(alignment: .leading, spacing: 12) {
                        Text("目標")
                            .font(.headline)
                        HStack {
                            Text("11月目標：40時間")
                            Spacer()
                            ProgressView(value: 0.6)
                                .frame(width: 100)
                            Image(systemName: "square")
                        }
                        HStack {
                            Text("今週：10時間")
                            Spacer()
                            ProgressView(value: 0.3)
                                .frame(width: 100)
                            Image(systemName: "square")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ⑤ 円グラフ（科目別＋合計＋凡例）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("科目別学習割合")
                            .font(.headline)

                        // 合計時間を表示
                        Text("合計学習時間：\(String(format: "%.1f", totalStudyHours)) 時間")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // 円グラフ本体
                        Chart(sampleData) { item in
                            SectorMark(
                                angle: .value("時間", item.value),
                                innerRadius: .ratio(0.6)
                            )
                            .foregroundStyle(item.color)
                        }
                        .frame(height: 220)

                        // 教材名＋時間の一覧（凡例）
                        VStack(alignment: .leading, spacing: 6) {
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
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // デバッグ用の更新時間
                    Text("最終更新：\(lastUpdated.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .refreshable { await reloadData() }
        }
    }

    // MARK: - 下スワイプで更新
    private func reloadData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        lastUpdated = Date()
    }

    // MARK: - カレンダー操作
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

    private func formattedTime(for day: Int) -> String {
        let minutes = studyMinutesByDay[day] ?? 0
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - グラフ用のダミーデータ
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
}

