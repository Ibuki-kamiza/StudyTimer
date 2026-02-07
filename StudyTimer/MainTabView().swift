import SwiftUI
@preconcurrency import UserNotifications

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
            setupNotificationsIfNeeded()
        }
    }

    // MARK: - 通知セットアップ（1回だけ実行）
    private func setupNotificationsIfNeeded() {
        guard !didSetupNotifications else { return }
        didSetupNotifications = true

        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak store] settings in
            guard let store else { return }

            if settings.authorizationStatus == .authorized {
                Task { @MainActor in
                    store.scheduleGoalNotifications()
                }
            } else {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak store] ok, _ in
                    guard ok, let store else { return }
                    Task { @MainActor in
                        store.scheduleGoalNotifications()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}

