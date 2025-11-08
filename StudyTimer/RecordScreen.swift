import SwiftUI

struct RecordScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var isShowingStudyForm = false
    @State private var isShowingMaterialForm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isShowingStudyForm = true
                    } label: {
                        Label("記録する（時間）", systemImage: "clock.badge.plus")
                    }
                }

                Section {
                    Button {
                        isShowingMaterialForm = true
                    } label: {
                        Label("教材の追加", systemImage: "book.closed.fill")
                    }
                }

                if !store.materials.isEmpty {
                    Section("追加した教材") {
                        ForEach(store.materials) { material in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(material.title)
                                    .font(.headline)
                                Text(material.finishedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !material.comment.isEmpty {
                                    Text(material.comment)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("記録")
            .sheet(isPresented: $isShowingStudyForm) {
                // 勉強時間を登録する方
                RecordFormView { minutes, material, comment in
                    store.addRecord(date: Date(), minutes: minutes)
                    isShowingStudyForm = false
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $isShowingMaterialForm) {
                // 教材を登録する方
                MaterialFormView { title, finishedAt, comment in
                    store.addMaterial(title: title, date: finishedAt, comment: comment)
                    isShowingMaterialForm = false
                }
            }
        }
    }
}

#Preview {
    RecordScreen()
        .environmentObject(StudyStore())
}

