import SwiftUI
import PhotosUI

struct ProfileEditSheet: View {
    @EnvironmentObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var cameraImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("名前", text: $draftName)
                }

                Section("写真") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Text("フォトライブラリから選ぶ")
                    }

                    Button("カメラで撮る") {
                        isShowingCamera = true
                    }
                }

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
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.profileName = draftName
                        dismiss()
                    }
                }
            }
            .onAppear {
                draftName = store.profileName
            }
            // フォトライブラリで画像を選んだら Data に変換して保存
            .onChange(of: pickerItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        store.profileImageData = data
                    }
                }
            }
            // カメラ用のsheet
            .sheet(isPresented: $isShowingCamera) {
                CameraPicker(image: $cameraImage)
            }
            // カメラで撮ったら保存
            .onChange(of: cameraImage) { newImage in
                if let image = newImage, let data = image.jpegData(compressionQuality: 0.8) {
                    store.profileImageData = data
                }
            }
        }
    }
}

