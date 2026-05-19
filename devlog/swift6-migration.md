# Swift 6 Migration Log — PasteEcho

## Migration Date: 2026-05-15

## Target
- Xcode 16
- Swift 6.0 language mode
- macOS 15 Sequoia (min deployment: macOS 13 Ventura)

---

## Actor Isolation Fixes

### 1. AppDelegate → @MainActor
- **File**: Sources/App/AppDelegate.swift
- **Issue**: AppDelegate accesses `DataStore.shared` (implicitly `@MainActor`), `NSStatusItem`, `NSPopover`, `NSImage` — all require main thread. Without `@MainActor`, Swift 6 strict concurrency rejects access to main-actor-isolated `DataStore.shared`.
- **Fix**: Added `@MainActor` to class declaration.
- **Impact if unfixed**: Compile error in Swift 6. App would not build.

### 2. ClipboardMonitor → @MainActor
- **File**: Sources/Services/ClipboardMonitor.swift
- **Issue**: `poll()` accesses `NSPasteboard.general` which requires main thread. Timer is scheduled on `.main` RunLoop. Without `@MainActor`, the Timer callback in Swift 6 is considered non-isolated and accessing `NSPasteboard` could be flagged.
- **Fix**: Added `@MainActor` to class declaration.
- **Impact if unfixed**: Compile error or runtime clipboard monitoring failure — UI would not update when clipboard changes.

### 3. SettingsView → @MainActor
- **File**: Sources/Views/SettingsView.swift
- **Issue**: `@StateObject private var dataStore = DataStore.shared` — the property initializer runs during struct init, which is NOT `@MainActor` in Swift 6 by default. Accessing `DataStore.shared` (MainActor) from non-MainActor context = compile error.
- **Fix**: Added `@MainActor` to struct declaration. This ensures the property wrapper is initialized in the correct actor context.
- **Impact if unfixed**: Compile error. Settings window would not open.

### 4. HotkeyManager → @MainActor (FULL CLASS)

**File**: Sources/Services/HotkeyManager.swift

**Initial fix (incomplete)**:
Added `@MainActor` only to `onHotkey` property, leaving the class non-isolated. This caused:
> "Default initializer for 'HotkeyManager' cannot be both nonisolated and main actor-isolated"

**Root cause**: In Swift 6, a stored property marked `@MainActor` in a non-isolated class requires the initializer to be main-actor-isolated. But the class's implicit default initializer is nonisolated — creating an unresolvable conflict.

**Final fix** (3 changes):
1. `@MainActor` on the entire class — this makes all stored properties and methods main-actor-isolated by default, resolving the init conflict
2. `@preconcurrency import Carbon` — tells Swift 6 to apply relaxed sendable checking for Carbon types (`FourCharCode`, `EventHotKeyRef`, etc.), which are C types that haven't been audited for Swift concurrency
3. `nonisolated(unsafe)` on `hotKeySignature` and `hotKeyID` constants — these `FourCharCode`/`UInt32` values are simple integer constants used as immutable IDs in C API calls; marking them `nonisolated(unsafe)` allows them to be read from the Carbon callback (non-isolated context) without a sendable warning
4. `Task { @MainActor in ... }` in the Carbon event handler callback (replaces `DispatchQueue.main.async`) — the Carbon callback runs on an arbitrary thread (C function pointer, `@convention(c)`, non-isolated). Using `Task { @MainActor in }` is the Swift 6 idiomatic way to hop back to the main actor from a non-isolated C callback. This is functionally equivalent to `DispatchQueue.main.async` but the compiler can verify the actor isolation.

**Impact if unfixed**: Swift 6 compile error. App cannot build. Global Cmd+Shift+V shortcut would be unavailable.

**Follow-up fix — deinit isolation conflict**:
After marking the class `@MainActor`, a new error appeared:
> "Call to main actor-isolated instance method 'unregister()' in a synchronous nonisolated context"

at `deinit { unregister() }`. `deinit` is always nonisolated (runs on the thread where the last reference is dropped), but `unregister()` inherited `@MainActor` from the class.

**Resolution**:
1. Marked `eventHotKeyRef` and `eventHandlerRef` as `nonisolated(unsafe)` — these are opaque C pointer types (`EventHotKeyRef?` / `EventHandlerRef?`). The associated cleanup functions (`UnregisterEventHotKey`, `RemoveEventHandler`) are C functions callable from any thread.
2. Marked `unregister()` as `nonisolated` — it only touches `nonisolated(unsafe)` C pointer properties and calls C functions, so it's inherently thread-safe.
3. This allows `deinit` to call `unregister()` safely, regardless of which thread triggers deallocation.

**Actor boundary design**:
- `register()` — `@MainActor` (called from `AppDelegate.setupHotkey()` on main thread)
- `unregister()` — `nonisolated` (callable from `deinit` on any thread)
- `onHotkey` — `@MainActor` (only called from `Task { @MainActor in }` callback)
- All Carbon refs — `nonisolated(unsafe)` (accessed from both sides, C-level thread safety)

### 5. AppViewModel — Already @MainActor
- **File**: Sources/ViewModels/AppViewModel.swift
- **Status**: Already correctly marked `@MainActor`. No changes needed.
- **Note**: `init(dataStore:)` receives a `DataStore` parameter. Since both classes are `@MainActor`, this is safe in Swift 6.

---

## Deprecated API Fixes

### 6. FileManager.replaceItem() upgrade
- **File**: Sources/Services/DataStore.swift
- **Old**: `FileManager.default.replaceItemAt(_:withItemAt:backupItemName:resultingItemURL:)`
- **New**: `FileManager.default.replaceItem(at:withItemAt:backupItemName:options:resultingItemURL:)`
- **Issue**: The old API's `resultingItemURL` parameter type (`AutoreleasingUnsafeMutablePointer<NSURL?>?`) conflicts with Swift 6 strict sendable checking. The `nil` literal fails type inference.
- **Fix**: Use new `replaceItem(at:)` API with explicit `var resultingURL: NSURL?` and `options: []`.
- **Impact if unfixed**: "nil requires a contextual type" compile error. JSON persistence would fail.

### 7. NSImage.lockFocus() → drawingHandler
- **File**: Sources/Services/ThumbnailGenerator.swift
- **Old**: `NSImage(size:).lockFocus()` + `unlockFocus()`
- **New**: `NSImage(size:flipped:drawingHandler:)`
- **Issue**: `lockFocus()` is deprecated in macOS 14+. In macOS 15 / Xcode 16, this generates a deprecation warning that may escalate to error with strict settings.
- **Fix**: Use the modern block-based drawing API.
- **Impact if unfixed**: Compile warning. Thumbnail generation would still work but would break in a future macOS release.

---

## Project Configuration Updates

### 8. project.yml
- `SWIFT_VERSION`: "5.9" → "6.0"
- `xcodeVersion`: "15.0" → "16.0"
- Added: `SWIFT_STRICT_CONCURRENCY: complete`
- Added: `CODE_SIGN_ENTITLEMENTS: Resources/PasteEcho.entitlements`

### 9. New: PasteEcho.entitlements
- Sandbox: disabled (LSUIElement menu bar apps typically run without sandbox)
- Library validation: enabled (prevent unsigned code injection)

---

## Compatibility Matrix

| Component | Status |
|-----------|--------|
| Xcode 16 | Compatible |
| Xcode 15 | Compatible (SWIFT_VERSION can be lowered to "5.9" if needed) |
| macOS 15 Sequoia | Compatible |
| macOS 14 Sonoma | Compatible |
| macOS 13 Ventura | Compatible (min deployment target) |
| Intel Mac | Compatible |
| Apple Silicon | Compatible |
| Swift 6 language mode | Compatible (all fixes applied) |
| Swift 5 language mode | Compatible (backward compatible) |

---

## Remaining Warnings (Non-blocking)

1. Carbon `RegisterEventHotKey` / `InstallEventHandler` — these C APIs are technically deprecated since macOS 10.13 in favor of `NSEvent.addGlobalMonitorForEvents`. However, Carbon HotKeys still work and do NOT require Accessibility permissions (unlike `NSEvent.addGlobalMonitorForEvents`), which is the explicit design choice for PasteEcho. The `HotkeyManager` handles the C-to-Swift actor bridge via `@preconcurrency import Carbon` + `nonisolated(unsafe)` constants + `Task { @MainActor in }` for the callback dispatch.
