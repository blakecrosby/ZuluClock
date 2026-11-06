import SwiftUI
import AppKit
import Combine

// MARK: - App

@main
struct ZuluClockApp: App {
    @StateObject private var clock = ZuluClockModel()

    var body: some Scene {
        MenuBarExtra {
            Button("Quit Zulu Clock") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Text(clock.displayText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.menu)
    }
}


// MARK: - Clock Model

@MainActor
final class ZuluClockModel: NSObject, ObservableObject {

    // MARK: Published state

    @Published private(set) var now = Date()


    // MARK: Private properties

    private var timer: Timer?


    // Cache the formatter rather than creating a new one every minute.
    private let zuluFormatter: DateFormatter = {
        let formatter = DateFormatter()

        // en_US_POSIX prevents the user's locale/settings from unexpectedly
        // changing our fixed aviation-style 24-hour representation.
        formatter.locale = Locale(identifier: "en_US_POSIX")

        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm'Z'"

        return formatter
    }()


    // MARK: Initialization

    override init() {
        super.init()

        registerForSystemNotifications()
        synchronizeClock()
    }


    deinit {
        timer?.invalidate()

        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }


    // MARK: Public display value

    var displayText: String {
        zuluFormatter.string(from: now) + dateOffset
    }


    // MARK: Clock synchronization

    private func synchronizeClock() {
        timer?.invalidate()
        timer = nil

        // Update immediately
        now = Date()

        let newTimer = Timer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(clockTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )

        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    @objc
    private func clockTimerFired(_ timer: Timer) {
        now = Date()
    }


    // MARK: System notifications

    private func registerForSystemNotifications() {

        // Mac woke from sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemTimeEnvironmentChanged(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // System clock changed, e.g. automatic synchronization or
        // the user manually changed the time.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemTimeEnvironmentChanged(_:)),
            name: .NSSystemClockDidChange,
            object: nil
        )

        // Local timezone changed.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemTimeEnvironmentChanged(_:)),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
    }


    @objc
    private func systemTimeEnvironmentChanged(_ notification: Notification) {
        synchronizeClock()
    }


    // MARK: Local / Zulu date comparison

    private var dateOffset: String {

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = .current

        var zuluCalendar = Calendar(identifier: .gregorian)
        zuluCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Extract Y/M/D independently in the two time zones.
        let localComponents = localCalendar.dateComponents(
            [.year, .month, .day],
            from: now
        )

        let zuluComponents = zuluCalendar.dateComponents(
            [.year, .month, .day],
            from: now
        )

        /*
         Reconstruct both dates in the same neutral calendar/timezone.

         We're comparing calendar dates, not moments in time. Using a common
         timezone here prevents timezone conversion from affecting the result.
        */
        var comparisonCalendar = Calendar(identifier: .gregorian)
        comparisonCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        guard
            let localDate = comparisonCalendar.date(from: localComponents),
            let zuluDate = comparisonCalendar.date(from: zuluComponents)
        else {
            return ""
        }

        let difference = comparisonCalendar.dateComponents(
            [.day],
            from: localDate,
            to: zuluDate
        ).day ?? 0

        switch difference {
        case 1:
            return " +1"

        case -1:
            return " -1"

        default:
            return ""
        }
    }
}
