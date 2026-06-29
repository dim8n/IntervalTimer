import Foundation
import ActivityKit

struct TimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Передаем массив всех запланированных интервалов вместо одной даты
        var reminderTimes: [Date]
    }
}
