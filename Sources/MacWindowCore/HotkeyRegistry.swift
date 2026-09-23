import Carbon.HIToolbox

/// A thin shell over Carbon's system-wide hot keys, which keep working while another app is in front.
@MainActor
public final class HotkeyRegistry {
    /// Marks the hot keys as ours; any four bytes will do as long as they are consistent.
    private static let signature: OSType = 0x6D77_696E  // 'mwin'

    private let onAction: (WindowAction) -> Void
    private var actions: [UInt32: WindowAction] = [:]
    private var hotKeys: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    public init(onAction: @escaping (WindowAction) -> Void) {
        self.onAction = onAction
    }

    /// Returns the actions whose shortcut could not be taken, which happens when another app —
    /// Rectangle itself, say — already holds it.
    @discardableResult
    public func start(_ registered: [WindowAction] = WindowAction.allCases) -> [WindowAction] {
        var pressed = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }

                var id = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
                guard status == noErr else { return status }

                let registry = Unmanaged<HotkeyRegistry>.fromOpaque(context).takeUnretainedValue()
                // Carbon delivers on the thread that runs the event loop, which is the main one.
                MainActor.assumeIsolated { registry.dispatch(id.id) }
                return noErr
            },
            1, &pressed, Unmanaged.passUnretained(self).toOpaque(), &handler)

        return registered.enumerated().compactMap { index, action in
            let id = UInt32(index + 1)
            actions[id] = action

            var hotKey: EventHotKeyRef?
            let status = RegisterEventHotKey(
                action.shortcut.keyCode, action.shortcut.modifiers,
                EventHotKeyID(signature: Self.signature, id: id),
                GetEventDispatcherTarget(), 0, &hotKey)

            guard status == noErr, let hotKey else { return action }
            hotKeys.append(hotKey)
            return nil
        }
    }

    private func dispatch(_ id: UInt32) {
        guard let action = actions[id] else { return }
        onAction(action)
    }

    /// Hands the shortcuts back to whoever wants them next.
    public func stop() {
        hotKeys.forEach { UnregisterEventHotKey($0) }
        hotKeys.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }
}
