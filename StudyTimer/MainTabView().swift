import SwiftUI
import UserNotifications

struct MainTabView: View {
    @StateObject private var store = StudyStore()
    @State private var didSetupNotifications = false

    var body: some View {
        TabView {
            TimerScreen()
                .tabItem { Label("タイマー", systemImage: "clock") }
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }
            RecordScreen()
                .tabItem { Label("記録", systemImage: "pencil") }
            ProfileScreen()
                .tabItem { Label("プロフィール", systemImage: "person") }
        }
        .environmentObject(store)
        .onAppear {
            guard !didSetupNotifications else { return }
            didSetupNotifications = true

            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                if settings.authorizationStatus == .authorized {
                    store.scheduleGoalNotifications()
                } else {
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                        if ok { store.scheduleGoalNotifications() }
                    }
                }
            }
        }
    }
}

#Preview { MainTabView().environmentObject(StudyStore()) }

