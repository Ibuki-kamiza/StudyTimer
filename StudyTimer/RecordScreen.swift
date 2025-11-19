import SwiftUI

struct RecordScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var isShowingStudyForm = false
    @State private var isShowingMaterialForm = false

    var body: some View {
        NavigationStack {
            List {

                // 勉強時間の記録
                Section("学習時間") {
                    Button {
                        isShowingStudyForm = true
                    } label: {
                        HStack {
                            ZStack {
                                Image(systemName: "clock")
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                    .offset(x: 8, y: 8)
                            }
                            Text("記録する（時間）")
                        }
                    }
                }

                // 教材の追加
                Section("教材") {
                    Button {
                        isShowingMaterialForm = true
                    } label: {
                        Label("教材の追加", systemImage: "book.closed.fill")
                    }
                }

                // 追加した教材の一覧
                if !store.materials.isEmpty {
                    Section("追加した教材") {
                        ForEach(store.materials) { material in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(material.title)
                                    .font(.headline)

                                Text(material.finishedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !material.comment.isEmpty {
                                    Text(material.comment)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("記録")
            // 学習時間入力シート（RecordFormView 側の引数: minutes, date, comment）
            .sheet(isPresented: $isShowingStudyForm) {
                RecordFormView { minutes, date, _ in
                    store.addRecord(date: date, minutes: minutes)
                }
            }
            // 教材追加シート（MaterialFormView 側の引数: title, finishedAt, comment）
            .sheet(isPresented: $isShowingMaterialForm) {
                MaterialFormView { title, finishedAt, comment in
                    store.addMaterial(title: title, finishedAt: finishedAt, comment: comment)
                }
            }
        }
    }
}

#Preview {
    RecordScreen()
        .environmentObject(StudyStore())
}

