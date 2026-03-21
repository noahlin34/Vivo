# Vivo — Claude Instructions

## Project Overview

Vivo is a personal health management iOS app built with SwiftUI + SwiftData. It lets users track medications, doctors, appointments, health notes, and vitals, stored locally on-device.

## Key Facts

- **Bundle ID**: `com.noahlin.Vivo`
- **Minimum deployment**: iOS 18.0
- **Swift version**: 5.0
- **Team**: TT5ULK557T
- **Project type**: Xcode 26 file-system-synchronized (all `.swift` files in subdirectories are auto-included — no need to add files to the project manually)

## Git Workflow

Use **atomic commits** for essentially everything — one logical change per commit. Do not bundle multiple unrelated changes into a single commit. Examples of correct granularity:

- Adding a new field to a model → one commit
- Updating the UI to use that field → separate commit
- A bug fix → its own commit, separate from any feature work
- Updating a shared component → separate from updating the views that use it

Each commit should build and be coherent on its own. After completing each logical unit of work, commit before moving to the next.

## Building & Testing

```bash
# Build for simulator
xcodebuild -scheme Vivo -destination 'generic/platform=iOS Simulator' build

# Check available simulators
xcrun simctl list devices available
```

After making changes, always run a build to confirm no compiler errors before finishing.

## Project Structure

```
Vivo/
├── VivoApp.swift          # @main, plain ModelContainer (local SwiftData, no CloudKit)
├── ContentView.swift      # TabView root + CustomTabBar (5 tabs)
├── Info.plist             # UILaunchScreen, ITSAppUsesNonExemptEncryption
├── Vivo.entitlements      # HealthKit only
├── Models/
│   ├── Medication.swift
│   ├── Doctor.swift
│   ├── Appointment.swift
│   ├── HealthNote.swift
│   └── VitalRecord.swift
├── Services/
│   ├── HealthKitService.swift     # Read-only HealthKit import
│   └── NotificationService.swift  # ensureAuthorizedThenSchedule helper
└── Views/
    ├── SharedComponents.swift   # Design tokens, shared views, helpers
    ├── LaunchGateView.swift     # Onboarding gate (@AppStorage hasCompletedOnboarding)
    ├── OnboardingView.swift     # 4-page swipeable onboarding flow
    ├── HomeView.swift
    ├── MedicationsView.swift
    ├── CareView.swift           # Combined doctors + appointments
    ├── DoctorsView.swift        # Detail/Add/Edit sheets for doctors
    ├── AppointmentsView.swift   # Detail/Add/Edit sheets for appointments
    ├── VitalsView.swift
    └── NotesView.swift
```

## Data Models (SwiftData)

All models use `@Model final class` and are registered in `VivoApp.swift`.

### Medication

```swift
name, dosage, frequency, scheduledTime(Date), scheduledTime2(Date?), scheduledTime3(Date?),
colorIndex(Int 0-5), notes(String), takenDates([Date]), pillCount(Int?),
reminderOffset(Int), createdAt
```

`reminderOffset` maps to `MedicationReminderOffset` (in MedicationsView.swift): `-1`=None, `0`=At dose time, `5/15/30/60`=minutes before.

Computed properties:
- `dosesRequired: Int` — 0 for "As needed", 1/2/3 based on frequency
- `dosesTakenToday: Int` — count of `takenDates` entries from today
- `isTakenToday: Bool` — true when all required doses are logged
- `daysRemaining: Int?` — `pillCount / dosesRequired` (nil if not tracking)
- `isLowSupply: Bool` — true when <= 7 days remain

### Doctor

```swift
name, specialty, phone, email, address, colorIndex(Int),
appointments([Appointment]?, @Relationship deleteRule: .nullify, inverse: \Appointment.doctor),
createdAt
```

Note: `colorIndex` exists on the model but doctor colors in the UI are derived from specialty via `SpecialtyStyle.forSpecialty()`.

### Appointment

```swift
title, doctorName, doctor(Doctor?, @Relationship deleteRule: .nullify),
date(Date), location, notes, reminderOption(String), createdAt
```

Computed: `displayDoctorName` — returns `doctor?.name ?? doctorName`

`reminderOption` maps to `AppointmentReminderOption` (in AppointmentsView.swift): `"none"`, `"at_time"`, `"5_min"`, `"15_min"`, `"30_min"`, `"1_hour"`, `"2_hours"`, `"1_day"`, `"1_day_1_hour"` (default).

### HealthNote

```swift
title, content, category(String, default "General"), createdAt
```

Categories: "Vitals", "Medications", "Lifestyle", "Questions", "Symptoms", "General"

### VitalRecord

```swift
type(String), value(Double), secondaryValue(Double?), unit(String),
notes(String), source(String, default "manual"), recordedAt(Date), createdAt
```

`source` field: `"manual"` (default, user-entered) or `"healthkit"` (imported from Apple Health). HealthKit records are read-only in the UI (no Edit/Delete).

`VitalType` enum (not stored — helper): `bloodPressure`, `weight`, `heartRate`, `bloodSugar` with `icon`, `unit`, `hasDualValue`, `formatValue()`, `color`/`gradient`. Blood Pressure uses `secondaryValue` for diastolic.

### HealthKit Integration

Read-only, on-demand import of vitals from Apple Health.

- **Service**: `HealthKitService` (`Vivo/Services/HealthKitService.swift`) — `@Observable` class
- **Supported types**: Blood Pressure (via `HKCorrelationQuery`), Weight (lbs), Heart Rate (bpm), Blood Sugar (mg/dL)
- **Flow**: user taps heart button in VitalsView → authorize → fetch last 30 days → dedup → insert with `source: "healthkit"`
- **Dedup strategy**: skip import if a VitalRecord with same type exists within 60 seconds of the HealthKit sample date
- **Simulator-safe**: `isAvailable` returns false via `#if targetEnvironment(simulator)`, import button hidden
- **Read-only**: HealthKit records show "Source: Apple Health" in detail sheet, Edit/Delete buttons hidden
- **No writes**: Vivo never writes to HealthKit; manual entries stay in SwiftData only
- **No background sync**: no `HKObserverQuery` — import is user-initiated only

## Notification Systems

Authorization is handled by `NotificationService.ensureAuthorizedThenSchedule` (in `Services/NotificationService.swift`), which requests permission if needed before scheduling.

### MedicationNotifications (in MedicationsView.swift)

- Base ID derived from `medication.createdAt.timeIntervalSince1970`
- "As needed" meds: no notifications
- `reminderOffset == -1` (None): notifications cancelled, none scheduled
- Scheduled meds: one repeating `UNCalendarNotificationTrigger` per dose time, fired `reminderOffset` minutes before each dose
  - Once daily: fires relative to `scheduledTime`
  - Twice daily: fires relative to `scheduledTime` and `scheduledTime2`
  - Three times daily: fires relative to `scheduledTime`, `scheduledTime2`, `scheduledTime3`
- Identifiers: `"\(base)-0"`, `"\(base)-1"`, `"\(base)-2"`

### AppointmentNotifications (in AppointmentsView.swift)

- Base ID derived from `appointment.createdAt.timeIntervalSince1970`
- Fires based on `appointment.reminderOption` — one non-repeating trigger per offset in `AppointmentReminderOption.offsets`
- `"none"` option: no notifications scheduled
- Body format: `"\(title) with \(displayDoctorName)"`
- Only schedules if fire time is in the future
- Identifiers: `"\(base)-0"`, `"\(base)-1"` (index into offsets array)
- Cancel also removes legacy `"\(base)-day"` / `"\(base)-hour"` identifiers for migration safety

Both notification enums have `schedule(for:)` and `cancel(for:)` static methods.

## Onboarding

`LaunchGateView` (in `LaunchGateView.swift`) is the app's entry point. It reads `@AppStorage("hasCompletedOnboarding")` and shows either `OnboardingView` or `ContentView` with a `.easeInOut` opacity transition.

`OnboardingView`:
- 4 swipeable pages (TabView `.page` style): Welcome → Medications → Care → Notifications
- Skip button appears on pages 2–4
- Animated dot indicator (selected dot 22pt wide, others 8pt)
- "Next" button advances; "Get Started" on final page sets `hasCompletedOnboarding = true`
- Each page layout is wrapped in `ScrollView(.scrollBounceBehavior(.basedOnSize))` as a safety net for short screens

## Design System

All design tokens live in `SharedComponents.swift` as `Color` static extensions. Always use these — never hardcode hex strings in view files.

### Color Tokens

Core tokens are **adaptive** (light/dark) via `Color.adaptive(light:dark:)`, which uses a `UIColor` dynamic trait provider internally. Accent/gradient colors are static — they work on both modes without adaptation.

```swift
// Adaptive tokens (light / dark)
Color.bg           // #F6F2EC / #1C1816 — app background
Color.cardBg       // #FFFFFF / #2A2520 — card surfaces
Color.mutedBg      // #E8E2D9 / #231F1B — subtle backgrounds
Color.nearBlack    // #1A1612 / #EBE6DF — primary text
Color.mutedFg      // #8C8279 / #9E958C — secondary/muted text
Color.destructive  // #DC2626 / #EF4444 — delete buttons (brighter in dark)

// Static tokens (same in both modes)
Color.primaryTeal  // #0D7C66 — primary accent

// Gradient palette (static)
Color.tealStart / .tealEnd       // #0D7C66 / #059669
Color.amberStart / .amberEnd     // #D97706 / #F59E0B
Color.cyanStart / .cyanEnd       // #0891B2 / #06B6D4
Color.purpleStart / .purpleEnd   // #7C3AED / #A78BFA
Color.roseStart / .roseEnd       // #E11D48 / #F43F5E
```

**Dark mode notes:**
- App follows system appearance — no in-app toggle
- `.white` on gradient backgrounds (hero, buttons, avatars, date badges) is intentional in both modes
- Shadows are unchanged — they naturally fade on dark surfaces
- To add new adaptive colors: `Color.adaptive(light: "HEXLIGHT", dark: "HEXDARK")`
- Do NOT use `UIColor(Color(hex:))` — use the private `uiColor(hex:)` helper (see CLAUDE.md pitfalls)

### Per-Tab Gradient Colors

| Tab          | Gradient              |
|--------------|-----------------------|
| Home (hero)  | teal → green → cyan   |
| Meds         | teal → green          |
| Care         | amber → yellow        |
| Vitals       | rose → light rose     |
| Notes        | purple → lavender     |

### Medication Color Palette (`colorIndex`)

`Color.medColor(index)` — 0=teal, 1=green, 2=amber, 3=purple, 4=cyan, 5=rose(`#E11D48`)

`Color.medHexColors` — array of 6 hex strings in the same order, used for color picker UI.

### Style Lookups

`SpecialtyStyle.forSpecialty(_ s: String)` returns `.color` and `.gradient`:
- Primary Care → teal, Cardiologist → rose, Endocrinologist → purple, Dermatologist → amber, Neurologist → indigo, Orthopedist → green, Pediatrician → cyan

`CategoryStyle.forCategory(_ c: String)` returns `.color` and `.gradient`:
- Vitals → rose, Medications → teal, Lifestyle → green, Questions → amber, Symptoms → purple, General → gray

`VitalTypeStyle.forType(_ t: String)` returns `.color`, `.gradient`, `.icon`:
- Blood Pressure → rose/heart.fill, Weight → cyan/scalemass.fill, Heart Rate → rose/waveform.path.ecg, Blood Sugar → purple/drop.fill

### Typography

- Page/section titles: `.fontDesign(.serif)` (or `.font(.system(size: X, weight: .regular, design: .serif))`)
- Body text: system font

### Cards

Each card component is **self-contained** — it includes its own background, clip shape, and shadow. Do NOT wrap card rows in an additional `WarmCard`; just use `VStack(spacing: 12)` directly.

```swift
.background(Color.cardBg)
.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
.warmShadow()   // shadow(color: Color(hex:"1A1612").opacity(0.06), radius:8, x:0, y:2)
// Large variant:
.warmShadowLg() // shadow(color: ..., opacity(0.08), radius:16, x:0, y:4)
```

### Tab Bar

The system tab bar is **hidden** (`UITabBar.appearance().isHidden = true` in `ContentView.init()`). A custom `CustomTabBar` is injected via `.safeAreaInset(edge: .bottom, spacing: 0)` on the `TabView`.

`CustomTabBar` features (5 tabs: Home, Meds, Care, Vitals, Notes):
- Frosted glass background: `Color.cardBg.opacity(0.7)` + `.ultraThinMaterial`, extends behind home indicator via `.ignoresSafeArea(edges: .bottom)`
- 24pt gradient fade above the bar (non-interactive)
- **Active tab**: 18pt icon in per-tab color + 36×32 glow background + label (9pt medium) + `-2pt` offset
- **Inactive tab**: 18pt muted icon only — **no label** (labels appear only on active tab with opacity+scale transition)
- Per-tab accent colors: Home=teal, Meds=teal, Care=amber, Vitals=rose, Notes=purple
- Spring animation + light haptic on tap

## Shared Components (SharedComponents.swift)

Reuse these — don't recreate them inline:

- `GradientAddButton(gradient:, action:)` — floating `+` button, 16pt corner radius, gradient background
- `GradientDateBadge(date:, isPast:, isToday:)` — 52×52pt date badge; muted when past, amber gradient when today, teal-cyan otherwise
- `MedicationCardRow(medication:, onToggle:)` — self-contained card: 6px color stripe + pill icon + name/dosage/time; optional dose indicator (checkmark, progress dots, or +counter); strikethrough when taken; supply warning when low
- `DoctorCardRow(doctor:)` — self-contained card: specialty gradient avatar + name/specialty + phone icon
- `AppointmentCardRow(appointment:, showTodayBadge:)` — self-contained card: date badge + title/doctor; amber top stripe + "Today" pill when today; 0.55 opacity when past
- `VitalCardRow(vital:)` — self-contained card: gradient stripe + type icon + formatted value/time
- `NoteCard(note:, onDelete:)` — gradient top bar + swipe-to-delete + context menu
- `CategoryChip(title:, gradient:, isSelected:, action:)` — filter pill; gradient bg when selected, white when not
- `SectionLabel(title:, dotColor:)` — uppercase section header with colored dot
- `WarmCard` — generic container: white background, 18pt corner radius, warm shadow

## Hero Safe Area Pattern

The home screen hero extends the gradient behind the Dynamic Island. The approach:

```swift
// 1. ScrollView ignores top safe area so content can start from y=0:
ScrollView { ... }
    .ignoresSafeArea(edges: .top)

// 2. Hero content uses UIKit to measure the safe area (NOT GeometryReader):
@State private var topSafeArea: CGFloat = 0

.onAppear {
    topSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
        .windows.first?.safeAreaInsets.top ?? 0
}

// 3. Hero content is pushed below the status bar:
.padding(.top, topSafeArea + 16)

// 4. Hero background gradient extends behind the status bar:
.background {
    LinearGradient(...)
        .ignoresSafeArea(edges: .top)
}
```

**Do NOT** use `GeometryReader` inside an `ignoresSafeArea` context — it returns 0.

## Bottom Scroll Clearance

The custom tab bar is ~100pt tall. The `safeAreaInset` that injects it does **not** reliably propagate as scroll content inset when the parent ScrollView uses `.ignoresSafeArea(edges: .top)`. All scroll views must include an explicit bottom spacer:

```swift
Spacer(minLength: 100)
```

This is present in every tab's scroll content (HomeView, MedicationsView, DoctorsView, AppointmentsView, VitalsView, NotesView). Do not reduce this value.

## Common SwiftUI Pitfalls in This Project

### `foregroundStyle` with custom Color tokens

Swift cannot resolve shorthand dot-syntax for custom `Color` static members when the generic parameter is `ShapeStyle`. Always use the full form:

```swift
// WRONG — will not compile
.foregroundStyle(.nearBlack)
.foregroundStyle(.mutedFg)

// CORRECT
.foregroundStyle(Color.nearBlack)
.foregroundStyle(Color.mutedFg)
```

This applies to all custom Color tokens. `.white`, `.black`, and built-in colors work fine with shorthand.

### `.background { Group { if ... AnyShapeStyle } }` doesn't compile

When using conditional backgrounds, use the `@ViewBuilder` trailing closure form with concrete view types:

```swift
// WRONG — generic parameter inference fails
.background(Group { if ... { AnyShapeStyle(...) } })

// CORRECT
.background {
    if condition {
        Color.mutedBg
    } else {
        LinearGradient(...)
    }
}
```

### SourceKit false positives

SourceKit frequently reports "Cannot find type 'Medication' in scope", "Type 'Color' has no member 'nearBlack'", etc. when editing individual files in isolation. These are **not real errors** — `xcodebuild` will succeed. Always verify with an actual build before assuming something is broken.

### UIColor from custom Color

Don't use `UIColor(Color(hex:))` — it can cause SourceKit errors. Use direct RGB instead:

```swift
UIColor(red: 246/255, green: 242/255, blue: 236/255, alpha: 0.97)
```

### `Menu` label animation jitter (text flies left/center on open/close)

SwiftUI's `Menu` animates its label from the view's natural (unconstrained) size to its laid-out size on every open/close. If the container holding the label has no fixed width, the text visibly slides around.

**Root cause:** the `VStack` or other container wrapping the `Menu` label doesn't have a constrained width, so SwiftUI can't establish a stable frame before animating.

**Fix:** give the label's inner container `.frame(maxWidth: .infinity, alignment: .leading)` so it has a fixed anchor, and add `.contentShape(Rectangle())` so the full row is tappable:

```swift
// WRONG — VStack has no width constraint; label jitters on open/close
Menu { ... } label: {
    HStack {
        Text(selectedValue)
        Spacer()
        Image(systemName: "chevron.up.chevron.down")
    }
}
.buttonStyle(.plain)

// CORRECT — VStack anchors the width; no animation jitter
Menu { ... } label: {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text("Label")
            Text(selectedValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: "chevron.up.chevron.down")
    }
    .contentShape(Rectangle())
}
.buttonStyle(.plain)
```

Do **not** work around this by replacing `Menu` with a `Button` that opens a separate sheet picker — use `Menu` with the frame fix above.

## Navigation & Sheets Pattern

Each tab view uses:
- `@State private var selected: ModelType? = nil` for detail sheets
- `.sheet(item: $selected)` — sheet appears when non-nil, dismissed by setting to nil
- Detail sheets: `.presentationDetents([.medium])` or `.presentationDetents([.medium, .large])` + `.presentationCornerRadius(24)`
- Full-content sheets (notes, edit forms): `.presentationDetents([.large])` or no detent
- Each detail sheet has an **Edit** button in the toolbar that opens the corresponding `EditXxxView`
- Deleting: red button in detail sheet calls `onDelete()` closure + `dismiss()`
- `NoteCard` has **built-in swipe-to-delete** (`.swipeActions`) and a context menu delete — both call `onDelete()`
- `MedicationCardRow` in MedicationsView has swipe-to-delete with `confirmationDialog`
- Other list rows (Doctors, Appointments, Vitals) — delete only from the detail sheet

## Tab-Specific Features

### HomeView (tab 0)
- Receives a `selectedTab: Binding<Int>` parameter — used by quick-pill buttons to navigate to other tabs
- **Hero section**: gradient background with date, "My Health" title, medication progress ring (animated), next appointment chip
- **Quick pills** (4): Meds(1), Care(2), Vitals(3), Notes(4) — each shows icon + label + count
- **Today's Medications**: first 3 meds with "See all" when > 3
- **Upcoming**: next 3 appointments with amber "Today" badge
- **Care Team**: horizontal scroll of doctor cards (if non-empty)
- **Recent Vitals**: last 3 readings with "See all" when > 3
- **Recent Notes**: last 2 notes

### MedicationsView (tab 1)
- **Search bar** (filters by name)
- **Time-of-day grouping**: Morning (5–12), Afternoon (12–17), Evening (17–21), Night (other) — each group shows remaining dose count
- **Dose toggle** on each card: checkmark for once daily, progress dots for multi-dose, +counter for as-needed
- **Swipe-to-delete** with confirmation dialog
- **Detail sheet**: 7-day adherence calendar, supply tracking with "Log Refill" button
- **Add/Edit views**: name, dosage, frequency picker, per-dose time pickers (1–3 depending on frequency), reminder offset picker, color picker (6 inline), refill tracking toggle + stepper

### CareView (tab 2)
- Combined doctors + appointments view
- **Search bar** (searches doctors by name/specialty, appointments by title/doctor/location)
- **Menu add button** (+): offers "Add Appointment" and "Add Doctor"
- **Upcoming** section: appointment cards with today badge
- **Care Team** section: doctor cards
- **Past** section: past appointments in reverse chronological order
- Reuses `DoctorDetailSheet`, `AddDoctorView`, `AppointmentDetailSheet`, `AddAppointmentView` from their original files

### VitalsView (tab 3)
- **Search bar** and **type filter chips** (All + 4 vital types) using `CategoryChip`
- Vitals grouped by date (Today, Yesterday, then by formatted date)
- **Detail sheet**: large value display, detail rows, **30-day trend chart** (Swift Charts `LineMark`/`PointMark`); BP shows dual series (systolic/diastolic), others show single line + dashed average rule mark
- **Add view**: type picker, conditional dual-value fields for Blood Pressure, date/time picker, notes

### NotesView (tab 4)
- **Search bar** (`@State private var searchText`) that filters notes by title/content
- **Category filter chips** (`@State private var selectedCategory`) using `CategoryChip` — one chip per category plus "All"
- `NoteCard` handles its own delete UI via swipe-to-delete and context menu
- **Add view**: title, category grid picker (LazyVGrid, 6 adaptive columns), TextEditor for content

## Edit Pattern

All five model types support editing. Each edit view follows the same pattern:

```swift
struct EditFooView: View {
    let foo: Foo
    @Environment(\.dismiss) private var dismiss

    // @State copies initialized from the model:
    @State private var field: Type

    init(foo: Foo) {
        self.foo = foo
        _field = State(initialValue: foo.field)
    }

    private func save() {
        foo.field = field  // mutate @Model directly — SwiftData autosaves
        dismiss()
    }
}
```

SwiftData `@Model` objects are reference types with `@Observable`. Mutating their properties directly is sufficient — no need to call `modelContext.save()`.

## Entitlements & Configuration

**Vivo.entitlements**:
- `com.apple.developer.healthkit`: true (HealthKit read access)
- `com.apple.developer.healthkit.access`: empty array (no specific clinical types)

**Info.plist** (actual file — minimal):
- `ITSAppUsesNonExemptEncryption`: false
- `UILaunchScreen`: `{UIColorName: LaunchBackground}`

`NSHealthShareUsageDescription` is set via `INFOPLIST_KEY_NSHealthShareUsageDescription` in the Xcode project build settings (not in Info.plist directly).

**Assets**: AccentColor + AppIcon in asset catalog. All colors defined in code via `Color(hex:)`, not asset colors.
