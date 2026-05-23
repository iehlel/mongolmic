import Cocoa
import Carbon

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    
    private var activeEventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onShortcutPressed: (() -> Void)?
    var onShortcutReleased: (() -> Void)?
    
    private init() {}
    
    /// Starts monitoring key events globally. Requires Accessibility permissions.
    func startMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handleEvent(type: type, event: event)
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Event Tap үүсгэж чадсангүй. Accessibility зөвшөөрөл шаардлагатай байж магадгүй.")
            setupBackupGlobalMonitor()
            return
        }
        
        activeEventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    private var isRecording = false
    
    private func handleEvent(type: CGEventType, event: CGEvent) {
        let settings = Settings.shared
        
        // We match: Command (1048576) + Option (524288) = 1572864
        let flags = event.flags
        let isCmdPressed = flags.contains(.maskCommand)
        let isOptPressed = flags.contains(.maskAlternate)
        
        // The virtual key code of Space key is 49
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        if isCmdPressed && isOptPressed && keyCode == 49 {
            if type == .keyDown {
                if !isRecording {
                    isRecording = true
                    DispatchQueue.main.async {
                        self.onShortcutPressed?()
                    }
                }
            } else if type == .keyUp {
                if isRecording {
                    isRecording = false
                    DispatchQueue.main.async {
                        self.onShortcutReleased?()
                    }
                }
            }
        }
    }
    
    /// Backup monitor using standard NSEvent (only works when app is out of focus, does not block shortcuts)
    private func setupBackupGlobalMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            // Fallback toggle using Command + Option + Space
            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    if !self.isRecording {
                        self.isRecording = true
                        self.onShortcutPressed?()
                    } else {
                        self.isRecording = false
                        self.onShortcutReleased?()
                    }
                }
            }
        }
    }
    
    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        activeEventTap = nil
        runLoopSource = nil
    }
}
