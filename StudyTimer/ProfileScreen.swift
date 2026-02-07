import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var isShowingEdit = false
    @State private var displayedDate = Date()
    private let calendar = Calendar.current

    // キーボード制御（numberPad対策）
    enum Field: Hashable { case monthlyGoal, weeklyGoal }
    @FocusState private var focusedField: Field?

    // 通知設定（保存される）
    @AppStorage("recordReminderEnabled") private var reminderEnabled: Bool = true
    @AppStorage("recordReminderHour") private var reminderHour: Int = 21
    @AppStorage("recordReminderMinute") private var reminderMinute: Int = 0

    // 整数入力用
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

                    // プロフィールカード
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
                            Button { isShowingEdit = true } label: {
                                Text(store.profileName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            Text("毎日の目標: \(formatMinutes(store.dailyGoalMinutes))")
                            Text("志望校: \(store.targetSchool)")
                            if !store.targetQualifications.isEmpty {
                                Text("資格: \(store.targetQualifications)")
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 学習目標
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学習目標").font(.headline)

                        goalRow(
                            title: "月間の学習時間",
                            minutes: $store.monthlyGoalMinutes,
                            focus: .monthlyGoal
                        )

                        goalRow(
                            title: "週間の学習時間",
                            minutes: $store.weeklyGoalMinutes,
                            focus: .weeklyGoal
                        )

                        Text("※ ここで設定した目標はホーム画面にも反映されます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 学習記録の通知
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学習記録の通知")
                            .font(.headline)

                        Toggle("通知を有効にする", isOn: $reminderEnabled)

                        if reminderEnabled {
                            DatePicker(
                                "通知時刻",
                                selection: Binding(
                                    get: {
                                        var c = DateComponents()
                                        c.hour = reminderHour
                                        c.minute = reminderMinute
                                        return calendar.date(from: c) ?? Date()
                                    },
                                    set: { date in
                                        reminderHour = calendar.component(.hour, from: date)
                                        reminderMinute = calendar.component(.minute, from: date)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }

                        Text("毎日この時間に学習記録の通知が届きます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ───────────────── カレンダー ─────────────────
                    calendarView

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .sheet(isPresented: $isShowingEdit, onDismiss: { focusedField = nil }) {
                ProfileEditSheet()
                    .environmentObject(store)
            }
        }
        // 画面タップでキーボード閉じる
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }

        // スクロールで閉じる
        .scrollDismissesKeyboard(.interactively)

        // numberPad用：キーボード上に完了ボタン
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { focusedField = nil }
            }
        }

        //  通知の再スケジュール
        .onChange(of: reminderEnabled) { _, newValue in
            Task {
                if newValue {
                    _ = await ReminderScheduler.requestPermission()
                    await ReminderScheduler.scheduleDailyRecordReminder(
                        hour: reminderHour,
                        minute: reminderMinute
                    )
                } else {
                    ReminderScheduler.cancel()
                }
            }
        }
        .onChange(of: reminderHour) { _, _ in rescheduleIfNeeded() }
        .onChange(of: reminderMinute) { _, _ in rescheduleIfNeeded() }
    }

    // MARK: - SubViews

    private func goalRow(title: String, minutes: Binding<Int>, focus: Field) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(
                "時間",
                value: Binding(
                    get: { minutes.wrappedValue / 60 },
                    set: { minutes.wrappedValue = max(0, $0) * 60 }
                ),
                formatter: intFormatter
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 64)
            .focused($focusedField, equals: focus)
            Text("時間")
        }
    }

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthTitle(for: displayedDate)).font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }

            let weekdays = ["S","M","T","W","T","F","S"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(weekdays, id: \.self) {
                    Text($0).font(.caption).foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(for: displayedDate), id: \.self) { day in
                    let hasStudy = (store.studyMinutesByDay[day] ?? 0) > 0
                    VStack(spacing: 2) {
                        Text("\(day)")
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
    }

    // MARK: - Helpers

    private func rescheduleIfNeeded() {
        Task {
            if reminderEnabled {
                await ReminderScheduler.scheduleDailyRecordReminder(
                    hour: reminderHour,
                    minute: reminderMinute
                )
            }
        }
    }

    private func changeMonth(by value: Int) {
        displayedDate = calendar.date(byAdding: .month, value: value, to: displayedDate) ?? displayedDate
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    // ここが一番重要：型の曖昧さを消す
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
        if h > 0 { return "\(h)時間" }
        return "\(m)分"
    }
}

