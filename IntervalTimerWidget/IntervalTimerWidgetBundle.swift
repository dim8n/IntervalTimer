import WidgetKit
import SwiftUI

@main
struct IntervalTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Теперь компилятор четко понимает, какую структуру вызывать
        IntervalLiveActivityWidget()
    }
}
