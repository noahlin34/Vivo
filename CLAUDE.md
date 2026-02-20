# Vivo — Claude Instructions

## Project Overview

Vivo is a personal health management iOS app built with SwiftUI + SwiftData + CloudKit. It lets users track medications, doctors, appointments, and health notes, synced privately via iCloud.

## Key Facts

- **Bundle ID**: `com.noahlin.Vivo`
- **CloudKit container**: `iCloud.com.noahlin.Vivo`
- **Minimum deployment**: iOS 18.0
- **Swift version**: 5.0
- **Team**: TT5ULK557T
- **Project type**: Xcode 26 file-system-synchronized (all `.swift` files in subdirectories are auto-included — no need to add files to the project manually)

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
├── ContentView.swift      # TabView root, UITabBarAppearance setup
├── Models/
│   ├── Medication.swift
│   ├── Doctor.swift
│   ├── Appointment.swift
│   └── HealthNote.swift
└── Views/
    ├── SharedComponents.swift   # Design tokens, shared views, helpers
    ├── HomeView.swift
    ├── MedicationsView.swift
    ├── DoctorsView.swift
    ├── AppointmentsView.swift
    └── NotesView.swift
```

## Data Models (SwiftData)

All models use `@Model final class` and are registered in `VivoApp.swift`.

```swift
Medication:   name, dosage, frequency, scheduledTime(Date), colorIndex(Int 0-5), createdAt
Doctor:       name, specialty, phone, email, address, colorIndex(Int), createdAt
Appointment:  title, doctorName, date(Date), time(String), location, notes, createdAt
HealthNote:   title, content, category(String), createdAt
```

CloudKit sync is configured with `.private("iCloud.com.noahlin.Vivo")`. Testing sync requires a physical device signed into iCloud with the container created in the Apple Developer Portal.

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
```

### Per-Tab Gradient Colors

| Tab          | Gradient              |
|--------------|-----------------------|
| Home (hero)  | teal → green → cyan   |
| Meds         | teal → green          |
| Doctors      | amber → yellow        |
| Appointments | cyan → light cyan     |
| Notes        | purple → lavender     |

### Medication Color Palette (`colorIndex`)

`Color.medColor(index)` — 0=teal, 1=green, 2=amber, 3=purple, 4=cyan, 5=rose(`#E11D48`)

### Note Categories

`CategoryStyle.forCategory(_ c: String)` returns `.color` and `.gradient`:
- Vitals → rose, Medications → teal, Lifestyle → green, Questions → amber, Symptoms → purple, General → gray

### Doctor Specialties

`SpecialtyStyle.forSpecialty(_ s: String)` returns `.color` and `.gradient`:
- Primary Care → teal, Cardiologist → rose, Endocrinologist → purple, Dermatologist → amber, Neurologist → indigo, Orthopedist → green, Pediatrician → cyan

### Typography

- Page/section titles: `.fontDesign(.serif)` (or `.font(.system(size: X, weight: .regular, design: .serif))`)
- Body text: system font

### Cards

```swift
.background(Color.cardBg)
.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
.warmShadow()   // shadow(color: Color(hex:"1A1612").opacity(0.06), radius:8, x:0, y:2)
// Large variant:
.warmShadowLg() // shadow(color: ..., opacity(0.08), radius:16, x:0, y:4)
```

### Tab Bar

Configured via `UITabBarAppearance` in `ContentView.init()`. Background is `#F6F2EC` (warm cream). Active tint is `Color.primaryTeal` (`.tint(Color(hex: "0D7C66"))`).

## Shared Components (SharedComponents.swift)

Reuse these — don't recreate them inline:

- `GradientAddButton(gradient:, action:)` — floating `+` button with gradient background
- `GradientDateBadge(date:, isPast:)` — teal gradient date badge; muted style when past
- `MedicationCardRow(medication:)` — color stripe left + pill icon card row
- `DoctorCardRow(doctor:)` — specialty gradient avatar card row
- `AppointmentCardRow(appointment:, showChevron:)` — date badge + title/doctor row
- `NoteCard(note:, onDelete:)` — gradient top bar + swipe-to-delete + context menu
- `CategoryChip(title:, gradient:, isSelected:, action:)` — filter pill
- `SectionLabel(title:, dotColor:)` — uppercase section header with dot
- `WarmCard` — plain white card with corner radius and warm shadow

## Hero Safe Area Pattern

The home screen hero extends the gradient behind the Dynamic Island. The pattern used:

```swift
// On the ScrollView:
.ignoresSafeArea(edges: .top)

// Hero content uses dynamic top padding:
private var topSafeArea: CGFloat {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
        .windows.first?.safeAreaInsets.top ?? 0
}
// Applied as: .padding(.top, topSafeArea + 16)

// Hero background gradient:
.ignoresSafeArea(edges: .top)
```

Do NOT use a `GeometryReader` inside an `ignoresSafeArea` context to measure safe area insets — it will return 0. Use the UIKit `UIWindowScene` approach above.

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

### SourceKit false positives

SourceKit sometimes reports "Cannot find type 'Medication' in scope" etc. when editing individual files in isolation. These are not real compiler errors — `xcodebuild` will succeed. Always verify with an actual build.

### UIColor from custom Color

Don't use `UIColor(Color(hex:))` — it can cause SourceKit errors. Use direct RGB instead:

```swift
UIColor(red: 246/255, green: 242/255, blue: 236/255, alpha: 0.97)
```

## Navigation & Sheets Pattern

Each tab view uses:
- `@State private var selected: ModelType? = nil` for detail/edit sheets
- `.sheet(item: $selected)` for bottom sheets
- `.presentationDetents([.medium])` or `.large` depending on content
- Swipe-to-delete via `.swipeActions(edge: .trailing)` with `role: .destructive`

## CloudKit Notes

- Container `iCloud.com.noahlin.Vivo` must exist in Apple Developer Portal → Identifiers → iCloud Containers
- App ID must have iCloud (CloudKit) capability enabled
- CloudKit sync only works on a physical device signed into iCloud (not simulator)
