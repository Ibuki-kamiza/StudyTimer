import SwiftUI
import PhotosUI
import UserNotifications

struct ProfileEditSheet: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var draftSchool: String = ""
    @State private var draftDailyHour: String = ""       // 例: "2"（時間）
    @State private var draftDailyMin: String  = ""       // 例: "30"（分）
    @State private var draftQualifications: String = ""  // カンマ区切り

    // ▼ここを追加：大事な日のドラフト
    @State private var draftImportantDate: Date = Date()
    @State private var draftImportantTitle: String = ""

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var cameraImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            Form {
                // プロフィール基本情報
                Section("プロフィール") {
                    TextField("名前", text: $draftName)
                    TextField("志望校", text: $draftSchool)
                    TextField("取りたい資格（例: 英検準1級, ITパスポート）",
                              text: $draftQualifications)
                }

                // 毎日の学習時間目標
                Section("毎日の学習時間目標") {
                    HStack {
                        TextField("時間", text: $draftDailyHour)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("時間")
                        TextField("分", text: $draftDailyMin)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("分")
                    }
                    Text("毎朝6:00にリマインドを送ります")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // ▼追加：大事な日のカウントダウン設定
                Section("大事な日のカウントダウン") {
                    TextField("タイトル（例: 第1志望校の入試）",
                              text: $draftImportantTitle)
                    DatePicker("日付",
                               selection: $draftImportantDate,
                               displayedComponents: .date)
                }

                // 写真
                Section("写真") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Text("フォトライブラリから選ぶ")
                    }
                    Button("カメラで撮る") {
                        isShowingCamera = true
                    }
                }

                // 現在の画像プレビュー
                if let data = store.profileImageData,
                   let uiImage = UIImage(data: data) {
                    Section("現在の画像") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                    }
                }
            }
            .navigationTitle("プロフィールを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        // 名前・志望校・資格
                        if !draftName.isEmpty {
                            store.profileName = draftName
                        }
                        store.targetSchool = draftSchool
                        store.targetQualifications = draftQualifications

                        // 毎日目標（時間+分 → 分 に変換）
                        let h = Int(draftDailyHour) ?? 0
                        let m = Int(draftDailyMin)  ?? 0
                        store.dailyGoalMinutes = max(0, h * 60 + m)

                        // ▼ 大事な日を保存
                        store.importantDate = draftImportantDate
                        store.importantTitle = draftImportantTitle

                        // 通知を再スケジュール（毎朝・毎週・毎月）
                        UNUserNotificationCenter.current()
                            .getNotificationSettings { settings in
                                if settings.authorizationStatus == .authorized {
                                    store.scheduleGoalNotifications()
                                } else {
                                    UNUserNotificationCenter.current()
                                        .requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                                            if ok {
                                                store.scheduleGoalNotifications()
                                            }
                                        }
                                }
                            }

                        dismiss()
                    }
                }
            }
            // 画面表示時にドラフトへ現在値をセット
            .onAppear {
                draftName = store.profileName
                draftSchool = store.targetSchool
                draftQualifications = store.targetQualifications
                draftDailyHour = String(store.dailyGoalMinutes / 60)
                draftDailyMin  = String(store.dailyGoalMinutes % 60)

                draftImportantDate  = store.importantDate
                draftImportantTitle = store.importantTitle
            }
            // フォトライブラリから選んだとき
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            store.profileImageData = data
                        }
                    }
                }
            }
            // カメラ撮影時
            .sheet(isPresented: $isShowingCamera) {
                CameraPicker(image: $cameraImage)
            }
            .onChange(of: cameraImage) { _, newImage in
                if let img = newImage,
                   let data = img.jpegData(compressionQuality: 0.85) {
                    store.profileImageData = data
                }
            }
        }
    }
}

