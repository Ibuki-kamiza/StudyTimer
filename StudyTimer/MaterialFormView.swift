import SwiftUI

struct MaterialFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var finishedAt: Date = Date()
    @State private var comment: String = ""

    // 登録時に親に返す
    let onSave: (_ title: String, _ finishedAt: Date, _ comment: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("教材名") {
                    TextField("教材名を入力", text: $title)
                }
                Section("学習完了日") {
                    DatePicker("完了日", selection: $finishedAt, displayedComponents: .date)
                }
                Section("コメント") {
                    TextField("メモ", text: $comment, axis: .vertical)
                }
            }
            .navigationTitle("教材の追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        onSave(title, finishedAt, comment)
                        dismiss()
                    }
                }
            }
        }
    }
}

