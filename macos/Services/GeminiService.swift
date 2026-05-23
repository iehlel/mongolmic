import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private init() {}
    
    struct GenerationConfig: Codable {
        let temperature: Double
        let maxOutputTokens: Int
        let thinkingConfig: ThinkingConfig
        
        enum CodingKeys: String, CodingKey {
            case temperature
            case maxOutputTokens = "maxOutputTokens"
            case thinkingConfig
        }
    }
    
    struct ThinkingConfig: Codable {
        let thinkingBudget: Int
    }
    
    struct SystemInstruction: Codable {
        let parts: [TextPart]
    }
    
    struct TextPart: Codable {
        let text: String
    }
    
    struct InlineData: Codable {
        let mimeType: String
        let data: String
    }
    
    struct InlineDataPart: Codable {
        let inlineData: InlineData
    }
    
    struct Content: Codable {
        let parts: [InlineDataPart]
    }
    
    struct Payload: Codable {
        let systemInstruction: SystemInstruction
        let contents: [Content]
        let generationConfig: GenerationConfig
    }
    
    struct ResponseCandidate: Codable {
        struct ResponseContent: Codable {
            struct ResponsePart: Codable {
                let text: String?
            }
            let parts: [ResponsePart]
        }
        let content: ResponseContent?
        let finishReason: String?
    }
    
    struct GeminiResponse: Codable {
        let candidates: [ResponseCandidate]?
    }
    
    func processSpeech(
        wavURL: URL,
        apiKey: String,
        isTranslationMode: Bool,
        targetLanguage: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Read audio file
        guard let audioData = try? Data(contentsOf: wavURL) else {
            completion(.failure(NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WAV файлыг уншиж чадсангүй"])))
            return
        }
        
        let base64Audio = audioData.base64EncodedString()
        
        // Prepare system instructions
        let systemInstructionText: String
        if isTranslationMode {
            systemInstructionText = """
            You are a highly accurate Mongolian-to-\(targetLanguage) Speech Translator.
            
            Task:
            1. Translate the spoken Mongolian speech in the provided audio file into natural, clean \(targetLanguage) text.
            2. Output ONLY the translated \(targetLanguage) text itself.
            3. If the audio contains only ambient silence, breathing, keyboard clicks, fan noise, or background static without human speech, return an empty string (nothing).
            """
        } else {
            systemInstructionText = """
            You are a highly accurate Mongolian Speech-to-Text Transcriber.
            
            Task:
            1. Transcribe the Mongolian speech in the provided audio file into natural, clean Mongolian text.
            2. Output ONLY the transcribed Mongolian text itself.
            3. If the audio contains only ambient silence, breathing, keyboard clicks, fan noise, or background static without human speech, return an empty string (nothing).
            """
        }
        
        // Create request payload matching the premium Windows implementation with thinkingBudget = 0
        let payload = Payload(
            systemInstruction: SystemInstruction(parts: [TextPart(text: systemInstructionText)]),
            contents: [
                Content(parts: [
                    InlineDataPart(inlineData: InlineData(mimeType: "audio/wav", data: base64Audio))
                ])
            ],
            generationConfig: GenerationConfig(
                temperature: 0.0,
                maxOutputTokens: 800,
                thinkingConfig: ThinkingConfig(thinkingBudget: 0) // Disable thinking mode for lightning-fast speeds
            )
        )
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)") else {
            completion(.failure(NSError(domain: "GeminiService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API URL үүсгэж чадсангүй"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GeminiService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Хариу хоосон ирлээ"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let responseObj = try decoder.decode(GeminiResponse.self, from: data)
                
                if let firstCandidate = responseObj.candidates?.first {
                    if let text = firstCandidate.content?.parts.first?.text {
                        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !processedText.isEmpty {
                            let endChars: Set<Character> = [".", "?", "!"]
                            if let lastChar = processedText.last, !endChars.contains(lastChar) {
                                processedText += "."
                            }
                            processedText += " "
                            completion(.success(processedText))
                        } else {
                            completion(.success("")) // Silence
                        }
                    } else if let reason = firstCandidate.finishReason, reason == "SAFETY" {
                        completion(.failure(NSError(domain: "GeminiService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Аюулгүй байдлын шүүлтүүрт хаагдлаа (Safety Blocked)"])))
                    } else {
                        completion(.success(""))
                    }
                } else {
                    completion(.failure(NSError(domain: "GeminiService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Gemini хариулт хоосон байна"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
