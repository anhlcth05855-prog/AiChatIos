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
    private var hasInstalledTap: Bool = false
    
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
        
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("[AudioSpeechManager] TTS audio session error: \(error)")
        }
        #endif
        
        let cleanText = text
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "`", with: "")
        
        let utterance = AVSpeechUtterance(string: cleanText)
        let localeTag = getVoiceLanguageTag(langCode)
        utterance.voice = AVSpeechSynthesisVoice(language: localeTag) ?? AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        synthesizer.speak(utterance)
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
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
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            #if os(iOS)
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        completion(micGranted)
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        completion(micGranted)
                    }
                }
            }
            #else
            DispatchQueue.main.async {
                completion(true)
            }
            #endif
        }
    }
    
    public func startRecording(langCode: String = "vi", onResult: @escaping (String) -> Void) {
        if audioEngine.isRunning || isRecording {
            stopRecording()
            return
        }
        
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AudioSpeechManager] AudioSession setup error: \(error)")
            stopRecording()
            return
        }
        #endif
        
        let localeTag = getVoiceLanguageTag(langCode)
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeTag))
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("[AudioSpeechManager] Speech recognizer unavailable for locale: \(localeTag)")
            stopRecording()
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasInstalledTap = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                    onResult(transcription)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("[AudioSpeechManager] Audio engine start error: \(error)")
            stopRecording()
        }
    }
    
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
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
