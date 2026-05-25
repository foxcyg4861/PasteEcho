@preconcurrency import Carbon
import AppKit

@MainActor
final class HotkeyManager {
    var onHotkey: (() -> Void)?

    private nonisolated(unsafe) var eventHotKeyRef: EventHotKeyRef?
    private nonisolated(unsafe) var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature = FourCharCode(0x50454300)
    private let hotKeyID = UInt32(1)

    func register() {
        guard eventHotKeyRef == nil else { return }

        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_V)

        let hotKeyIDStruct = EventHotKeyID(signature: hotKeySignature, id: hotKeyID)

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyIDStruct,
            GetEventDispatcherTarget(),
            0,
            &eventHotKeyRef
        )

        guard registerStatus == noErr else {
            print("PasteEcho: Hotkey registration failed with status \(registerStatus)")
            return
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(-1) }
                let manager = Unmanaged<HotkeyManager>
                    .fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.onHotkey?()
                }
                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            &eventHandlerRef
        )

        if handlerStatus != noErr {
            print("PasteEcho: EventHandler install failed with status \(handlerStatus)")
        }
    }

    nonisolated func unregister() {
        if let ref = eventHotKeyRef {
            UnregisterEventHotKey(ref)
            eventHotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}
