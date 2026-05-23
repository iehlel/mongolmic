import Foundation

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
        }
    }
    
    @Published var isTranslationMode: Bool {
        didSet {
            UserDefaults.standard.set(isTranslationMode, forKey: "isTranslationMode")
        }
    }
    
    @Published var targetLanguage: String {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage")
        }
    }
    
    @Published var delayMilliseconds: Int {
        didSet {
            UserDefaults.standard.set(delayMilliseconds, forKey: "delayMilliseconds")
        }
    }
    
    @Published var isInstantPaste: Bool {
        didSet {
            UserDefaults.standard.set(isInstantPaste, forKey: "isInstantPaste")
        }
    }
    
    @Published var shortcutKeyCode: Int {
        didSet {
            UserDefaults.standard.set(shortcutKeyCode, forKey: "shortcutKeyCode")
        }
    }
    
    @Published var shortcutModifiers: Int {
        didSet {
            UserDefaults.standard.set(shortcutModifiers, forKey: "shortcutModifiers")
        }
    }
    
    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        self.isTranslationMode = UserDefaults.standard.bool(forKey: "isTranslationMode")
        self.targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? "English"
        
        // Premium default 12ms delay
        let savedDelay = UserDefaults.standard.integer(forKey: "delayMilliseconds")
        self.delayMilliseconds = savedDelay > 0 ? savedDelay : 12
        
        self.isInstantPaste = UserDefaults.standard.bool(forKey: "isInstantPaste")
        
        // Defaults: Space keycode = 49, Modifiers: Cmd + Alt (Control=4096, Option=524288, Command=1048576)
        let savedKey = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        self.shortcutKeyCode = savedKey > 0 ? savedKey : 49
        
        let savedMods = UserDefaults.standard.integer(forKey: "shortcutModifiers")
        self.shortcutModifiers = savedMods > 0 ? savedMods : 1572864 // Command + Option
    }
}
