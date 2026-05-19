# Architecture Review — PasteEcho

## Review Date: 2026-05-15

---

## Current Architecture

```
┌─────────────────────────────────────────────────────┐
│                   PasteEchoApp (@main)               │
│  SwiftUI App, NSApplicationDelegateAdaptor           │
├─────────────────────────────────────────────────────┤
│                   AppDelegate (@MainActor)            │
│  Coordinator: NSStatusItem + NSPopover + Services    │
├──────────┬──────────┬──────────┬────────────────────┤
│ Monitor  │ DataStore│ HotkeyMgr│ AutoLaunchMgr      │
│ (Service)│ (Service)│ (Service)│ (Service)           │
├──────────┴──────────┴──────────┴────────────────────┤
│                 AppViewModel (@MainActor)            │
│  Presentation logic: sort, filter, search, actions  │
├─────────────────────────────────────────────────────┤
│           SwiftUI Views (PopoverRoot → Cards)        │
└─────────────────────────────────────────────────────┘
```

### Layer Summary

| Layer | Components | Role |
|-------|-----------|------|
| App | PasteEchoApp, AppDelegate | Entry point, lifecycle, coordination |
| Services | ClipboardMonitor, DataStore, HotkeyManager, ThumbnailGenerator, AutoLaunchManager | Core business logic |
| ViewModel | AppViewModel | UI state management, bridging |
| Views | PopoverRootView, ClipboardCard, SearchBar, SettingsView, etc. | Rendering and interaction |
| Models | ClipboardItem, Settings, ContentType, RetentionPeriod | Data structures |
| Extensions | Color+Theme, Date+Relative | Convenience |

---

## Architecture Assessment

### Strengths

1. **Clean Separation**: Clear distinction between Services, ViewModel, and Views
2. **Single Source of Truth**: DataStore singleton ensures all components see the same data
3. **Type Safety**: `@MainActor` on all stateful classes prevents concurrency bugs at compile time
4. **Zero External Dependencies**: 100% native Swift + Apple frameworks
5. **Debounced Persistence**: Combine publisher debounce prevents I/O thrashing during rapid copy operations
6. **Atomic Writes**: Temp-then-replace pattern prevents JSON corruption

### Weaknesses

1. **Timer-based Polling**: 0.5s polling is simple but wastes CPU cycles. Could be improved with `NSWorkspace` notifications or `CGEvent` taps, but these have their own tradeoffs (permissions, complexity).
2. **Singleton DataStore**: While appropriate for v1, singletons make unit testing difficult. Each test shares the same store.
3. **No Protocol Abstractions**: Services have no protocols. This makes mocking/testing harder but keeps the codebase simple.
4. **Inline Thumbnails**: Storing thumbnail `Data` in JSON inflates file size. For 200 items with 2KB thumbnails = ~400KB overhead. Acceptable for now.
5. **Polling Interval**: 0.5s is hardcoded. Could be configurable.

### Threats (Future)

1. **Carbon API Deprecation**: `RegisterEventHotKey` has been deprecated since macOS 10.13. Apple could remove Carbon entirely in a future macOS release.
2. **NSPasteboard Polling**: If Apple restricts pasteboard access from background apps, polling could break.
3. **SwiftData Migration Pressure**: As SwiftData matures, JSON persistence will feel increasingly dated.

---

## Is Architecture Suitable for Long-Term Maintenance?

**Yes, with caveats.**

The current layered architecture is sound for a project of this size. The 20 Swift files are well-organized and follow standard patterns. A solo developer or small team can maintain this comfortably.

For projects exceeding ~50 Swift files, consider:
- Extracting Services into a separate Swift Package
- Adding protocol layers for testability
- Adopting Swift Testing framework

---

## Should We Modularize?

**Not yet.** With 20 files, modularization would add complexity without proportional benefit.

**When to modularize** (heuristics):
- >50 source files
- Multiple developers working on different layers
- Need to share code with a companion app (e.g., iOS widget)

**If modularizing, recommended package split**:
```
PasteEchoCore/       (Models + DataStore + ClipboardMonitor)
PasteEchoUI/         (Views + ViewModels)
PasteEchoApp/        (App entry + AppDelegate)
```

---

## Should We Continue Using XcodeGen?

**Yes.** XcodeGen is the right choice for this project:

- **No merge conflicts**: `.xcodeproj` is binary; `project.yml` is text
- **CI-friendly**: `xcodegen generate` + `xcodebuild` is scriptable
- **SweetPad/VSCode**: Works well with file-based project definition
- **Onboarding**: New developers run `xcodegen generate` once

**Alternatives considered**:
| Tool | Verdict |
|------|---------|
| Tuist | Overkill for a single-target project |
| SPM (Package.swift) | macOS apps can't use SPM as the sole project (no asset catalog support) |
| Manual .xcodeproj | Fragile, merge conflicts, not VCS-friendly |

---

## Should We Introduce SwiftData / CoreData?

**Not for v1.** Rationale:

| Factor | JSON (current) | SwiftData / CoreData |
|--------|---------------|---------------------|
| Item count (≤200) | Fast enough | Overkill |
| Image storage | Filesystem (good separation) | Would bloat the database |
| Schema migrations | Manual (not needed yet) | Automatic (adds complexity) |
| iCloud sync | Would need custom implementation | Built-in (but bug-prone) |
| App size / startup | Minimal | Adds framework overhead |
| Debugging | Human-readable JSON | Opaque SQLite |

**When to consider SwiftData**: If clipboard history grows to thousands of items, if iCloud sync is needed, or if the data model becomes relational (tags, folders, etc.).

---

## Recommendations

### Immediate (this phase)
- [x] Fix Swift 6 / Xcode 16 compatibility
- [x] Add entitlements for Hardened Runtime
- [x] Configure strict concurrency checking

### Short-term (next 1-2 sprints)
- [ ] Add app icon PNG to AppIcon.appiconset
- [ ] Configure Team/Signing in Xcode
- [ ] Test on both Intel and Apple Silicon Macs
- [ ] Add keyboard shortcut customization in Settings

### Medium-term (next 3-6 months)
- [ ] Replace Carbon hotkey with `NSEvent.addGlobalMonitorForEvents` (requires Accessibility permission, but future-proof)
- [ ] Add paste preview (larger text/image view on double-click)
- [ ] Performance profiling with Instruments

### Long-term
- [ ] Evaluate SwiftData migration if feature set expands
- [ ] Consider modularization if codebase grows >50 files
- [ ] iCloud sync (if user demand)
