import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

struct IntervalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in
            // Интерфейс на ЭКРАНЕ БЛОКИРОВКИ (Трехзонная структура)
            HStack(alignment: .center, spacing: 0) {
                
                // ЗОНА 1: Информационные надписи (Выравнивание по левому краю)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Таймер")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)
                    Text("До сигнала:")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // ЗОНА 2: Обратный отсчет (Строго по центру виджета)
                VStack(alignment: .center) {
                    Text(timerInterval: Date()...context.state.expireDate, countsDown: true)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // ЗОНА 3: Декоративная кнопка паузы (Выравнивание по правому краю)
                HStack {
                    Button(intent: StartTimerIntent()) { // Используем системный Intent для совместимости с кнопками в виджетах
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain) // Убираем стандартную синюю рамку кнопки iOS
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            // Интерфейс в DYNAMIC ISLAND (Оставляем стабильный рабочий вариант)
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
