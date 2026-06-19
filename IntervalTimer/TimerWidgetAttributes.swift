import Foundation
import ActivityKit

struct TimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Та самая переменная из первой версии
        var expireDate: Date
    }
}
