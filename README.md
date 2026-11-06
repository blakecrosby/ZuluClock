# Zulu Clock

A tiny macOS menu bar app that shows the current time in UTC (Zulu time), formatted aviation-style:

```
14:32Z
```

If the UTC date is different from your local date, a day offset is added after the time:

```
23:15Z +1    ← it's already tomorrow in UTC
01:05Z -1    ← it's still yesterday in UTC
```

## Features

- Lives only in the menu bar: no Dock icon, no window (`LSUIElement`).
- Fixed 24-hour `HH:mm'Z'` format that ignores locale and 12/24-hour settings.
- Monospaced digits, so the menu bar item doesn't shift width as the time changes.
- Shows a `+1` / `-1` date offset when the UTC calendar day differs from the local one.
- Resyncs automatically when the Mac wakes from sleep, the system clock changes, or the time zone changes.
- Click the time to get a **Quit Zulu Clock** menu item.

## Requirements

- macOS 26.2 or later (the project's deployment target)
- Xcode with the macOS 26 SDK to build

## Building

1. Clone the repository:
   ```bash
   git clone https://github.com/blakecrosby/ZuluClock.git
   ```
2. Open `ZuluClock.xcodeproj` in Xcode.
3. Choose the **ZuluClock** scheme and press **⌘R** to run, or use **Product → Archive** to build a copy you can install.

The clock appears in the menu bar right after launch. To have it start automatically, add it under **System Settings → General → Login Items**.

## How it works

The whole app is in [`ZuluClock/ZuluClockApp.swift`](ZuluClock/ZuluClockApp.swift):

- `ZuluClockApp` declares a SwiftUI `MenuBarExtra` whose label is the formatted time.
- `ZuluClockModel` is an `ObservableObject` that updates `now` every second with a `Timer` on the main run loop's `.common` mode, so it keeps ticking while menus are open. It reuses one cached `DateFormatter` set to `en_US_POSIX` and UTC.
- The day offset comes from reading the year, month and day separately in the local and UTC calendars, then comparing those calendar dates in one neutral time zone.
