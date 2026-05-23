import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    let languages = ["English", "Spanish", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "German"]
    
    var body: some View {
        Form {
            Section(header: Text("🔑 GOOGLE GEMINI API")) {
                VStack(alignment: .leading, spacing: 6) {
                    SecureField("Google Gemini API Key оруулах", text: $settings.apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("API түлхүүр байхгүй бол [aistudio.google.com](https://aistudio.google.com) руу орж үнэгүй авна уу.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("⚙️ АЖИЛЛАХ ГОРИМ")) {
                Toggle("Орчуулах горимыг идэвхжүүлэх", isOn: $settings.isTranslationMode)
                
                if settings.isTranslationMode {
                    Picker("Орчуулах хэл:", selection: $settings.targetLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                }
            }
            
            Section(header: Text("⚡ ШИВЭХ ХУРДНЫ ТОХИРГОО")) {
                Toggle("Шууд хуулах горим (Агшин зуурт)", isOn: $settings.isInstantPaste)
                
                if !settings.isInstantPaste {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Slider(value: Binding(
                                get: { Double(settings.delayMilliseconds) },
                                set: { settings.delayMilliseconds = Int($0) }
                            ), in: 5...50, step: 1)
                            
                            Text("\(settings.delayMilliseconds) ms")
                                .bold()
                                .frame(width: 50, alignment: .trailing)
                        }
                        Text("Тэмдэгт хоорондын хугацаа (Premium уусч шивэх эффект)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("ℹ️ ХОЛБООСУУД")) {
                VStack(alignment: .leading, spacing: 8) {
                    Link("Instagram: @_lxagwa", destination: URL(string: "https://www.instagram.com/_lxagwa/")!)
                        .font(.system(size: 13, weight: .medium))
                    Text("Бүрэн хувилбарын лицензийн нууц үг авах бол дээрх холбоосоор холбогдоно уу.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(30)
        .frame(width: 480, height: 450)
        .navigationTitle("Mongolmic V4 Тохиргоо")
    }
}

#Preview {
    SettingsView()
}
