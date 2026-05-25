import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipboardWindow: NSWindow?
    private var detailWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private let clipboardMonitor = ClipboardMonitor()
    private let dataStore = DataStore.shared
    private lazy var appViewModel = AppViewModel(dataStore: dataStore)
    private let hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if dataStore.settings.launchAtLogin {
            AutoLaunchManager.setEnabled(true)
        }

        setupStatusItem()
        setupPopover()
        setupClipboardMonitor()
        setupHotkey()
        setupWindowPinCallback()
        setupWindowModeObserver()
    }

    private func setupWindowPinCallback() {
        appViewModel.onWindowPinToggled = { [weak self] pinned in
            guard let self else { return }
            if self.dataStore.settings.windowMode == .freeWindow {
                self.clipboardWindow?.level = pinned ? .floating : .normal
            } else {
                self.popover.behavior = pinned ? .applicationDefined : .transient
            }
        }
    }

    private func setupWindowModeObserver() {
        dataStore.onWindowModeChanged = { [weak self] in
            guard let self else { return }
            if self.dataStore.settings.windowMode == .freeWindow {
                if self.popover.isShown {
                    self.popover.performClose(nil)
                }
                self.showFreeWindow()
            } else {
                if let window = self.clipboardWindow, window.isVisible {
                    window.orderOut(nil)
                }
                self.toggleDockedPopover()
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "clipboard.fill",
                accessibilityDescription: "PasteEcho"
            )
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView()
                .environmentObject(appViewModel)
        )
    }

    private func setupClipboardMonitor() {
        clipboardMonitor.onCapture = { [weak self] capture in
            guard let self else { return }
            if let imageData = capture.imageData,
               let fileName = capture.item.imageFileName {
                self.dataStore.saveImageData(imageData, fileName: fileName)
            }
            self.dataStore.add(capture.item)
        }
        clipboardMonitor.start()
    }

    private func setupHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            self?.togglePopover()
        }
        hotkeyManager.register()
    }

    @objc private func handleStatusItemClick() {
        guard let button = statusItem.button,
              let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(
                title: "Settings...",
                action: #selector(openSettingsMenu),
                keyEquivalent: ","
            ))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(
                title: "Quit PasteEcho",
                action: #selector(quitApp),
                keyEquivalent: "q"
            ))
            statusItem.menu = menu
            button.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }

    @objc private func togglePopover() {
        if dataStore.settings.windowMode == .freeWindow {
            toggleFreeWindow()
        } else {
            toggleDockedPopover()
        }
    }

    private func toggleDockedPopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func toggleFreeWindow() {
        if let window = clipboardWindow, window.isVisible {
            window.orderOut(nil)
        } else {
            showFreeWindow()
        }
    }

    private func showFreeWindow() {
        if let window = clipboardWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PasteEcho"
        window.center()
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = NSHostingView(
            rootView: PopoverRootView()
                .environmentObject(appViewModel)
        )
        clipboardWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func openSettingsMenu() {
        showSettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PasteEcho Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: SettingsView()
        )
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func showDetailWindow(for item: ClipboardItem) {
        if let window = detailWindow {
            window.close()
        }

        let defaultWidth: CGFloat = 600
        let defaultHeight: CGFloat = 450
        let savedFrame = UserDefaults.standard.string(forKey: "detailWindowFrame") ?? ""

        var initialRect = NSRect(x: 0, y: 0, width: defaultWidth, height: defaultHeight)
        if !savedFrame.isEmpty {
            initialRect = NSRectFromString(savedFrame)
        }

        let window = NSWindow(
            contentRect: initialRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Detail"
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 320, height: 200)
        window.contentView = NSHostingView(
            rootView: DetailContentView(item: item)
        )
        window.delegate = self
        window.setFrameAutosaveName("PasteEchoDetailWindow")
        detailWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === detailWindow {
            let frameString = NSStringFromRect(window.frame)
            UserDefaults.standard.set(frameString, forKey: "detailWindowFrame")
        }
    }
}
