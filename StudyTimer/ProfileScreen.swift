import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var isShowingEdit = false
    @State private var displayedDate = Date()   // カレンダーに表示する月
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // プロフィールカード
                    HStack(alignment: .top, spacing: 16) {
                        Button {
                            isShowingEdit = true
                        } label: {
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
                            Button {
                                isShowingEdit = true
                            } label: {
                                Text(store.profileName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            Text("目標: 毎日2時間")
                            Text("志望校: 〇〇高校")
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 1)

                    // カレンダー部分
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                changeMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            Spacer()
                            Text(monthTitle(for: displayedDate))
                                .font(.headline)
                            Spacer()
                            Button {
                                changeMonth(by: 1)
                            } label: {
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

                        // 日付＋チェック
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
                                        // 何もないときはスペーサーにしとくと高さ揃う
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

                    Spacer().frame(height: 40)
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .sheet(isPresented: $isShowingEdit) {
                ProfileEditSheet()
                    .environmentObject(store)
            }
        }
    }

    // 月を前後に動かす
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
}

