import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

struct IntervalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            // Получаем актуальный интервал для экрана блокировки
            let nextExpireDate = getNextExpireDate(from: context.state.reminderTimes)
            
            // Интерфейс на ЭКРАНЕ БЛОКИРОВКИ
            HStack(alignment: .center, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Таймер")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)
                    Text("До сигнала:")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .center) {
                    if let expireDate = nextExpireDate {
                        // СИСТЕМНЫЙ ТАЙМЕР: iOS сама будет переключать его,
                        // так как при наступлении expireDate этот Text автоматически скроется/пересчитается,
                        // либо применит новую дату, если виджет обновится
                        Text(timerInterval: Date()...expireDate, countsDown: true)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    } else {
                        Text("00:00")
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Button(intent: StartTimerIntent()) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            let nextExpireDate = getNextExpireDate(from: context.state.reminderTimes)
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("⏱️")
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let expireDate = nextExpireDate {
                        Text(timerInterval: Date()...expireDate, countsDown: true)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.trailing, 8)
                    } else {
                        Text("00:00")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Дневной интервал запущен")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Text("⏱️")
            } compactTrailing: {
                if let expireDate = nextExpireDate {
                    Text(timerInterval: Date()...expireDate, countsDown: true)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.orange)
                } else {
                    Text("00:00")
                }
            } minimal: {
                Text("⏱️")
            }
        }
    }
    
    // Вспомогательная функция, которая ищет первый интервал в будущем прямо внутри виджета
    private func getNextExpireDate(from times: [Date]) -> Date? {
        let now = Date()
        // Находим самое первое время из массива, которое строго больше текущего момента
        return times.first(where: { $0 > now })
    }
}
