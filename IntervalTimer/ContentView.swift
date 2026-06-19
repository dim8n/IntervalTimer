import SwiftUI

enum NotificationType: String, CaseIterable, Identifiable {
    case sound = "Звук"
    case vibration = "Вибрация"
    case both = "Звук + Вибрация"
    
    var id: String { self.rawValue }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var reminderManager = ReminderManager()
    
    // Временные переменные для колесиков выбора в UI
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var intervalMinutes = 30
    @State private var selectedNotification: NotificationType = .both
    
    var body: some View {
        NavigationView {
            Form {
                if !reminderManager.isActive {
                    Section(header: Text("Период активности")) {
                        DatePicker("Время начала", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Время окончания", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Section(header: Text("Интервал сигнала")) {
                        Stepper("Каждые \(intervalMinutes) мин.", value: $intervalMinutes, in: 1...360, step: 1)
                    }
                    
                    Section(header: Text("Способ уведомления")) {
                        Picker("Уведомление", selection: $selectedNotification) {
                            ForEach(NotificationType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Section(header: Text("Статус")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Таймер активен.")
                                .font(.subheadline)
                                .bold()
                            
                            if let secondsLeft = reminderManager.secondsToNextReminder {
                                let progress = Double(secondsLeft) / reminderManager.totalIntervalSeconds
                                
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                    .animation(.linear(duration: 1.0), value: progress)
                                
                                HStack {
                                    Text("До следующего сигнала:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatSeconds(secondsLeft))
                                        .font(.system(.body, design: .monospaced))
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: {
                        if reminderManager.isActive {
                            reminderManager.stopReminders()
                        } else {
                            reminderManager.startReminders(
                                from: startTime,
                                to: endTime,
                                intervalMinutes: intervalMinutes,
                                type: selectedNotification
                            )
                        }
                    }) {
                        Text(reminderManager.isActive ? "Остановить таймер" : "Запустить таймер")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(reminderManager.isActive ? Color.red : Color.green)
                            .cornerRadius(10)
                    }
                }
                // Секция со списком запланированных сигналов
                if reminderManager.isActive && !reminderManager.reminderTimes.isEmpty {
                    Section(header: Text("Расписание сигналов на сегодня")) {
                        List {
                            ForEach(reminderManager.reminderTimes, id: \.self) { time in
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(time > Date() ? .orange : .gray)
                                        .font(.caption)
                                    
                                    Text(formatAbsoluteTime(time))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(time > Date() ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    if time > Date() {
                                        Text("Ожидание")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Сработал")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        // Ограничиваем максимальную высоту списка, чтобы он не растягивал экран,
                        // и добавляем прокрутку внутри секции
                        .frame(maxHeight: 200)
                    }
                }
            }
            .navigationTitle("Таймер")
            .onAppear {
                reminderManager.requestPermission()
                
                // Загружаем сохраненные данные из менеджера в UI элементы
                self.startTime = reminderManager.savedStartTime
                self.endTime = reminderManager.savedEndTime
                self.intervalMinutes = reminderManager.savedInterval
                self.selectedNotification = reminderManager.savedNotificationType
            }
            // --- ДОБАВЛЕННЫЕ СТРОКИ ТУТ ---
            // Отслеживаем изменения и сохраняем их на лету
            .onChange(of: startTime) { saveCurrentState() }
            .onChange(of: endTime) { saveCurrentState() }
            .onChange(of: intervalMinutes) { saveCurrentState() }
            .onChange(of: selectedNotification) { saveCurrentState() }
            
            // --- ДОБАВЛЯЕМ ОТСЛЕЖИВАНИЕ АКТИВНОСТИ ОКНА ---
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    // Как только вошли в приложение — убираем старые пуши из шторки
                    reminderManager.clearDeliveredNotifications()
                }
            }
        }
    }
    
    // Вспомогательный метод для мгновенной записи текущего состояния экрана в LocalStorage
    private func saveCurrentState() {
        reminderManager.saveSettingsToLocalStorage(
            start: startTime,
            end: endTime,
            interval: intervalMinutes,
            type: selectedNotification
        )
    }
    
    private func formatSeconds(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatAbsoluteTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: date)
    }
}
