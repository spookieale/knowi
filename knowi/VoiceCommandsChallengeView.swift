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
    @Published var audioLevel: Float = 0.0
    
    private var audioLevelTimer: Timer?
    private var audioLevelNode: AVAudioNode?
    private var audioMeteringEnabled = false
    
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
            
            // Calculate audio level directly from the buffer here
            let channelDataValue = buffer.floatChannelData?.pointee
            if let channelData = channelDataValue {
                let channelDataArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelData[$0] }
                let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
                DispatchQueue.main.async {
                    self.audioLevel = rms * 10
                }
            }
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
        audioLevel = 0.0
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
}

// MARK: - Voice Commands Challenge View Models and Supporting Views
struct VoiceChallengeStep: Identifiable {
    let id = UUID()
    let instructions: String
    let expectedCommand: String
    let explanation: String
    let tip: String
    let codePreview: String
    let output: String?
    let difficulty: StepDifficulty
    
    enum StepDifficulty: String {
        case beginner = "Principiante"
        case intermediate = "Intermedio"
        case advanced = "Avanzado"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .purple
            }
        }
    }
}

struct AnimatedWaveform: View {
    let level: Float
    let isRecording: Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<15) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(self.barColor(for: index))
                        .frame(width: (geometry.size.width / 20), height: self.barHeight(for: index, size: geometry.size.height))
                        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: level)
                }
            }
            .frame(height: geometry.size.height)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func barHeight(for index: Int, size: CGFloat) -> CGFloat {
        guard isRecording else { return size * 0.2 }
        
        let randomFactor = CGFloat(level * (Float(index % 3 + 1) * 0.3))
        let height = min(size * (0.3 + CGFloat(randomFactor)), size * 0.95)
        return max(height, size * 0.1)
    }
    
    private func barColor(for index: Int) -> Color {
        guard isRecording else { return .gray.opacity(0.5) }
        
        let baseColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        let colorIndex = index % baseColors.count
        let opacity = min(CGFloat(level) * 0.8 + 0.2, 1.0)
        return baseColors[colorIndex].opacity(opacity)
    }
}

struct ScoreProgressView: View {
    let correctCount: Int
    let totalCount: Int
    
    var body: some View {
        HStack {
            Text("Progreso")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 12)
                    .foregroundColor(.white.opacity(0.3))
                
                Capsule()
                    .frame(width: totalCount > 0 ? CGFloat(correctCount) / CGFloat(totalCount) * 150 : 0, height: 12)
                    .foregroundColor(.green)
            }
            .frame(width: 150)
            
            Text("\(correctCount)/\(totalCount)")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
    }
}

struct CommandCard: View {
    let step: VoiceChallengeStep
    let isActive: Bool
    let isCompleted: Bool
    
    @Binding var showingHint: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(step.difficulty.rawValue)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(step.difficulty.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(step.difficulty.color.opacity(0.2))
                    .cornerRadius(15)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                } else if isActive {
                    Text("Activo")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(15)
                }
            }
            
            Text(step.instructions)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
            
            if isActive {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Código de ejemplo:")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(step.codePreview)
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    
                    if let output = step.output {
                        Text("Resultado:")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 5)
                        
                        Text(output)
                            .font(.custom("Courier", size: 16))
                            .foregroundColor(.green)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    
                    Button {
                        withAnimation {
                            showingHint.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showingHint ? "lightbulb.fill" : "lightbulb")
                                .foregroundColor(.yellow)
                            Text(showingHint ? "Ocultar pista" : "Mostrar pista")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(15)
                    }
                    
                    if showingHint {
                        Text("Pista: \(step.tip)")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.yellow.opacity(0.9))
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        isActive ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5),
                        isActive ? Color.purple.opacity(0.7) : Color.gray.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: isActive ? Color.blue.opacity(0.5) : Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isActive ? 1.0 : 0.95)
        .opacity(isActive ? 1.0 : 0.8)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isActive)
    }
}

struct SuccessConfetti: View {
    let count: Int
    @State private var confetti: [Confetti] = []
    
    struct Confetti: Identifiable {
        let id = UUID()
        let color: Color
        var position: CGPoint
        var rotation: Double
        let size: CGFloat
        let duration: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(confetti) { item in
                Rectangle()
                    .fill(item.color)
                    .frame(width: item.size, height: item.size)
                    .rotationEffect(.degrees(item.rotation))
                    .position(item.position)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        confetti = []
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        
        for _ in 0..<count {
            let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let randomY = CGFloat.random(in: -100...0)
            let randomColor = colors.randomElement() ?? .blue
            let randomRotation = Double.random(in: 0...360)
            let randomSize = CGFloat.random(in: 5...15)
            let randomDuration = Double.random(in: 2...5)
            
            let newConfetti = Confetti(
                color: randomColor,
                position: CGPoint(x: randomX, y: randomY),
                rotation: randomRotation,
                size: randomSize,
                duration: randomDuration
            )
            
            confetti.append(newConfetti)
            
            // Animate the confetti falling
            withAnimation(.easeIn(duration: newConfetti.duration)) {
                if let index = confetti.firstIndex(where: { $0.id == newConfetti.id }) {
                    confetti[index].position.y = UIScreen.main.bounds.height + 100
                    confetti[index].rotation += 360
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let title: String
    let description: String
    let iconName: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.orange.opacity(0.5), radius: 10, x: 0, y: 5)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.7))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Enhanced Voice Commands Challenge View
struct VoiceCommandsChallengeView: View {
    // Enhanced challenge steps with more context and visual elements
    let steps: [VoiceChallengeStep] = [
        VoiceChallengeStep(
            instructions: "Vamos a imprimir un mensaje en la consola. El comando 'print hola mundo' muestra el texto en la salida del programa.",
            expectedCommand: "print hola mundo",
            explanation: "El comando 'print' es una función esencial en Swift que muestra mensajes o valores en la consola. Es útil para depurar y verificar los valores durante la ejecución del programa.",
            tip: "Pronuncia claramente 'print' seguido de 'hola mundo'",
            codePreview: "print(\"hola mundo\")",
            output: "hola mundo",
            difficulty: .beginner
        ),
        VoiceChallengeStep(
            instructions: "Ahora vamos a declarar una constante. Usa 'var numero = 10' para crear una constante con un valor fijo.",
            expectedCommand: "led numero = 10",
            explanation: "En Swift, 'let' se usa para declarar constantes cuyos valores no pueden cambiar una vez asignados. Esto ayuda a prevenir errores en tu código.",
            tip: "Asegúrate de decir primero 'let', luego 'numero', luego 'igual', y finalmente '10'",
            codePreview: "let numero = 10\nprint(numero)",
            output: "10",
            difficulty: .beginner
        ),
        VoiceChallengeStep(
            instructions: "Usemos 'var mensaje = hola swift' para declarar una variable cuyo valor puede cambiar más tarde. Dilo sin comillas.",
            expectedCommand: "var mensaje = hola swift",
            explanation: "A diferencia de las constantes, las variables (declaradas con 'var') pueden cambiar su valor durante la ejecución del programa. Son útiles cuando necesitas modificar datos.",
            tip: "Empieza con 'var', seguido de 'mensaje', 'igual', y 'hola swift'",
            codePreview: "var mensaje = \"hola swift\"\nprint(mensaje)",
            output: "hola swift",
            difficulty: .beginner
        ),
        VoiceChallengeStep(
            instructions: "Para ver el valor de nuestra variable, di 'print mensaje' para mostrar su contenido en la consola.",
            expectedCommand: "print mensaje",
            explanation: "Podemos usar print no solo con texto literal, sino también con variables y constantes para ver sus valores actuales.",
            tip: "Simplemente di 'print' seguido de 'mensaje'",
            codePreview: "print(mensaje)",
            output: "hola swift",
            difficulty: .beginner
        ),
        VoiceChallengeStep(
            instructions: "Vamos a actualizar nuestra variable. Di 'mensaje = adios swift' para cambiar su valor.",
            expectedCommand: "mensaje = adios swift",
            explanation: "Las variables nos permiten asignar nuevos valores en cualquier momento. Observa que no necesitamos volver a usar 'var' después de la declaración inicial.",
            tip: "Di 'mensaje igual adios swift'",
            codePreview: "mensaje = \"adios swift\"\nprint(mensaje)",
            output: "adios swift",
            difficulty: .intermediate
        ),
        VoiceChallengeStep(
            instructions: "Creemos una condicional. Di 'if numero mayor que 5 print es mayor' para ejecutar código basado en una condición.",
            expectedCommand: "if numero mayor que 5 print es mayor",
            explanation: "Las estructuras condicionales como 'if' nos permiten ejecutar código solo cuando se cumple cierta condición, lo que hace nuestros programas más dinámicos.",
            tip: "Pronuncia claramente 'if numero mayor que 5' y luego 'print es mayor'",
            codePreview: "if numero > 5 {\n    print(\"es mayor\")\n}",
            output: "es mayor",
            difficulty: .intermediate
        ),
        VoiceChallengeStep(
            instructions: "Definamos un bucle. Di 'for i in 1 a 3 print i' para repetir código varias veces.",
            expectedCommand: "for i in 1 a 3 print i",
            explanation: "Los bucles nos permiten repetir código de manera eficiente. El bucle 'for-in' es muy útil para iterar sobre rangos de números o colecciones de elementos.",
            tip: "Di 'for i in uno a tres print i'",
            codePreview: "for i in 1...3 {\n    print(i)\n}",
            output: "1\n2\n3",
            difficulty: .advanced
        ),
        VoiceChallengeStep(
            instructions: "Finalmente, creemos una función. Di 'func saludar print hola desde la función' para definir código reutilizable.",
            expectedCommand: "func saludar print hola desde la funcion",
            explanation: "Las funciones nos permiten organizar código en bloques reutilizables que realizan tareas específicas, mejorando la organización y evitando repeticiones.",
            tip: "Pronuncia 'func' seguido de 'saludar' y luego 'print hola desde la función'",
            codePreview: "func saludar() {\n    print(\"hola desde la función\")\n}\nsaludar()",
            output: "hola desde la función",
            difficulty: .advanced
        )
    ]
    
    @State private var currentStepIndex: Int = 0
    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var feedback: String = ""
    @State private var stepCompleted: Bool = false
    @State private var challengeCompleted: Bool = false
    @State private var completedSteps: Set<Int> = []
    @State private var streakCount: Int = 0
    @State private var showingHint: Bool = false
    @State private var showCard: Bool = true
    @State private var rotationDegrees: Double = 0
    @State private var showingAchievement: Bool = false
    @State private var xpEarned: Int = 0
    @State private var confettiCount: Int = 0
    @State private var pulseAnimation: Bool = false
    
    // Background animation properties
    @State private var gradientColors: [Color] = [Color.blue, Color.purple]
    @State private var gradientScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dynamic animated background
            RadialGradient(
                gradient: Gradient(colors: gradientColors),
                center: .center,
                startRadius: 100 * gradientScale,
                endRadius: 650 * gradientScale
            )
            .animation(
                Animation.easeInOut(duration: 8).repeatForever(autoreverses: true),
                value: gradientScale
            )
            .ignoresSafeArea()
            .onAppear {
                startBackgroundAnimations()
            }
            
            // Main scrolling content
            ScrollView {
                VStack(spacing: 25) {
                    // Header with progress
                    VStack(spacing: 10) {
                        Text("Desafío de Comandos de Voz")
                            .font(.custom("Poppins-Bold", size: 30))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            .padding(.top, 20)
                        
                        ScoreProgressView(correctCount: completedSteps.count, totalCount: steps.count)
                        
                        if streakCount > 1 {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("Racha: \(streakCount)")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.orange)
                                
                                if pulseAnimation {
                                    Text("+\(min(streakCount, 5))")
                                        .font(.custom("Poppins-Bold", size: 14))
                                        .foregroundColor(.yellow)
                                        .transition(.scale)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(15)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseAnimation)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Challenge Card
                    if showCard {
                        CommandCard(
                            step: steps[currentStepIndex],
                            isActive: true,
                            isCompleted: completedSteps.contains(currentStepIndex),
                            showingHint: $showingHint
                        )
                        .rotation3DEffect(.degrees(rotationDegrees), axis: (x: 0, y: 1, z: 0))
                        .padding(.horizontal)
                    }
                    
                    // Voice recognition UI
                    VStack(spacing: 20) {
                        // Waveform visualization
                        AnimatedWaveform(level: speechManager.audioLevel, isRecording: speechManager.isRecording)
                            .frame(height: 60)
                            .padding(.horizontal)
                        
                        // Recognized text display
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Tu voz:")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(speechManager.recognizedText.isEmpty ? "Esperando tu comando..." : speechManager.recognizedText)
                                .font(.custom("Poppins-Regular", size: 22))
                                .foregroundColor(.white)
                                .frame(minHeight: 60)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(speechManager.isRecording ? Color.red : Color.clear, lineWidth: 2)
                                        .opacity(speechManager.isRecording ? 1 : 0.5)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Record button with dynamic styling
                        Button(action: {
                            if speechManager.isRecording {
                                speechManager.stopRecording()
                                evaluateCommand()
                            } else {
                                feedback = ""
                                speechManager.startRecording()
                            }
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text(speechManager.isRecording ? "Detener Grabación" : "Iniciar Grabación")
                                    .font(.custom("Poppins-SemiBold", size: 18))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 15)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                speechManager.isRecording ? Color.red : Color.blue,
                                                speechManager.isRecording ? Color.red.opacity(0.7) : Color.blue.opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: speechManager.isRecording ? Color.red.opacity(0.5) : Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechManager.isRecording)
                        }
                    }
                    .padding(.vertical, 15)
                    
                    // Feedback section
                    if !feedback.isEmpty {
                        HStack {
                            Image(systemName: (stepCompleted || challengeCompleted) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor((stepCompleted || challengeCompleted) ? .green : .red)
                                .font(.system(size: 24))
                            
                            Text(feedback)
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundColor((stepCompleted || challengeCompleted) ? .green : .red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(((stepCompleted || challengeCompleted) ? Color.green : Color.red).opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Navigation button for completed steps
                    if stepCompleted {
                        if currentStepIndex == steps.count - 1 {
                            // Final step completed
                            Button(action: {
                                finishChallenge()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                                        .font(.system(size: 20))
                                    
                                    Text("¡Completar Desafío!")
                                        .font(.custom("Poppins-Bold", size: 20))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color.green.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            // Continue to next step
                            Button(action: {
                                moveToNextStep()
                            }) {
                                HStack(spacing: 10) {
                                    Text("Continuar")
                                        .font(.custom("Poppins-Bold", size: 20))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Tips section
                    if !stepCompleted && feedback.contains("Incorrecto") {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Sugerencia:")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.yellow)
                                
                                Text("Intenta pronunciar despacio y claramente. A veces ayuda hacer una breve pausa entre palabras.")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Upcoming challenges preview (small previews of next steps)
                    if currentStepIndex < steps.count - 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Próximos desafíos:")
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(currentStepIndex + 1..<min(currentStepIndex + 3, steps.count), id: \.self) { index in
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text(steps[index].difficulty.rawValue)
                                                    .font(.custom("Poppins-SemiBold", size: 12))
                                                    .foregroundColor(steps[index].difficulty.color)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(steps[index].difficulty.color.opacity(0.2))
                                                    .cornerRadius(10)
                                                
                                                Spacer()
                                                
                                                if completedSteps.contains(index) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 16))
                                                }
                                            }
                                            
                                            Text(steps[index].instructions.components(separatedBy: ".").first ?? "")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding()
                                        .frame(width: 200)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(15)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 15)
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Confetti effect for completed steps
            if confettiCount > 0 {
                SuccessConfetti(count: confettiCount)
                    .allowsHitTesting(false)
            }
            
            // Achievement badge overlay
            if showingAchievement {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                AchievementBadge(
                    title: challengeCompleted ? "¡Dominio de Comandos!" : "¡Paso Completado!",
                    description: challengeCompleted ?
                        "Has completado todos los comandos de voz. ¡Ganaste \(xpEarned) XP!" :
                        "Comando dominado. +\(5 + (streakCount > 1 ? min(streakCount, 5) : 0)) XP",
                    iconName: challengeCompleted ? "trophy.fill" : "star.fill"
                )
                .transition(.scale)
                .onAppear {
                    // Dismiss achievement after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showingAchievement = false
                        }
                    }
                }
            }
        }
        .onAppear {
            speechManager.requestAuthorization { _ in }
        }
    }
    
    private func startBackgroundAnimations() {
        // Start background animation cycle for scale
        withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            gradientScale = 1.3
        }
        
        // Timer to change gradient colors
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.5)) {
                let baseColors: [Color] = [.blue, .purple, .indigo, .teal, .cyan]
                gradientColors[0] = baseColors.randomElement() ?? .blue
                gradientColors[1] = baseColors.randomElement() ?? .purple
            }
        }
    }
    
    private func evaluateCommand() {
        let spoken = speechManager.recognizedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let spokenClean = spoken.components(separatedBy: CharacterSet.punctuationCharacters).joined()
        let expected = steps[currentStepIndex].expectedCommand
        
        if spokenClean.contains(expected) {
            feedback = "¡Correcto! Has pronunciado el comando adecuadamente."
            completeCurrentStep()
        } else {
            feedback = "Incorrecto. Intenta de nuevo. El comando esperado es: \"\(expected)\""
            stepCompleted = false
            streakCount = 0
            showingHint = true
        }
    }
    
    private func completeCurrentStep() {
        stepCompleted = true
        completedSteps.insert(currentStepIndex)
        
        // Update streak and animate
        streakCount += 1
        if streakCount > 1 {
            pulseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                pulseAnimation = false
            }
        }
        
        // Show success effects
        confettiCount = 20
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            confettiCount = 0
        }
        
        // Show badge for first completion or high streaks
        if !challengeCompleted && (streakCount >= 3 || currentStepIndex == 0) {
            xpEarned = 5 + (streakCount > 1 ? min(streakCount, 5) : 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showingAchievement = true
                }
            }
        }
        
        if currentStepIndex == steps.count - 1 {
            challengeCompleted = true
        }
    }
    
    private func moveToNextStep() {
        if currentStepIndex < steps.count - 1 {
            withAnimation {
                showCard = false
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationDegrees = 90
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStepIndex += 1
                feedback = ""
                speechManager.recognizedText = ""
                stepCompleted = false
                showingHint = false
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationDegrees = -90
                }
                
                withAnimation {
                    showCard = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotationDegrees = 0
                    }
                }
            }
        }
    }
    
    private func finishChallenge() {
        xpEarned = 50 + completedSteps.count * 10
        
        // Show achievement
        withAnimation {
            showingAchievement = true
        }
        
        // Lots of confetti!
        confettiCount = 100
        
        // Here you would integrate with your XP system
        // UserDataManager.shared.addXP(xpEarned)
        
        // Add completion to user progress
        let userDataManager = UserDataManager.shared
        userDataManager.userProfile.xpPoints += xpEarned
        userDataManager.userProfile.dailyProgress += xpEarned
        if let questIndex = userDataManager.availableQuests.firstIndex(where: { $0.title == "Desafío de Comandos de Voz" }) {
            userDataManager.markQuestAsCompleted(userDataManager.availableQuests[questIndex].title)
        }
        userDataManager.saveUserData()
        
        // Dismiss achievement after delay and navigate back
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showingAchievement = false
                // Here you would navigate back to the home screen
                // presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Extension to integrate with HomeView
extension UserDataManager {
    // Add Voice Commands Challenge to available quests
    func addVoiceCommandsChallenge() {
        // Check if the challenge already exists
        if availableQuests.contains(where: { $0.title == "Desafío de Comandos de Voz" }) {
            return
        }
        
        // Create the voice commands challenge quest
        let voiceCommandsQuest = Quest(
            title: "Desafío de Comandos de Voz",
            description: "Aprende a programar usando comandos de voz para reforzar tus conocimientos de Swift",
            xpReward: 150,
            duration: 20,
            difficulty: .intermediate,
            learningStyles: ["auditory", "kinesthetic"],
            iconName: "waveform.and.mic",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(VoiceCommandsChallengeView())
        )
        
        // Add to available quests
        availableQuests.append(voiceCommandsQuest)
        
        // If user has auditory learning style, make it the suggested quest
        if userProfile.learningStyles.contains("auditory") {
            var suggestedCopy = voiceCommandsQuest
            suggestedCopy.isRecommended = true
            suggestedCopy.recommendationReason = "Perfecto para aprender programación mientras mejoras tus habilidades de pronunciación"
            suggestedQuest = suggestedCopy
        }
        
        // Save changes
        saveUserData()
    }
}

// MARK: - Interactive Code Preview Component
struct InteractiveCodePreview: View {
    let codeString: String
    let output: String?
    
    @State private var isAnimating = false
    @State private var showOutput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Code section
            VStack(alignment: .leading, spacing: 10) {
                Text("Código:")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                ScrollView {
                    Text(codeString)
                        .font(.custom("Courier", size: 16))
                        .foregroundColor(.white)
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
                .frame(minHeight: 100, maxHeight: 150)
            }
            
            if let output = output {
                // Run button
                Button(action: {
                    withAnimation(.spring()) {
                        isAnimating = true
                        
                        // Show output after delay to simulate running
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                showOutput = true
                            }
                            
                            // Reset animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAnimating = false
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                        
                        Text("Ejecutar")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                }
                .disabled(showOutput)
                
                // Output section
                if showOutput {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resultado:")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(output)
                            .font(.custom("Courier", size: 16))
                            .foregroundColor(.green)
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

struct VoiceCommandsChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCommandsChallengeView()
    }
}
