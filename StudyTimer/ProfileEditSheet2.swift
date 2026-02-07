import SwiftUI
import PhotosUI

struct ProfileEditSheet: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    // 画像選択
    @State private var selectedItem: PhotosPickerItem? = nil

    // 入力項目（編集用）
    @State private var name: String = ""
    @State private var dailyGoalMinutes: Int = 60
    @State private var targetSchool: String = ""
    @State private var targetQualifications: String = ""

    // numberPad の閉じる用
    enum Field: Hashable { case goal }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {

                // ───────────── 画像 ─────────────
                Section("プロフィール画像") {
                    HStack(spacing: 16) {
                        profileImageView
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("写真を選ぶ")
                        }

                        if store.profileImageData != nil {
                            Button(role: .destructive) {
                                store.profileImageData = nil
                            } label: {
                                Text("削除")
                            }
                        }
                    }
                }

                // ───────────── 基本情報 ─────────────
                Section("基本情報") {
                    TextField("名前", text: $name)
                    TextField("志望校", text: $targetSchool)
                    TextField("資格（例：英検2級, TOEICなど）", text: $targetQualifications)
                }

                // ───────────── 目標 ─────────────
                Section("毎日の目標") {
                    HStack {
                        Text("目標（分）")
                        Spacer()
                        TextField("60", value: $dailyGoalMinutes, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($focusedField, equals: .goal)
                        Text("分")
                    }

                    Stepper(value: $dailyGoalMinutes, in: 0...1440, step: 5) {
                        Text("微調整（5分刻み）")
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.profileName = name
                        store.dailyGoalMinutes = max(0, dailyGoalMinutes)
                        store.targetSchool = targetSchool
                        store.targetQualifications = targetQualifications
                        focusedField = nil
                        dismiss()
                    }
                }

                // numberPad の上に完了
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focusedField = nil }
                }
            }
            .onAppear {
                // 既存値をフォームへ反映
                name = store.profileName
                dailyGoalMinutes = store.dailyGoalMinutes
                targetSchool = store.targetSchool
                targetQualifications = store.targetQualifications
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            store.profileImageData = data
                        }
                    }
                }
            }
        }
    }

    // MARK: - Views / Helpers

    private var profileImageView: some View {
        Group {
            if let data = store.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.minimum = 0
        return f
    }
}

#Preview {
    ProfileEditSheet()
        .environmentObject(StudyStore())
}

