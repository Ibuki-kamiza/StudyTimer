import Foundation

enum TimeSlot {
    case dawn, morning, noon, evening, night

    static func current(for date: Date = Date()) -> TimeSlot {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 4...8:   return .dawn       // 4-8
        case 9...11:  return .morning     // 9-11
        case 12...15: return .noon        // 12-15
        case 16...19: return .evening     // 16-19
        default:      return .night       // 20-23 と 0-3
        }
    }
}

