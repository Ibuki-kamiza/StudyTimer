import SwiftUI

/// 「記録する（時間）」の入力用
struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var minutesText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var comment: String = ""

    /// 保存時に親へ返す（分・日付・メモ）
    let onSave: (_ minutes: Int, _ date: Date, _ comment: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("勉強時間") {
                    HStack {
                        TextField("分数を入力", text: $minutesText)
                            .keyboardType(.numberPad)
                        Text("分")
                    }
                }

                Section("日付") {
                    DatePicker("勉強した日", selection: $selectedDate, displayedComponents: .date)
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $comment, axis: .vertical)
                }
            }
            .navigationTitle("勉強時間を記録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        let minutes = Int(minutesText) ?? 0
                        onSave(minutes, selectedDate, comment)
                        dismiss()
                    }
                    .disabled(Int(minutesText) == nil)
                }
            }
        }
    }
}

#Preview {
    RecordFormView { _,_,_ in }
}

