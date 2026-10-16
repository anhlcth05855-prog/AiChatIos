import Foundation
import AVFoundation
import Speech

public final class AudioSpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    public static let shared = AudioSpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published public var isSpeaking: Bool = false
    @Published public var isRecording: Bool = false
    @Published public var transcribedText: String = ""
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Text-to-Speech (TTS)
    
    public func speak(text: String, langCode: String = "vi") {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let cleanText = text
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "`", with: "")
        
        let utterance = AVSpeechUtterance(string: cleanText)
        let localeTag = getVoiceLanguageTag(langCode)
        utterance.voice = AVSpeechSynthesisVoice(language: localeTag) ?? AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // MARK: - Speech Recognition (STT)
    
    public func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    public func startRecording(langCode: String = "vi", onResult: @escaping (String) -> Void) {
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
        let localeTag = getVoiceLanguageTag(langCode)
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeTag))
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                    onResult(transcription)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("[AudioSpeechManager] Audio engine start error: \(error)")
            stopRecording()
        }
    }
    
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    private func getVoiceLanguageTag(_ langCode: String) -> String {
        switch langCode {
        case "en": return "en-US"
        case "zh": return "zh-CN"
        case "ja": return "ja-JP"
        case "ko": return "ko-KR"
        case "fr": return "fr-FR"
        default: return "vi-VN"
        }
    }
}
