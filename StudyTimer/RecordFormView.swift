import SwiftUI
import UIKit

/// 「記録する（時間）」の入力用
struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var minutesText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var comment: String = ""

    // キーボード制御（フォーカス管理）
    @FocusState private var focusedField: Field?
    private enum Field { case minutes, comment }

    /// 保存時に親へ返す（分・日付・メモ）
    let onSave: (_ minutes: Int, _ date: Date, _ comment: String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // 画面全体タップを拾う透明レイヤー（Formより下に敷く）
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }

                Form {
                    Section("勉強時間") {
                        HStack {
                            TextField("分数を入力", text: $minutesText)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .minutes)
                            Text("分")
                        }
                    }

                    Section("日付") {
                        DatePicker("勉強した日", selection: $selectedDate, displayedComponents: .date)
                    }

                    Section("メモ") {
                        TextField("メモ（任意）", text: $comment, axis: .vertical)
                            .focused($focusedField, equals: .comment)
                    }
                }
                //  フォーム内のスクロールでも閉じる（iOS16+）
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("勉強時間を記録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismissKeyboard()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        // ここで100%閉じる
                        dismissKeyboard()

                        let minutes = Int(minutesText) ?? 0
                        onSave(minutes, selectedDate, comment)
                        dismiss()
                    }
                    .disabled((Int(minutesText) ?? 0) <= 0)
                }

                // numberPadには完了キーがない → キーボード上に「完了」を追加
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { dismissKeyboard() }
                }
            }
            .onAppear {
                // 最初に分数へフォーカス（不要なら消してOK）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focusedField = .minutes
                }
            }
        }
    }

    // フォーカス解除 + 強制的にキーボードを閉じる（最強）
    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

#Preview {
    RecordFormView { _,_,_ in }
}

