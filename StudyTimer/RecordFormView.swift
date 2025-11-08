import SwiftUI

struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var minutesText = ""
    @State private var material = ""
    @State private var comment = ""

    // 登録ボタンを押したときに親に伝える
    let onSave: (_ minutes: Int, _ material: String, _ comment: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("学習時間") {
                    TextField("分で入力（例: 30）", text: $minutesText)
                        .keyboardType(.numberPad)
                }
                Section("学習した教材") {
                    TextField("教材名", text: $material)
                }
                Section("コメント") {
                    TextField("メモ", text: $comment, axis: .vertical)
                }
            }
            .navigationTitle("記録する")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        let minutes = Int(minutesText) ?? 0
                        onSave(minutes, material, comment)
                        dismiss()
                    }
                }
            }
        }
    }
}

