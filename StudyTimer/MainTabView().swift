import SwiftUI

struct MainTabView: View {
    // ここで共有データを1個だけ作る
    @StateObject private var store = StudyStore()

    var body: some View {
        TabView {
            TimerScreen()
                .tabItem {
                    Label("タイマー", systemImage: "clock")
                }

            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            RecordScreen()
                .tabItem {
                    Label("記録", systemImage: "pencil")
                }

            ProfileScreen()
                .tabItem {
                    Label("プロフィール", systemImage: "person")
                }
        }
        // これがないと RecordScreen などでクラッシュする
        .environmentObject(store)
    }
}

#Preview {
    MainTabView()
        .environmentObject(StudyStore())
}

