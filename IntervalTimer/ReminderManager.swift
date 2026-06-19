import Foundation
import UserNotifications
import Combine
import ActivityKit

class ReminderManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var secondsToNextReminder: Int? = nil
    @Published var totalIntervalSeconds: Double = 1800
    
    // Переменные, хранящие настройки для отображения в интерфейсе
    @Published var savedStartTime: Date = Date()
    @Published var savedEndTime: Date = Date()
    @Published var savedInterval: Int = 30
    @Published var savedNotificationType: NotificationType = .both
    
    private var internalTimer: Timer?
    @Published var reminderTimes: [Date] = []
    private var currentActivity: Activity<TimerWidgetAttributes>? = nil
    private var lastUpdatedActivityDate: Date? = nil
    
    // Стандартное локальное хранилище iOS
    private let localStore = UserDefaults.standard
    
    init() {
        // Как только менеджер создается, мы сразу читаем данные из памяти телефона
        loadSettingsFromLocalStorage()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // Очистка всех доставленных уведомлений из шторки
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // 1. ФУНКЦИЯ СОХРАНЕНИЯ НАСТРОЕК В ПАМЯТЬ ТЕЛЕФОНА
    func saveSettingsToLocalStorage(start: Date, end: Date, interval: Int, type: NotificationType) {
        localStore.set(start.timeIntervalSince1970, forKey: "local_startTime")
        localStore.set(end.timeIntervalSince1970, forKey: "local_endTime")
        localStore.set(interval, forKey: "local_intervalMinutes")
        localStore.set(type.rawValue, forKey: "local_notificationType")
        
        self.savedStartTime = start
        self.savedEndTime = end
        self.savedInterval = interval
        self.savedNotificationType = type
    }
    
    // 2. ФУНКЦИЯ ЗАГРУЗКИ НАСТРОЕК ИЗ ПАМЯТИ
    func loadSettingsFromLocalStorage() {
        let startTimestamp = localStore.double(forKey: "local_startTime")
        let endTimestamp = localStore.double(forKey: "local_endTime")
        let interval = localStore.integer(forKey: "local_intervalMinutes")
        let typeString = localStore.string(forKey: "local_notificationType")
        
        if startTimestamp == 0 {
            self.savedStartTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            self.savedEndTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
            self.savedInterval = 30
            self.savedNotificationType = .both
        } else {
            self.savedStartTime = Date(timeIntervalSince1970: startTimestamp)
            self.savedEndTime = Date(timeIntervalSince1970: endTimestamp)
            self.savedInterval = interval
            if let typeString = typeString, let type = NotificationType(rawValue: typeString) {
                self.savedNotificationType = type
            }
        }
    }
    
    func startReminders(from start: Date, to end: Date, intervalMinutes: Int, type: NotificationType) {
        stopReminders()
        
        saveSettingsToLocalStorage(start: start, end: end, interval: intervalMinutes, type: type)
        
        let calendar = Calendar.current
        let now = Date()
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        guard let startHour = startComponents.hour, let startMinute = startComponents.minute,
              let endHour = endComponents.hour, let endMinute = endComponents.minute else { return }
        
        guard let todayStart = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
              var todayEnd = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) else { return }
        
        if todayEnd <= todayStart {
            todayEnd = calendar.date(byAdding: .day, value: 1, to: todayEnd) ?? todayEnd
        }
        
        var referenceDate = now
        if now < todayStart {
            referenceDate = todayStart
        } else if now > todayEnd {
            guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
                  let tomorrowEnd = calendar.date(byAdding: .day, value: 1, to: todayEnd) else { return }
            referenceDate = tomorrowStart
            todayEnd = tomorrowEnd
        }
        
        reminderTimes.removeAll()
        var currentTargetDate = calendar.date(byAdding: .minute, value: intervalMinutes, to: referenceDate) ?? referenceDate
        var count = 0
        
        while currentTargetDate <= todayEnd && count < 60 {
            reminderTimes.append(currentTargetDate)
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentTargetDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = "Интервальный таймер"
            content.body = "Пора сделать перерыв!"
            
            if type == .sound || type == .both {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "fleita.wav"))
            } else {
                content.sound = nil
            }
            
            let request = UNNotificationRequest(identifier: "IntervalReminder_\(count)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
            currentTargetDate = calendar.date(byAdding: .minute, value: intervalMinutes, to: currentTargetDate) ?? currentTargetDate
            count += 1
        }
        
        guard !reminderTimes.isEmpty else { return }
        
        self.totalIntervalSeconds = Double(intervalMinutes * 60)
        self.isActive = true
        
        // --- ИСПРАВЛЕННЫЕ СТРОКИ 140 И 141 ---
        if let nextReminder = reminderTimes.first {
            // Передаем строго expireDate в ContentState и пустые атрибуты
            let initialState = TimerWidgetAttributes.ContentState(expireDate: nextReminder)
            let attributes = TimerWidgetAttributes()
            let activityContent = ActivityContent(state: initialState, staleDate: nil)
            
            self.lastUpdatedActivityDate = nextReminder
            
            DispatchQueue.main.async {
                if let activity = try? Activity.request(attributes: attributes, content: activityContent) {
                    self.currentActivity = activity
                }
            }
        }
        
        startInternalTimer()
    }
    
    func stopReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        internalTimer?.invalidate()
        internalTimer = nil
        secondsToNextReminder = nil
        isActive = false
        endLiveActivity()
        self.lastUpdatedActivityDate = nil
    }
    
    private func startInternalTimer() {
        updateCountdown()
        internalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        let now = Date()
        let activeReminders = reminderTimes.filter { $0 > now }
        
        if let nextReminder = activeReminders.first {
            let diff = Int(nextReminder.timeIntervalSince(now))
            DispatchQueue.main.async { self.secondsToNextReminder = diff }
            
            // --- ИСПРАВЛЕННАЯ СТРОКА 185 (ОБНОВЛЕНИЕ ПРИ СМЕНЕ ИНТЕРВАЛА) ---
            if currentActivity != nil && nextReminder != lastUpdatedActivityDate {
                lastUpdatedActivityDate = nextReminder
                
                let updatedState = TimerWidgetAttributes.ContentState(expireDate: nextReminder)
                let updatedContent = ActivityContent(state: updatedState, staleDate: nil)
                
                Task {
                    await currentActivity?.update(updatedContent)
                }
            }
        } else {
            DispatchQueue.main.async { self.secondsToNextReminder = nil }
            endLiveActivity()
        }
    }
    
    func endLiveActivity() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
