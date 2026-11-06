import Foundation
import UserNotifications

enum VyrethNotifyBell {
    static func vyrethAsk(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { allowed, _ in
            DispatchQueue.main.async { done(allowed) }
        }
    }

    static func vyrethCancelRisk() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["vyreth-risk"])
    }

    static func vyrethRefresh(_ blob: VyrethLedgerBlob) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            center.removePendingNotificationRequests(withIdentifiers: (0..<14).map { "vyreth-day-\($0)" } + ["vyreth-risk"])
            guard blob.profile.reminderOn else { return }
            let notes = VyrethCatalog.book.reminders
            let calendar = VyrethClock.cal
            for offset in 0..<max(notes.count, 1) {
                guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
                var parts = calendar.dateComponents([.year, .month, .day], from: day)
                parts.hour = blob.profile.reminderHour
                parts.minute = blob.profile.reminderMinute
                let content = UNMutableNotificationContent()
                content.title = "Today's slate is waiting"
                content.body = notes.isEmpty ? "Two finished Takes keep the light bright." : notes[offset % notes.count]
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                center.add(UNNotificationRequest(identifier: "vyreth-day-\(offset)", content: content, trigger: trigger))
            }
            guard blob.profile.riskOn else { return }
            let today = VyrethClock.key()
            let day = blob.days.first { $0.date == today }
            let slots = VyrethSlate.kinds(blob.extra)
            let doneCount = slots.filter { kind in
                guard let day else { return false }
                return VyrethSlate.done(kind, day: day, extra: blob.extra)
            }.count
            if day?.counted == true || doneCount >= blob.profile.takesPerDay { return }
            var risk = calendar.dateComponents([.year, .month, .day], from: Date())
            risk.hour = 21
            risk.minute = 30
            let riskBody = UNMutableNotificationContent()
            riskBody.title = "The light is still at risk"
            riskBody.body = "Finish enough Takes before the day ends and the beam stays bright."
            riskBody.sound = .default
            center.add(UNNotificationRequest(identifier: "vyreth-risk", content: riskBody, trigger: UNCalendarNotificationTrigger(dateMatching: risk, repeats: false)))
        }
    }
}
