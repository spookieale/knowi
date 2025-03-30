import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Music Programming View
struct MusicProgrammingView: View {
    // Environment objects for navigation
    @Environment(\.presentationMode) var presentationMode
    
    // Observable state for AudioEngine
    @StateObject private var audioController = AudioController()
    @State private var currentLesson: Int = 0
    @State private var userSequence: [MusicalNote] = []
    @State private var isPlaying = false
    @State private var showSuccess = false
    @State private var showHint = false
    @State private var attemptCount = 0
    @State private var xpEarned = 0
    @State private var isCompleted = false
    @State private var shouldReturnToDashboard = false
    
    // Haptic feedback manager
    private let hapticFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Text(lessons[currentLesson].title)
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .multilineTextAlignment(.center)
                        
                        Text(lessons[currentLesson].subtitle)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    
                    // Concept explanation card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Concepto:")
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundColor(.blue)
                            
                            Text(lessons[currentLesson].concept)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.black.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let codeExample = lessons[currentLesson].codeExample {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Código:")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.blue.opacity(0.8))
                                    
                                    Text(codeExample)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(10)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Text("Crea una secuencia musical que represente este concepto.")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.purple)
                                .padding(.top, 5)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Musical sequence challenge
                    VStack(spacing: 15) {
                        Text("Objetivo musical:")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                        
                        Text(lessons[currentLesson].challenge)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Play example button
                        Button(action: {
                            playExampleSequence()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16))
                                Text("Escuchar ejemplo")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(25)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.top, 5)
                        
                        // User sequence visualization
                        HStack(spacing: 8) {
                            ForEach(userSequence.indices, id: \.self) { index in
                                Circle()
                                    .fill(userSequence[index].color)
                                    .frame(width: 25, height: 25)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .scaleEffect(isPlaying && audioController.currentlyPlayingIndex == index ? 1.3 : 1.0)
                                    .animation(.spring(), value: isPlaying && audioController.currentlyPlayingIndex == index)
                            }
                            
                            // Placeholder circles
                            ForEach(userSequence.count..<lessons[currentLesson].expectedSequence.count, id: \.self) { _ in
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: 25, height: 25)
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding()
                    
                    // Musical buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(MusicalNote.allCases, id: \.self) { note in
                            Button(action: {
                                addNoteToSequence(note)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(note.color)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: note.symbol)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Control buttons
                    HStack(spacing: 20) {
                        // Reset button
                        Button(action: {
                            resetSequence()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reiniciar")
                            }
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(25)
                        }
                        
                        // Play button
                        Button(action: {
                            playUserSequence()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Reproducir")
                            }
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(25)
                        }
                        .disabled(userSequence.isEmpty)
                        .opacity(userSequence.isEmpty ? 0.5 : 1)
                        
                        // Submit button
                        Button(action: {
                            checkAnswer()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Verificar")
                            }
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                        .disabled(userSequence.count != lessons[currentLesson].expectedSequence.count)
                        .opacity(userSequence.count != lessons[currentLesson].expectedSequence.count ? 0.5 : 1)
                    }
                    .padding(.top, 10)
                    
                    // Hint button
                    Button(action: {
                        withAnimation {
                            showHint.toggle()
                        }
                    }) {
                        Text(showHint ? "Ocultar pista" : "Mostrar pista")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 5)
                    }
                    
                    if showHint {
                        Text(lessons[currentLesson].hint)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    Spacer(minLength: 30)
                }
            }
            
            // Success popup
            if showSuccess {
                SuccessView(
                    isCompleted: $isCompleted,
                    xpEarned: xpEarned,
                    lessonComplete: currentLesson == lessons.count - 1,
                    onContinue: {
                        if currentLesson < lessons.count - 1 {
                            currentLesson += 1
                            resetSequence()
                            showSuccess = false
                        } else {
                            isCompleted = true
                            showSuccess = false
                            // Update user's XP in the UserDataManager
                            updateUserProgress()
                            // Return to dashboard after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Programación con Música")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hapticFeedback.prepare()
            audioController.prepareAudioEngine()
        }
        .onDisappear {
            audioController.stopAudioEngine()
        }
    }
    
    // MARK: - Audio Functions
    private func addNoteToSequence(_ note: MusicalNote) {
        if userSequence.count < lessons[currentLesson].expectedSequence.count {
            userSequence.append(note)
            audioController.playNote(note)
            hapticFeedback.notificationOccurred(.success)
        }
    }
    
    // Update user progress in UserDataManager
    private func updateUserProgress() {
        // Calculate total XP earned from all lessons
        let totalXP = xpEarned * lessons.count
        
        // Access the shared UserDataManager
        let userManager = UserDataManager.shared
        
        // Update user's XP points
        userManager.userProfile.xpPoints += totalXP
        
        // Update daily progress
        userManager.userProfile.dailyProgress += totalXP
        
        // Mark this quest as completed
        userManager.markQuestAsCompleted("Música y Programación")
        
        // Save the updated user data
        userManager.saveUserData()
    }
    
    private func playUserSequence() {
        isPlaying = true
        audioController.playSequence(userSequence) {
            isPlaying = false
        }
    }
    
    private func playExampleSequence() {
        isPlaying = true
        let targetSequence = lessons[currentLesson].expectedSequence
        audioController.playSequence(targetSequence) {
            isPlaying = false
        }
    }
    
    private func resetSequence() {
        userSequence = []
    }
    
    private func checkAnswer() {
        let expected = lessons[currentLesson].expectedSequence
        
        // Check if sequences match
        let isCorrect = userSequence == expected
        
        if isCorrect {
            // Calculate XP based on attempts
            xpEarned = max(100 - (attemptCount * 20), 50)
            
            // Success feedback
            hapticFeedback.notificationOccurred(.success)
            
            // Audio success sequence
            audioController.playSuccessSequence()
            
            // Show success popup
            withAnimation {
                showSuccess = true
            }
        } else {
            // Incorrect feedback
            hapticFeedback.notificationOccurred(.error)
            
            // Play error sound
            audioController.playErrorSound()
            
            // Increment attempt count
            attemptCount += 1
        }
    }
}

// MARK: - Audio Controller
class AudioController: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var sampler: AVAudioUnitSampler?
    private var timer: Timer?
    
    @Published var currentlyPlayingIndex: Int = -1
    
    func prepareAudioEngine() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        
        guard let audioEngine = audioEngine,
              let sampler = sampler else { return }
        
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Could not start audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        timer?.invalidate()
        timer = nil
        audioEngine?.stop()
    }
    
    func playNote(_ note: MusicalNote) {
        guard let sampler = sampler else { return }
        sampler.startNote(UInt8(note.midiNote), withVelocity: 100, onChannel: 0)
        
        // Stop note after a short duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sampler.stopNote(UInt8(note.midiNote), onChannel: 0)
        }
    }
    
    func playSequence(_ sequence: [MusicalNote], completion: @escaping () -> Void) {
        guard !sequence.isEmpty else {
            completion()
            return
        }
        
        // Cancel any existing timer
        timer?.invalidate()
        
        var index = 0
        currentlyPlayingIndex = 0
        
        // Play the first note immediately
        playNote(sequence[0])
        
        // Schedule the rest of the notes
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            index += 1
            
            if index < sequence.count {
                self.currentlyPlayingIndex = index
                self.playNote(sequence[index])
            } else {
                timer.invalidate()
                self.currentlyPlayingIndex = -1
                completion()
            }
        }
    }
    
    func playSuccessSequence() {
        let successNotes: [MusicalNote] = [.c, .e, .g, .highC]
        
        var delay: TimeInterval = 0
        for note in successNotes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playNote(note)
            }
            delay += 0.2
        }
    }
    
    func playErrorSound() {
        guard let sampler = sampler else { return }
        
        // Play a dissonant chord
        sampler.startNote(60, withVelocity: 100, onChannel: 0)
        sampler.startNote(61, withVelocity: 100, onChannel: 0)
        
        // Stop after a short duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sampler.stopNote(60, onChannel: 0)
            sampler.stopNote(61, onChannel: 0)
        }
    }
}

// MARK: - Musical Note
enum MusicalNote: CaseIterable {
    case c      // Do
    case d      // Re
    case e      // Mi
    case f      // Fa
    case g      // Sol
    case a      // La
    case b      // Si
    case highC  // Do (octave higher)
    
    var midiNote: Int {
        switch self {
        case .c: return 60      // Middle C
        case .d: return 62
        case .e: return 64
        case .f: return 65
        case .g: return 67
        case .a: return 69
        case .b: return 71
        case .highC: return 72  // C one octave higher
        }
    }
    
    var symbol: String {
        switch self {
        case .c: return "c.circle.fill"
        case .d: return "d.circle.fill"
        case .e: return "e.circle.fill"
        case .f: return "f.circle.fill"
        case .g: return "g.circle.fill"
        case .a: return "a.circle.fill"
        case .b: return "b.circle.fill"
        case .highC: return "c.square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .c: return .red
        case .d: return .orange
        case .e: return .yellow
        case .f: return .green
        case .g: return .blue
        case .a: return .purple
        case .b: return .pink
        case .highC: return .red.opacity(0.7)
        }
    }
}

// MARK: - Lesson Model
struct MusicProgrammingLesson {
    let title: String
    let subtitle: String
    let concept: String
    let codeExample: String?
    let challenge: String
    let hint: String
    let expectedSequence: [MusicalNote]
}

// MARK: - Lesson Data
extension MusicProgrammingView {
    var lessons: [MusicProgrammingLesson] {
        [
            // Lesson 1: Variables
            MusicProgrammingLesson(
                title: "Variables y Constantes",
                subtitle: "Almacenando información en la programación",
                concept: "En la programación, las variables son como contenedores que guardan datos. Cuando creas una variable, reservas un espacio en la memoria con un nombre específico. Las constantes son similares, pero su valor no puede cambiar después de asignarse.",
                codeExample: """
                // Variable (puede cambiar)
                var puntuacion = 10
                puntuacion = 20
                
                // Constante (no puede cambiar)
                let nombreUsuario = "Alex"
                """,
                challenge: "Crea una secuencia musical que represente la asignación y cambio de una variable. Usa la misma nota al principio y al final, con notas distintas en medio para representar el cambio.",
                hint: "Intenta usar Do (rojo) al principio y final, con otras notas en medio para mostrar el cambio de valor.",
                expectedSequence: [.c, .e, .g, .c]
            ),
            
            // Lesson 2: If Statements
            MusicProgrammingLesson(
                title: "Estructuras Condicionales",
                subtitle: "Tomando decisiones en el código",
                concept: "Las estructuras condicionales (if/else) permiten que un programa tome decisiones basadas en condiciones. Si la condición es verdadera, se ejecuta un bloque de código; si es falsa, se puede ejecutar otro bloque diferente.",
                codeExample: """
                let temperatura = 25
                
                if temperatura > 30 {
                    print("Hace calor")
                } else if temperatura > 20 {
                    print("Temperatura agradable")
                } else {
                    print("Hace frío")
                }
                """,
                challenge: "Crea una secuencia musical que represente una decisión con dos caminos posibles. Comienza con una nota, luego elige entre dos patrones diferentes.",
                hint: "Comienza con Do (rojo), luego crea un patrón ascendente para representar el camino 'verdadero'.",
                expectedSequence: [.c, .d, .e, .f, .g]
            ),
            
            // Lesson 3: Loops
            MusicProgrammingLesson(
                title: "Bucles (Loops)",
                subtitle: "Repitiendo acciones en programación",
                concept: "Los bucles permiten repetir bloques de código varias veces. Son útiles cuando necesitas realizar la misma acción múltiples veces o procesar colecciones de datos de manera eficiente.",
                codeExample: """
                // Bucle for que repite 3 veces
                for i in 1...3 {
                    print("Repetición \\(i)")
                }
                
                // Bucle while
                var contador = 0
                while contador < 3 {
                    print("Contador: \\(contador)")
                    contador += 1
                }
                """,
                challenge: "Crea un patrón musical que represente un bucle, utilizando una secuencia de notas que se repita. El patrón debe tener una clara estructura repetitiva.",
                hint: "Intenta un patrón como Do-Mi-Sol, Do-Mi-Sol para representar una acción que se repite dos veces.",
                expectedSequence: [.c, .e, .g, .c, .e, .g]
            )
        ]
    }
}

// MARK: - Success View
struct SuccessView: View {
    @Binding var isCompleted: Bool
    let xpEarned: Int
    let lessonComplete: Bool
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Success icon
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                // Success text
                Text("¡Excelente trabajo!")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                
                Text("Has completado este desafío correctamente.")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // XP earned
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    
                    Text("+\(xpEarned) XP")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.yellow)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(20)
                
                // Continue button
                Button(action: onContinue) {
                    Text(lessonComplete ? "Finalizar" : "Continuar")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 15)
            .padding(30)
        }
    }
}

// MARK: - Preview
struct MusicProgrammingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MusicProgrammingView()
        }
    }
}
