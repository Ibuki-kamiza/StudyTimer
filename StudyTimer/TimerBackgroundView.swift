import SwiftUI

struct TimerBackgroundView: View {
    let slot: TimeSlot

    var body: some View {
        Group {
            switch slot {

            case .dawn:
                LinearGradient(colors: [.orange.opacity(0.5), .yellow.opacity(0.2)],
                               startPoint: .top, endPoint: .bottom)

            case .morning:
                LinearGradient(colors: [.blue.opacity(0.4), .white],
                               startPoint: .top, endPoint: .bottom)

            case .noon:
                LinearGradient(colors: [.cyan.opacity(0.35), .white],
                               startPoint: .top, endPoint: .bottom)

            case .evening:
                LinearGradient(colors: [.pink.opacity(0.35), .purple.opacity(0.25)],
                               startPoint: .top, endPoint: .bottom)

            case .night:
                LinearGradient(colors: [.black.opacity(0.7), .blue.opacity(0.35)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    TimerBackgroundView(slot: .morning)
}

