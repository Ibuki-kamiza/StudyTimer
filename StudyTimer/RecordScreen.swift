import SwiftUI

struct RecordScreen: View {
    @EnvironmentObject var store: StudyStore

    @State private var minutesText: String = ""
    @State private var materialTitle: String = ""
    @State private var materialComment: String = ""
    @State private var targetDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                // 学習時間を追加
                Section("学習時間を追加") {
                    DatePicker("日付", selection: $targetDate, displayedComponents: .date)

                    TextField("分数（例：30）", text: $minutesText)
                        .keyboardType(.numberPad)

                    Button("学習時間を追加") {
                        addMinutes()
                    }
                }

                // 教材（学習記録）を追加
                Section("教材の記録を追加") {
                    TextField("教材名 / タイトル", text: $materialTitle)
                    TextField("メモ（任意）", text: $materialComment)

                    Button("教材を追加") {
                        addMaterial()
                    }
                    .disabled(materialTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                //記録一覧
                if !store.materials.isEmpty {
                    Section("教材の記録一覧") {
                        ForEach(store.materials) { m in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(m.title)
                                    .font(.headline)

                                Text(m.finishedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !m.comment.isEmpty {
                                    Text(m.comment)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteMaterials)
                    }
                }
            }
            .navigationTitle("記録")
        }
    }

    // MARK: - Actions

    private func addMinutes() {
        let trimmed = minutesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(trimmed), minutes > 0 else { return }

        store.addStudyMinutes(minutes, date: targetDate)

        // 入力リセット
        minutesText = ""
    }

    private func addMaterial() {
        let title = materialTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let comment = materialComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        // StudyStoreの関数は (title, comment, finishedAt) の順
        store.addMaterial(title: title, comment: comment, finishedAt: targetDate)

        materialTitle = ""
        materialComment = ""
    }

    private func deleteMaterials(at offsets: IndexSet) {
        offsets.map { store.materials[$0] }.forEach(store.removeMaterial)
    }
}

#Preview {
    RecordScreen()
        .environmentObject(StudyStore())
}

