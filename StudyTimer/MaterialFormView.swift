import SwiftUI

/// 「教材の追加」の入力用
struct MaterialFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var finishedAt: Date = Date()
    @State private var comment: String = ""

    /// 保存時に親へ返す（教材名・完了日・コメント）
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
            .navigationTitle("教材を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        onSave(title, finishedAt, comment)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MaterialFormView { _,_,_ in }
}

