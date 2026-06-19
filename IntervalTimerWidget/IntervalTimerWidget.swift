import SwiftUI
import WidgetKit
import ActivityKit

struct IntervalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            // Интерфейс на ЭКРАНЕ БЛОКИРОВКИ
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Интервальный таймер")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                    Text("До сигнала:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Тот самый исходный рабочий таймер отсчета до expireDate
                Text(timerInterval: Date()...context.state.expireDate, countsDown: true)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            // Интерфейс в DYNAMIC ISLAND
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("⏱️")
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.expireDate, countsDown: true)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Дневной интервал запущен")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Text("⏱️")
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.expireDate, countsDown: true)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
            } minimal: {
                Text("⏱️")
            }
        }
    }
}
