import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorder()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    private override init() {
        super.init()
    }
    
    func startRecording(completion: @escaping (Bool) -> Void) {
        // Request Microphone Permission
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Микрофон ашиглах зөвшөөрөл олгоогүй байна.")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.setupAndRecord(completion: completion)
            }
        }
    }
    
    private func setupAndRecord(completion: @escaping (Bool) -> Void) {
        // Create temporary URL for WAV file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "mongolmic_recording.wav"
        let fileURL = tempDir.appendingPathComponent(fileName)
        self.audioFileURL = fileURL
        
        // Premium WAV Format Configuration: 16kHz, 16-bit, Mono PCM WAV
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            // Start recording immediately
            let success = audioRecorder?.record() ?? false
            completion(success)
        } catch {
            print("Бичлэг эхлүүлэхэд алдаа гарлаа: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        return audioFileURL
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioRecorder = nil
        audioFileURL = nil
    }
    
    // MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Бичлэг амжилтгүй дууслаа.")
        }
    }
}
