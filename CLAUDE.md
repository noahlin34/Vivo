# Vivo — Claude Instructions

## Project Overview

Vivo is a personal health management iOS app built with SwiftUI + SwiftData + CloudKit. It lets users track medications, doctors, appointments, health notes, and vitals, synced privately via iCloud.

## Key Facts

- **Bundle ID**: `com.noahlin.Vivo`
- **CloudKit container**: `iCloud.com.noahlin.Vivo`
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
├── VivoApp.swift          # @main, ModelContainer + CloudKit config
├── ContentView.swift      # TabView root + CustomTabBar
├── Models/
│   ├── Medication.swift
│   ├── Doctor.swift
│   ├── Appointment.swift
│   ├── HealthNote.swift
│   └── VitalRecord.swift
└── Views/
    ├── SharedComponents.swift   # Design tokens, shared views, helpers
    ├── HomeView.swift
    ├── MedicationsView.swift
    ├── DoctorsView.swift
    ├── AppointmentsView.swift
    ├── VitalsView.swift
    └── NotesView.swift
```

## Data Models (SwiftData)

All models use `@Model final class` and are registered in `VivoApp.swift`.

```swift
Medication:   name, dosage, frequency, scheduledTime(Date), colorIndex(Int 0-5), notes(String), createdAt
Doctor:       name, specialty, phone, email, address, createdAt
Appointment:  title, doctorName, date(Date), time(String), location, notes(String), createdAt
HealthNote:   title, content, category(String), createdAt
VitalRecord:  type(String), value(Double), secondaryValue(Double?), unit(String), notes(String), recordedAt(Date), createdAt
```

`VitalType` enum (not stored — helper): `bloodPressure`, `weight`, `heartRate`, `bloodSugar` with `icon`, `unit`, `hasDualValue`, `formatValue()`, `color`/`gradient`. Blood Pressure uses `secondaryValue` for diastolic.

Note: `Doctor` has no `colorIndex` — doctor color is derived entirely from specialty via `SpecialtyStyle.forSpecialty()`.

CloudKit sync is configured with `.private("iCloud.com.noahlin.Vivo")`. Testing sync requires a physical device signed into iCloud with the container created in the Apple Developer Portal.

**Simulator**: CloudKit is skipped on simulator via `#if targetEnvironment(simulator)` — uses local-only SwiftData storage.

## Design System

All design tokens live in `SharedComponents.swift` as `Color` static extensions. Always use these — never hardcode hex strings in view files.

### Color Tokens

```swift
Color.bg           // #F6F2EC — warm cream, app background
Color.cardBg       // white — card surfaces
Color.mutedBg      // #E8E2D9 — subtle backgrounds
Color.nearBlack    // #1A1612 — primary text
Color.mutedFg      // #8C8279 — secondary/muted text
Color.primaryTeal  // #0D7C66 — primary accent

// Gradient palette
Color.tealStart / .tealEnd       // #0D7C66 / #059669
Color.amberStart / .amberEnd     // #D97706 / #F59E0B
Color.cyanStart / .cyanEnd       // #0891B2 / #06B6D4
Color.purpleStart / .purpleEnd   // #7C3AED / #A78BFA
Color.roseStart / .roseEnd       // #E11D48 / #F43F5E
```

### Per-Tab Gradient Colors

| Tab          | Gradient              |
|--------------|-----------------------|
| Home (hero)  | teal → green → cyan   |
| Meds         | teal → green          |
| Doctors      | amber → yellow        |
| Appointments | cyan → light cyan     |
| Vitals       | rose → light rose     |
| Notes        | purple → lavender     |

### Medication Color Palette (`colorIndex`)

`Color.medColor(index)` — 0=teal, 1=green, 2=amber, 3=purple, 4=cyan, 5=rose(`#E11D48`)

`Color.medHexColors` — array of 6 hex strings in the same order, used for color picker UI.

### Note Categories

`CategoryStyle.forCategory(_ c: String)` returns `.color` and `.gradient`:
- Vitals → rose, Medications → teal, Lifestyle → green, Questions → amber, Symptoms → purple, General → gray

### Doctor Specialties

`SpecialtyStyle.forSpecialty(_ s: String)` returns `.color` and `.gradient`:
- Primary Care → teal, Cardiologist → rose, Endocrinologist → purple, Dermatologist → amber, Neurologist → indigo, Orthopedist → green, Pediatrician → cyan

### Vital Types

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

`CustomTabBar` features:
- Frosted glass background: `Color.white.opacity(0.7)` + `.ultraThinMaterial`, extends behind home indicator via `.ignoresSafeArea(edges: .bottom)`
- 24pt gradient fade above the bar (non-interactive)
- Active tab: teal icon + glow background + dot indicator, `-2pt` offset
- Inactive tab: muted icon, no glow
- Spring animation + light haptic on tap

## Shared Components (SharedComponents.swift)

Reuse these — don't recreate them inline:

- `GradientAddButton(gradient:, action:)` — floating `+` button, 16pt corner radius, gradient background
- `GradientDateBadge(date:, isPast:, isToday:)` — 52×52pt date badge; muted when past, amber gradient when today, teal-cyan otherwise
- `MedicationCardRow(medication:)` — self-contained card: 6px color stripe + pill icon + name/dosage/time
- `DoctorCardRow(doctor:)` — self-contained card: specialty gradient avatar + name/specialty
- `AppointmentCardRow(appointment:, showTodayBadge:)` — self-contained card: date badge + title/doctor; amber top stripe + "Today" pill when today; 0.55 opacity when past
- `VitalCardRow(vital:)` — self-contained card: rose gradient stripe + type icon + formatted value/time
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

## Navigation & Sheets Pattern

Each tab view uses:
- `@State private var selected: ModelType? = nil` for detail sheets
- `.sheet(item: $selected)` — sheet appears when non-nil, dismissed by setting to nil
- Detail sheets: `.presentationDetents([.medium])` + `.presentationCornerRadius(24)`
- Full-content sheets (notes, edit forms): `.presentationDetents([.large])` or no detent
- Each detail sheet has an **Edit** button in the toolbar that opens the corresponding `EditXxxView`
- Deleting: red button in detail sheet calls `onDelete()` closure + `dismiss()`
- `NoteCard` has **built-in swipe-to-delete** (`.swipeActions`) and a context menu delete — both call `onDelete()`
- All other list rows (Medications, Doctors, Appointments) have no swipe-to-delete — delete only from the detail sheet

## Tab-Specific Features

### HomeView
- Receives a `selectedTab: Binding<Int>` parameter — used by quick-pill buttons to navigate to other tabs
- Hero chips show today's med count and next appointment date
- Tab indices: Meds(1), Doctors(2), Appts(3), Vitals(4), Notes(5)

### AppointmentsView
- Divides list into **Upcoming** and **Past** sections using `SectionLabel`
- Past appointments are shown in reverse chronological order and rendered at 0.55 opacity (handled by `AppointmentCardRow`)

### VitalsView
- Has a **search bar** and **type filter chips** (All + 4 vital types) using `CategoryChip`
- Vitals grouped by date (Today, Yesterday, then by formatted date)
- `VitalDetailSheet` shows 30-day trend chart (Swift Charts `LineMark`/`PointMark`); BP shows dual series (systolic/diastolic)
- `AddVitalView` form with type picker and conditional dual-value fields for Blood Pressure

### NotesView
- Has a **search bar** (`@State private var searchText`) that filters notes by title/content
- Has **category filter chips** (`@State private var selectedCategory`) using `CategoryChip` — one chip per category plus "All"
- `NoteCard` handles its own delete UI via swipe-to-delete and context menu

## Edit Pattern

All four model types support editing. Each edit view follows the same pattern:

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

## CloudKit Notes

- Container `iCloud.com.noahlin.Vivo` must exist in Apple Developer Portal → Identifiers → iCloud Containers
- App ID must have iCloud (CloudKit) capability enabled
- CloudKit sync only works on a physical device signed into iCloud (not simulator)
- Simulator uses local-only storage (`#if targetEnvironment(simulator)` skips CloudKit config)
