import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let clipboardMonitor = ClipboardMonitor()
    private let dataStore = DataStore.shared
    private lazy var appViewModel = AppViewModel(dataStore: dataStore)
    private let hotkeyManager = HotkeyManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if dataStore.settings.launchAtLogin {
            AutoLaunchManager.setEnabled(true)
        }

        setupStatusItem()
        setupPopover()
        setupClipboardMonitor()
        setupHotkey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "clipboard.fill",
                accessibilityDescription: "PasteEcho"
            )
            button.action = #selector(togglePopover)
            button.target = self
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
        clipboardMonitor.newCapturePublisher
            .sink { [weak self] capture in
                guard let self = self else { return }

                if let imageData = capture.imageData,
                   let fileName = capture.item.imageFileName {
                    self.dataStore.saveImageData(imageData, fileName: fileName)
                }

                self.dataStore.add(capture.item)
            }
            .store(in: &cancellables)
        clipboardMonitor.start()
    }

    private func setupHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            self?.togglePopover()
        }
        hotkeyManager.register()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
