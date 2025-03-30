//
//  DictationLessonView.swift
//  knowi
//
//  Created on 29/03/25.
//

import SwiftUI
import AVFoundation

// Model for dictation content
struct DictationContent: Identifiable {
    let id = UUID()
    let text: String
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
}

// Quiz State
enum QuizState {
    case listening
    case answering
    case feedback
    case completed
}

struct DictationLessonView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userDataManager = UserDataManager.shared
    
    // State variables
    @State private var currentIndex = 0
    @State private var progress: CGFloat = 0.0
    @State private var score = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var quizState: QuizState = .listening
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking = false
    @State private var showExplanation = false
    
    // Store delegate as a property to prevent deallocation
    @State private var speechDelegate: SpeechDelegate?
    
    // Lesson content in Spanish
    let dictationContents = [
        DictationContent(
            text: "La programación es el proceso de crear un conjunto de instrucciones que le dicen a una computadora cómo realizar una tarea.",
            question: "¿Qué es la programación?",
            options: [
                "Un lenguaje de computadora",
                "El proceso de crear instrucciones para una computadora",
                "Una aplicación móvil",
                "Un tipo de hardware"
            ],
            correctAnswerIndex: 1
        ),
        DictationContent(
            text: "Swift es un lenguaje de programación potente e intuitivo para iOS, iPadOS, macOS, tvOS y watchOS.",
            question: "¿Para qué sistemas operativos está diseñado Swift?",
            options: [
                "Solo para iOS",
                "Para Windows y Mac",
                "Para iOS, iPadOS, macOS, tvOS y watchOS",
                "Solo para aplicaciones web"
            ],
            correctAnswerIndex: 2
        ),
        DictationContent(
            text: "AVSpeechSynthesizer es una clase en el marco de AVFoundation que permite a tu aplicación pronunciar texto a través de los dispositivos de audio del sistema.",
            question: "¿Qué permite hacer AVSpeechSynthesizer?",
            options: [
                "Grabar audio",
                "Reproducir música",
                "Pronunciar texto a través de los dispositivos de audio",
                "Analizar frecuencias de audio"
            ],
            correctAnswerIndex: 2
        ),
        DictationContent(
            text: "La accesibilidad en las aplicaciones móviles es esencial para asegurar que todas las personas, incluidas aquellas con discapacidades, puedan utilizar tu aplicación de manera efectiva.",
            question: "¿Por qué es importante la accesibilidad en las aplicaciones móviles?",
            options: [
                "Para que la aplicación sea más rápida",
                "Para que todas las personas puedan usar la aplicación efectivamente",
                "Para cumplir con reglas de diseño",
                "Para usar menos memoria"
            ],
            correctAnswerIndex: 1
        ),
        DictationContent(
            text: "El dictado por voz permite a los usuarios que prefieren o necesitan interactuar con la tecnología mediante comandos de voz, hacer uso efectivo de las aplicaciones.",
            question: "¿Qué beneficio ofrece el dictado por voz?",
            options: [
                "Hace que las aplicaciones sean más lentas",
                "Solo funciona en idioma inglés",
                "Permite interactuar con la tecnología mediante comandos de voz",
                "Reemplaza completamente las interfaces táctiles"
            ],
            correctAnswerIndex: 2
        )
    ]
    
    // Computed properties
    var currentContent: DictationContent {
        dictationContents[currentIndex]
    }
    
    var isLastItem: Bool {
        currentIndex == dictationContents.count - 1
    }
    
    var currentProgress: CGFloat {
        CGFloat(currentIndex) / CGFloat(dictationContents.count)
    }
    
    // Body of the view
    var body: some View {
        ZStack {
            // Background
            Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all)
            
            VStack(spacing:
                  20) {
                // Navigation bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    Text("\(currentIndex + 1)/\(dictationContents.count)")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.blue)
                        .padding()
                }
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(.blue)
                        .frame(width: max(CGFloat(currentProgress) * UIScreen.main.bounds.width, 0), height: 8)
                        .cornerRadius(4)
                        .animation(.linear, value: currentProgress)
                }
                .padding(.horizontal)
                
                // Main content container
                ScrollView {
                    VStack(spacing: 25) {
                        // Title
                        Text("Dictado y Comprensión Auditiva")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.black)
                            .padding(.top)
                        
                        // Different view depending on state
                        switch quizState {
                        case .listening:
                            listeningView
                        case .answering:
                            questionView
                        case .feedback:
                            feedbackView
                        case .completed:
                            completionView
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                
                // Bottom button area
                actionButtonArea
            }
        }
        .onAppear {
            prepareToSpeak()
        }
        .onDisappear {
            stopSpeaking()
        }
    }
    
    // Listening view - shows when the speech synthesizer is speaking
    var listeningView: some View {
        VStack(spacing: 25) {
            // Audio visualization graphic
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isSpeaking ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isSpeaking)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isSpeaking ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isSpeaking)
                
                Image(systemName: "ear.and.waveform")
                    .font(.system(size: 45))
                    .foregroundColor(.blue)
            }
            
            Text("Escucha atentamente...")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            Text("Toca el botón para escuchar el texto")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !isSpeaking {
                Button(action: {
                    startSpeaking()
                }) {
                    Text("Reproducir audio")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 10)
            } else {
                Button(action: {
                    stopSpeaking()
                }) {
                    Text("Detener audio")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .cornerRadius(25)
                        .shadow(color: Color.red.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 10)
            }
            
            if showExplanation {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Texto:")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.black)
                    
                    Text(currentContent.text)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(5)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                }
                .padding(.top, 20)
                .transition(.opacity)
            }
            
            Spacer(minLength: 40)
        }
    }
    
    // Question view - shows the question and answer options
    var questionView: some View {
        VStack(spacing: 25) {
            Text(currentContent.question)
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Answer options
            VStack(spacing: 15) {
                ForEach(0..<currentContent.options.count, id: \.self) { index in
                    Button(action: {
                        self.selectedAnswerIndex = index
                    }) {
                        HStack {
                            Text("\(["A", "B", "C", "D"][index]). ")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(selectedAnswerIndex == index ? .white : .blue)
                            
                            Text(currentContent.options[index])
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(selectedAnswerIndex == index ? .white : .black)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            if selectedAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedAnswerIndex == index ? Color.blue : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical)
            
            Button(action: {
                // Listen again
                prepareToSpeak()
                startSpeaking()
            }) {
                HStack {
                    Image(systemName: "ear")
                        .font(.system(size: 16))
                    
                    Text("Escuchar de nuevo")
                        .font(.custom("Poppins-Regular", size: 16))
                }
                .foregroundColor(.blue)
                .padding()
            }
            
            Spacer(minLength: 40)
        }
    }
    
    // Feedback view - shows feedback after answering
    var feedbackView: some View {
        VStack(spacing: 20) {
            // Feedback icon
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(isCorrect ? .green : .red)
            
            // Feedback message
            Text(isCorrect ? "¡Correcto!" : "Incorrecto")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(isCorrect ? .green : .red)
            
            // Explanation
            VStack(alignment: .leading, spacing: 15) {
                Text("Texto original:")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Text(currentContent.text)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
                    .lineSpacing(5)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                
                Text("Respuesta correcta:")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text(currentContent.options[currentContent.correctAnswerIndex])
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
            }
            .padding()
            
            // XP reward
            if isCorrect {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("+30 XP")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    // Completion view - shown when the lesson is completed
    var completionView: some View {
        VStack(spacing: 25) {
            // Success image
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding()
            
            Text("¡Lección completada!")
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.black)
            
            Text("Has completado la lección de Dictado y Comprensión Auditiva")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Score display
            VStack {
                Text("Tu puntuación:")
                    .font(.custom("Poppins-SemiBold", size: 20))
                    .foregroundColor(.black)
                
                Text("\(score) de \(dictationContents.count)")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.blue)
                
                // Display stars based on score
                HStack(spacing: 15) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 30))
                            .foregroundColor(
                                Double(score) / Double(dictationContents.count) > Double(index) / 3.0 + 0.1 ?
                                    .yellow : .gray.opacity(0.3)
                            )
                    }
                }
                .padding()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
            
            // XP earned
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("+\(score * 30) XP ganados")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(20)
            
            Spacer(minLength: 30)
        }
    }
    
    // Dynamic action button area at the bottom of the screen
    var actionButtonArea: some View {
        VStack {
            switch quizState {
            case .listening:
                Button(action: {
                    // Move to answer state
                    stopSpeaking()
                    withAnimation {
                        quizState = .answering
                    }
                }) {
                    Text("Contestar pregunta")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                
                Button(action: {
                    withAnimation {
                        showExplanation.toggle()
                    }
                }) {
                    Text(showExplanation ? "Ocultar texto" : "Mostrar texto")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                }
                
            case .answering:
                Button(action: {
                    // Check answer and show feedback
                    isCorrect = selectedAnswerIndex == currentContent.correctAnswerIndex
                    if isCorrect {
                        score += 1
                    }
                    
                    withAnimation {
                        quizState = .feedback
                    }
                }) {
                    Text("Comprobar respuesta")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(selectedAnswerIndex != nil ? Color.blue : Color.gray)
                        .cornerRadius(25)
                        .shadow(color: selectedAnswerIndex != nil ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .disabled(selectedAnswerIndex == nil)
                .padding(.horizontal)
                
            case .feedback:
                Button(action: {
                    // Move to next question or complete
                    if isLastItem {
                        completeLesson()
                    } else {
                        moveToNextQuestion()
                    }
                }) {
                    Text(isLastItem ? "Finalizar lección" : "Siguiente pregunta")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                
            case .completed:
                Button(action: {
                    // Return to home view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Volver al inicio")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 30)
    }
    
    // Functions for the speech synthesizer
    func prepareToSpeak() {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: currentContent.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Create and store the delegate
        self.speechDelegate = SpeechDelegate(
            didStart: {
                DispatchQueue.main.async {
                    self.isSpeaking = true
                }
            },
            didFinish: {
                DispatchQueue.main.async {
                    self.isSpeaking = false
                }
            }
        )
        
        // Assign the delegate
        speechSynthesizer.delegate = speechDelegate
    }
    
    func startSpeaking() {
        let utterance = AVSpeechUtterance(string: currentContent.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // Navigation and progression functions
    func moveToNextQuestion() {
        // Reset states
        selectedAnswerIndex = nil
        showExplanation = false
        
        // Advance to next question
        currentIndex += 1
        
        // Update state
        withAnimation {
            quizState = .listening
        }
        
        // Prepare for speaking
        prepareToSpeak()
    }
    
    func completeLesson() {
        // Update user data with XP and progress
        let xpEarned = score * 30
        userDataManager.userProfile.xpPoints += xpEarned
        userDataManager.userProfile.dailyProgress += xpEarned
        
        // Mark the quest as completed
        userDataManager.markQuestAsCompleted("Dictado y Comprensión Auditiva")
        
        // Save user data changes
        userDataManager.saveUserData()
        
        // Show completion view
        withAnimation {
            quizState = .completed
        }
    }
}

// Speech synthesis delegate to track speaking state
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var didStart: () -> Void
    var didFinish: () -> Void
    
    init(didStart: @escaping () -> Void, didFinish: @escaping () -> Void) {
        self.didStart = didStart
        self.didFinish = didFinish
        super.init()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        didStart()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinish()
    }
}

// Preview
struct DictationLessonView_Previews: PreviewProvider {
    static var previews: some View {
        DictationLessonView()
    }
}
