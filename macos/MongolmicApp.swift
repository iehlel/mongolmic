import SwiftUI
import Cocoa

@main
struct MongolmicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We use SettingsScene to prevent standard empty window from spawning on startup
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    var overlayWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Create a beautiful premium Menu Bar Status Item (Tray Icon equivalent)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Mongolmic V4")
            button.image?.isTemplate = true // Light/Dark mode reactive
        }
        
        setupMenu()
        
        // 2. Setup keyboard shortcut actions
        KeyboardShortcutManager.shared.onShortcutPressed = { [weak self] in
            self?.startRecordingFlow()
        }
        
        KeyboardShortcutManager.shared.onShortcutReleased = { [weak self] in
            self?.stopRecordingFlow()
        }
        
        // 3. Start monitoring shortcut keys globally
        KeyboardShortcutManager.shared.startMonitoring()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "🎤 Mongolmic V4", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "⚙️ Тохиргоо...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "🔑 Үнэгүй API Key авах...", action: #selector(openAIStudio), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "❌ Гарах", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func showSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 450),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Mongolmic V4 Тохиргоо"
            window.contentView = NSHostingView(rootView: contentView)
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openAIStudio() {
        if let url = URL(string: "https://aistudio.google.com/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quitApp() {
        KeyboardShortcutManager.shared.stopMonitoring()
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Recording Flow
    
    private func startRecordingFlow() {
        // Pre-validate API Key
        let settings = Settings.shared
        guard !settings.apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            showNotification(title: "API Key дутуу байна", subtitle: "Тохиргоо хэсэгт API Key-ээ оруулна уу.")
            return
        }
        
        // Start audio recording
        AudioRecorder.shared.startRecording { [weak self] success in
            guard success else { return }
            
            DispatchQueue.main.async {
                self?.showOverlayWindow()
            }
        }
    }
    
    private func stopRecordingFlow() {
        // Stop audio and get file URL
        guard let wavURL = AudioRecorder.shared.stopRecording() else {
            hideOverlayWindow()
            return
        }
        
        let settings = Settings.shared
        
        // Call Gemini API (with thinkingBudget = 0 for lightning speed)
        GeminiService.shared.processSpeech(
            wavURL: wavURL,
            apiKey: settings.apiKey,
            isTranslationMode: settings.isTranslationMode,
            targetLanguage: settings.targetLanguage
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideOverlayWindow()
                
                switch result {
                case .success(let text):
                    guard !text.isEmpty else { return }
                    
                    // Paste/Type text using preferred setting
                    if settings.isInstantPaste {
                        InputSimulator.shared.pasteText(text)
                    } else {
                        InputSimulator.shared.typeText(text, delayMilliseconds: settings.delayMilliseconds)
                    }
                    
                case .failure(let error):
                    self?.showNotification(title: "Алдаа гарлаа", subtitle: error.localizedDescription)
                }
                
                // Cleanup temp file
                try? FileManager.default.removeItem(at: wavURL)
            }
        }
    }
    
    // MARK: - Custom Floating Overlay Window
    
    private func showOverlayWindow() {
        if overlayWindow == nil {
            let view = RecordingOverlayView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 250, height: 210),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .status // Stay above other windows
            window.ignoresMouseEvents = true
            window.contentView = NSHostingView(rootView: view)
            
            overlayWindow = window
        }
        
        // Premium Positioning: Centered at the bottom of the screen (similar to WPF overlay)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 250
            let windowHeight: CGFloat = 210
            let x = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            let y = screenFrame.origin.y + 40 // 40px above the bottom dock
            
            overlayWindow?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
        
        overlayWindow?.orderFrontRegardless()
    }
    
    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
    }
    
    private func showNotification(title: String, subtitle: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
