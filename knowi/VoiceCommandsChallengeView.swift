//
//  VoiceCommandsChallengeView.swift
//  knowi
//
//  Created on 29/03/25.
//

import SwiftUI
import Speech
import AVFoundation

// MARK: - Speech Recognizer Manager
class SpeechRecognizerManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let request = SFSpeechAudioBufferRecognitionRequest()
    
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    
    func startRecording() {
        recognizedText = ""
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
        
        let inputNode = audioEngine.inputNode
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                DispatchQueue.main.async {
                    self.isRecording = false
                }
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("Audio Engine error: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        request.endAudio()
        isRecording = false
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
}

// MARK: - Voice Commands Challenge View
struct VoiceCommandsChallengeView: View {
    // Each step includes instructions, the expected command (normalized to lowercase and without punctuation), and an explanation.
    struct VoiceChallengeStep {
        let instructions: String
        let expectedCommand: String
        let explanation: String
    }
    
    let steps: [VoiceChallengeStep] = [
        VoiceChallengeStep(
            instructions: """
            Paso 1:
            El comando 'print hola mundo' imprime el mensaje 'hola mundo' en la consola.
            Por favor, di el comando en voz alta.
            """,
            expectedCommand: "print hola mundo",
            explanation: "El comando print se usa para mostrar información en la consola."
        ),
        VoiceChallengeStep(
            instructions: """
            Paso 2:
            El comando 'let numero = 10' declara una constante llamada numero con el valor 10.
            Dilo en voz alta.
            """,
            expectedCommand: "let numero = 10",
            explanation: "Las constantes se declaran con let y su valor no puede cambiar."
        ),
        VoiceChallengeStep(
            instructions: """
            Paso 3:
            El comando 'var mensaje = hola swift' declara una variable llamada mensaje con el valor 'hola swift'.
            Dilo en voz alta (sin comillas).
            """,
            expectedCommand: "var mensaje = hola swift",
            explanation: "Las variables se declaran con var y pueden cambiar durante la ejecución."
        ),
        VoiceChallengeStep(
            instructions: """
            Paso 4:
            Ahora, di 'print mensaje' para imprimir el contenido de la variable mensaje en la consola.
            Dilo en voz alta.
            """,
            expectedCommand: "print mensaje",
            explanation: "Este comando muestra el contenido de la variable mensaje en la consola."
        )
    ]
    
    @State private var currentStepIndex: Int = 0
    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var feedback: String = ""
    @State private var stepCompleted: Bool = false
    @State private var challengeCompleted: Bool = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color("ChallengeStart"), Color("ChallengeEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(Animation.linear(duration: 10).repeatForever(autoreverses: true), value: currentStepIndex)
            
            VStack(spacing: 30) {
                Text("Desafío de Comandos de Voz")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Text(steps[currentStepIndex].instructions)
                        .font(.custom("Poppins-Regular", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if stepCompleted {
                        Text(steps[currentStepIndex].explanation)
                            .font(.custom("Poppins-Italic", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .transition(.opacity)
                    }
                }
                
                // Display live recognized text
                Text(speechManager.recognizedText)
                    .font(.custom("Poppins-Regular", size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                
                Button(action: {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        evaluateCommand()
                    } else {
                        feedback = ""
                        stepCompleted = false
                        speechManager.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: speechManager.isRecording ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 24))
                        Text(speechManager.isRecording ? "Detener Grabación" : "Iniciar Grabación")
                            .font(.custom("Poppins-SemiBold", size: 20))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(speechManager.isRecording ? Color.red : Color.blue)
                    .cornerRadius(25)
                    .shadow(radius: 5)
                }
                
                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.custom("Poppins-SemiBold", size: 20))
                        .foregroundColor((challengeCompleted || stepCompleted) ? .green : .red)
                        .padding()
                        .transition(.opacity)
                }
                
                if stepCompleted {
                    Button(action: {
                        moveToNextStep()
                    }) {
                        Text(currentStepIndex == steps.count - 1 ? "Finalizar Desafío" : "Siguiente")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            speechManager.requestAuthorization { _ in }
        }
    }
    
    private func evaluateCommand() {
        let spoken = speechManager.recognizedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let spokenClean = spoken.components(separatedBy: CharacterSet.punctuationCharacters).joined()
        let expected = steps[currentStepIndex].expectedCommand
        if spokenClean.contains(expected) {
            feedback = "¡Correcto! Has pronunciado el comando."
            stepCompleted = true
            if currentStepIndex == steps.count - 1 {
                challengeCompleted = true
            }
        } else {
            feedback = "Incorrecto. Intenta de nuevo. Asegúrate de decir: \(expected)"
            stepCompleted = false
            challengeCompleted = false
        }
    }
    
    private func moveToNextStep() {
        if currentStepIndex < steps.count - 1 {
            withAnimation(.easeOut(duration: 0.3)) {
                currentStepIndex += 1
                feedback = ""
                speechManager.recognizedText = ""
                stepCompleted = false
            }
        } else {
            challengeCompleted = true
            feedback = "¡Desafío completado!"
        }
    }
}

struct VoiceCommandsChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCommandsChallengeView()
    }
}
