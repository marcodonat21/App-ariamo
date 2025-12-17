import Foundation
import EventKit

class CalendarHelper {
    
    private static let eventStore = EKEventStore()
    
    // RICHIESTA PERMESSO CALENDARIO
    static func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Calendar access error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }
    
    // AGGIUNGI ATTIVITÀ AL CALENDARIO
    static func addToCalendar(activity: Activity) {
        requestCalendarAccess { granted in
            guard granted else {
                print("⚠️ Calendar access denied")
                return
            }
            
            // Crea l'evento
            let event = EKEvent(eventStore: eventStore)
            event.title = activity.title
            event.notes = activity.description
            event.location = activity.locationName
            event.startDate = activity.date
            event.endDate = activity.date.addingTimeInterval(2 * 3600) // Durata 2 ore di default
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            // Aggiungi allarmi (24h e 1h prima)
            let alarm24h = EKAlarm(absoluteDate: activity.date.addingTimeInterval(-24 * 3600))
            let alarm1h = EKAlarm(absoluteDate: activity.date.addingTimeInterval(-3600))
            event.alarms = [alarm24h, alarm1h]
            
            // Salva l'evento
            do {
                try eventStore.save(event, span: .thisEvent)
                print("✅ Activity added to Calendar: \(activity.title)")
                
                // Salva l'ID dell'evento per poterlo rimuovere dopo
                UserDefaults.standard.set(event.eventIdentifier, forKey: "calendar_\(activity.id.uuidString)")
            } catch {
                print("❌ Failed to save event: \(error.localizedDescription)")
            }
        }
    }
    
    // RIMUOVI ATTIVITÀ DAL CALENDARIO
    static func removeFromCalendar(activity: Activity) {
        let eventID = UserDefaults.standard.string(forKey: "calendar_\(activity.id.uuidString)")
        
        guard let eventID = eventID,
              let event = eventStore.event(withIdentifier: eventID) else {
            print("⚠️ Event not found in Calendar")
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            UserDefaults.standard.removeObject(forKey: "calendar_\(activity.id.uuidString)")
            print("✅ Activity removed from Calendar: \(activity.title)")
        } catch {
            print("❌ Failed to remove event: \(error.localizedDescription)")
        }
    }
}
