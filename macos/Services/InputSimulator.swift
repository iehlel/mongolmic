import Foundation
import Cocoa
import CoreGraphics

class InputSimulator {
    static let shared = InputSimulator()
    
    private init() {}
    
    /// Simulates character-by-character human-like typing with a custom delay.
    /// This requires Accessibility permissions on macOS.
    func typeText(_ text: String, delayMilliseconds: Int = 12, completion: (() -> Void)? = nil) {
        guard !text.isEmpty else {
            completion?()
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let source = CGEventSource(stateID: .hidSystemState)
            
            for char in text {
                let utf16Chars = Array(String(char).utf16)
                
                // 1. Key Down Event
                if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                    keyDownEvent.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                    keyDownEvent.post(tap: .cghidEventTap)
                }
                
                // 2. Key Up Event
                if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                    keyUpEvent.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                    keyUpEvent.post(tap: .cghidEventTap)
                }
                
                // Premium visual delay
                Thread.sleep(forTimeInterval: Double(delayMilliseconds) / 1000.0)
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// Instant pasting using macOS NSPasteboard (Clipboard) and simulating Cmd+V shortcut.
    func pasteText(_ text: String, completion: (() -> Void)? = nil) {
        guard !text.isEmpty else {
            completion?()
            return
        }
        
        DispatchQueue.main.async {
            // Save original clipboard content to restore later (premium detail!)
            let pasteboard = NSPasteboard.general
            let originalItems = pasteboard.pasteboardItems
            
            // Set new text to clipboard
            pasteboard.clearContents()
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(text, forType: .string)
            
            // Simulate Command + V press
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Virtual Keycode for 'V' is 9
            let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
            cmdKeyDown?.flags = .maskCommand
            
            let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
            cmdKeyUp?.flags = .maskCommand
            
            cmdKeyDown?.post(tap: .cghidEventTap)
            cmdKeyUp?.post(tap: .cghidEventTap)
            
            // Restore original clipboard after a small delay
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
                pasteboard.clearContents()
                if let items = originalItems {
                    for item in items {
                        let newItem = NSPasteboardItem()
                        for type in item.types {
                            if let data = item.data(forType: type) {
                                newItem.setData(data, forType: type)
                            }
                        }
                        pasteboard.writeObjects([newItem])
                    }
                }
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}
