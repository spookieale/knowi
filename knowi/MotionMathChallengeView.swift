//
//  MotionMathChallengeView.swift
//  knowi
//
//  Created on 29/03/25.
//

import SwiftUI
import CoreMotion

// Model for math challenge problem
struct MathProblem {
    let question: String
    let options: [String]
    let correctAnswer: Int
    let difficulty: Int // 1-3 scale
    let points: Int
    
    static func generateRandomProblem(difficulty: Int) -> MathProblem {
        let difficultyMultiplier = difficulty
        
        // Generate different types of problems based on difficulty
        let problemType = Int.random(in: 0...3)
        
        switch problemType {
        case 0: // Addition
            let num1 = Int.random(in: 1...(10 * difficultyMultiplier))
            let num2 = Int.random(in: 1...(10 * difficultyMultiplier))
            let answer = num1 + num2
            
            let options = generateOptions(correctAnswer: answer, difficulty: difficulty)
            
            return MathProblem(
                question: "\(num1) + \(num2) = ?",
                options: options,
                correctAnswer: options.firstIndex(of: "\(answer)") ?? 0,
                difficulty: difficulty,
                points: 25 * difficulty
            )
            
        case 1: // Subtraction
            let num2 = Int.random(in: 1...(10 * difficultyMultiplier))
            let num1 = Int.random(in: num2...(10 * difficultyMultiplier + num2)) // Ensure positive result
            let answer = num1 - num2
            
            let options = generateOptions(correctAnswer: answer, difficulty: difficulty)
            
            return MathProblem(
                question: "\(num1) - \(num2) = ?",
                options: options,
                correctAnswer: options.firstIndex(of: "\(answer)") ?? 0,
                difficulty: difficulty,
                points: 25 * difficulty
            )
            
        case 2: // Multiplication
            let num1 = Int.random(in: 2...(5 + difficultyMultiplier))
            let num2 = Int.random(in: 2...(5 + difficultyMultiplier))
            let answer = num1 * num2
            
            let options = generateOptions(correctAnswer: answer, difficulty: difficulty)
            
            return MathProblem(
                question: "\(num1) × \(num2) = ?",
                options: options,
                correctAnswer: options.firstIndex(of: "\(answer)") ?? 0,
                difficulty: difficulty,
                points: 35 * difficulty
            )
            
        case 3: // Division (for higher difficulties) or simple equation
            if difficulty > 1 {
                // Division with whole number results
                let num2 = Int.random(in: 2...(5 + difficultyMultiplier))
                let answer = Int.random(in: 1...10)
                let num1 = num2 * answer
                
                let options = generateOptions(correctAnswer: answer, difficulty: difficulty)
                
                return MathProblem(
                    question: "\(num1) ÷ \(num2) = ?",
                    options: options,
                    correctAnswer: options.firstIndex(of: "\(answer)") ?? 0,
                    difficulty: difficulty,
                    points: 40 * difficulty
                )
            } else {
                // Simple equation for difficulty 1
                let x = Int.random(in: 1...10)
                let num2 = Int.random(in: 1...10)
                let sum = x + num2
                
                let options = generateOptions(correctAnswer: x, difficulty: difficulty)
                
                return MathProblem(
                    question: "x + \(num2) = \(sum), x = ?",
                    options: options,
                    correctAnswer: options.firstIndex(of: "\(x)") ?? 0,
                    difficulty: difficulty,
                    points: 30 * difficulty
                )
            }
        default:
            // Default case (should never reach here)
            return MathProblem(
                question: "2 + 2 = ?",
                options: ["3", "4", "5", "6"],
                correctAnswer: 1,
                difficulty: 1,
                points: 25
            )
        }
    }
    
    static private func generateOptions(correctAnswer: Int, difficulty: Int) -> [String] {
        var options = ["\(correctAnswer)"]
        
        // Generate wrong options
        while options.count < 4 {
            // Offset ranges depend on difficulty
            let offsets: [Int]
            switch difficulty {
            case 1:
                offsets = [-2, -1, 1, 2]
            case 2:
                offsets = [-3, -2, -1, 1, 2, 3]
            default:
                offsets = [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5]
            }
            
            if let offset = offsets.randomElement() {
                let wrongAnswer = correctAnswer + offset
                if wrongAnswer > 0 && !options.contains("\(wrongAnswer)") {
                    options.append("\(wrongAnswer)")
                }
            }
        }
        
        // Shuffle options
        return options.shuffled()
    }
}

// Game state manager
class MotionMathGameState: ObservableObject {
    @Published var currentProblem: MathProblem
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 60
    @Published var selectedAnswer: Int? = nil
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    @Published var problemsSolved: Int = 0
    @Published var challengeCompleted: Bool = false
    @Published var currentTarget: MotionTarget = .left
    @Published var successfulMoves: Int = 0
    @Published var showTutorial: Bool = true
    
    private var timer: Timer?
    private var difficulty: Int
    let motionManager = CMMotionManager()
    
    // Motion targets for device tilting
    enum MotionTarget {
        case left, right, up, down
        
        var description: String {
            switch self {
            case .left: return "izquierda"
            case .right: return "derecha"
            case .up: return "arriba"
            case .down: return "abajo"
            }
        }
        
        var icon: String {
            switch self {
            case .left: return "arrow.left"
            case .right: return "arrow.right"
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            }
        }
        
        static func random() -> MotionTarget {
            let all: [MotionTarget] = [.left, .right, .up, .down]
            return all.randomElement() ?? .left
        }
    }
    
    init(difficulty: Int = 1) {
        self.difficulty = difficulty
        self.currentProblem = MathProblem.generateRandomProblem(difficulty: difficulty)
        setupMotionDetection()
    }
    
    func startGame() {
        resetGame()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.endGame()
            }
        }
    }
    
    func resetGame() {
        score = 0
        timeRemaining = 60
        problemsSolved = 0
        challengeCompleted = false
        selectedAnswer = nil
        showFeedback = false
        successfulMoves = 0
        generateNewProblem()
    }
    
    func endGame() {
        timer?.invalidate()
        timer = nil
        
        // Determine if challenge is completed based on score/problems solved
        challengeCompleted = problemsSolved >= 8
    }
    
    func selectAnswer(_ index: Int) {
        selectedAnswer = index
        showFeedback = true
        
        isCorrect = (index == currentProblem.correctAnswer)
        
        if isCorrect {
            score += currentProblem.points
            problemsSolved += 1
            
            // Move to new problem after feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, !self.challengeCompleted else { return }
                
                self.showFeedback = false
                self.selectedAnswer = nil
                self.generateNewProblem()
            }
        } else {
            // Allow retrying after incorrect
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                
                self.showFeedback = false
                self.selectedAnswer = nil
                
                // Regenerate problem after 2 wrong attempts
                if self.successfulMoves == 0 {
                    self.generateNewProblem()
                }
            }
        }
    }
    
    func generateNewProblem() {
        // Adjust difficulty based on performance
        if problemsSolved > 0 && problemsSolved % 5 == 0 && difficulty < 3 {
            difficulty += 1
        }
        
        // Generate new problem and motion target
        currentProblem = MathProblem.generateRandomProblem(difficulty: difficulty)
        currentTarget = MotionTarget.random()
        successfulMoves = 0
    }
    
    private func setupMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil, !self.showFeedback else { return }
            
            // Get device orientation
            let roll = motion.attitude.roll  // Left/Right tilt
            let pitch = motion.attitude.pitch // Up/Down tilt
            
            // Check for threshold to trigger action
            let threshold: Double = 0.5
            
            // Detect motion based on current target
            switch self.currentTarget {
            case .left where roll < -threshold:
                self.handleSuccessfulMotion()
            case .right where roll > threshold:
                self.handleSuccessfulMotion()
            case .up where pitch < -threshold:
                self.handleSuccessfulMotion()
            case .down where pitch > threshold:
                self.handleSuccessfulMotion()
            default:
                break
            }
        }
    }
    
    func handleSuccessfulMotion() {
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        successfulMoves += 1
        
        // After successful motion, show problem options if we have 2 successful moves
        if successfulMoves >= 2 {
            // Show answer options
            // These will be handled by the view
        } else {
            // Change to a new target direction for the next motion
            currentTarget = MotionTarget.random()
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
    }
}

// View showing a motion instruction with arrow
struct MotionInstructionView: View {
    let target: MotionMathGameState.MotionTarget
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Inclina tu dispositivo")
                .font(.custom("Poppins-SemiBold", size: 22))
                .foregroundColor(.white)
            
            Text("hacia \(target.description)")
                .font(.custom("Poppins-SemiBold", size: 24))
                .foregroundColor(.white)
            
            Image(systemName: target.icon)
                .font(.system(size: 80))
                .foregroundColor(.white)
                .padding()
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding()
    }
}

// Main view for the motion math challenge
struct MotionMathChallengeView: View {
    @StateObject private var gameState = MotionMathGameState()
    @State private var showCompletionModal = false
    @Environment(\.presentationMode) var presentationMode
    var onComplete: ((Int) -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Background
            Color.blue.opacity(0.1).edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header with score and timer
                HStack {
                    Button(action: {
                        gameState.stopMotionUpdates()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Score display
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(gameState.score) XP")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // Timer display
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.red)
                        
                        Text("\(gameState.timeRemaining)s")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // Progress bar
                ProgressView(value: Double(gameState.problemsSolved), total: 8.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                    .padding(.horizontal)
                
                Spacer()
                
                // Content area
                if gameState.showTutorial {
                    // Tutorial
                    VStack(spacing: 20) {
                        Text("Challenge matemático con movimiento")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Inclina tu dispositivo para resolver problemas matemáticos. Necesitarás hacer dos movimientos correctos para desbloquear cada pregunta.")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        // Illustration
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 100))
                            .foregroundColor(.blue)
                            .rotationEffect(Angle(degrees: 15))
                            .overlay(
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .offset(x: 50, y: -50)
                            )
                            .padding(.bottom, 40)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                gameState.showTutorial = false
                                gameState.startGame()
                            }
                        }) {
                            Text("Comenzar")
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundColor(.white)
                                .padding(.horizontal, 50)
                                .padding(.vertical, 15)
                                .background(Color.blue)
                                .cornerRadius(30)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding()
                    
                } else if gameState.successfulMoves < 2 {
                    // Motion instruction
                    MotionInstructionView(target: gameState.currentTarget)
                    
                    // Visualization of successful moves
                    HStack(spacing: 20) {
                        Circle()
                            .fill(gameState.successfulMoves > 0 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .fill(gameState.successfulMoves > 1 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                    }
                    .padding(.top, 20)
                    
                } else {
                    // Question view
                    VStack(spacing: 30) {
                        // Problem statement
                        Text(gameState.currentProblem.question)
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Answer options grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(0..<gameState.currentProblem.options.count, id: \.self) { index in
                                Button(action: {
                                    if gameState.selectedAnswer == nil {
                                        gameState.selectAnswer(index)
                                    }
                                }) {
                                    Text(gameState.currentProblem.options[index])
                                        .font(.custom("Poppins-SemiBold", size: 24))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(backgroundColor(for: index))
                                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                        )
                                        .overlay(
                                            gameState.showFeedback && index == gameState.currentProblem.correctAnswer ?
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.green, lineWidth: 3) : nil
                                        )
                                }
                                .disabled(gameState.showFeedback)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical)
            
            // Completion modal overlay
            if gameState.challengeCompleted {
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        showCompletionModal = true
                    }
                
                // Completion modal
                VStack(spacing: 20) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 30)
                    
                    Text("¡Excelente trabajo!")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.black)
                    
                    Text("Has completado el desafío matemático")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Puntuación: \(gameState.score) XP")
                                .font(.custom("Poppins-SemiBold", size: 16))
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "number.circle.fill")
                                .foregroundColor(.blue)
                            Text("Problemas resueltos: \(gameState.problemsSolved)")
                                .font(.custom("Poppins-SemiBold", size: 16))
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                            Text("Tiempo restante: \(gameState.timeRemaining)s")
                                .font(.custom("Poppins-SemiBold", size: 16))
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Button(action: {
                        gameState.stopMotionUpdates()
                        // Call the completion handler with the score
                        onComplete?(gameState.score)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Volver al inicio")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(30)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                .frame(width: 320)
                .background(Color.white)
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onDisappear {
            gameState.stopMotionUpdates()
        }
    }
    
    // Helper function for background color
    private func backgroundColor(for index: Int) -> Color {
        if gameState.showFeedback && gameState.selectedAnswer == index {
            return gameState.isCorrect ? Color.green : Color.red
        } else if gameState.selectedAnswer == index {
            return Color.blue.opacity(0.7)
        } else {
            return Color.blue
        }
    }
}

// Preview
struct MotionMathChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        MotionMathChallengeView()
    }
}

// Extension to add the motion math challenge to the quest options
extension HomeView {
    func addMotionMathChallenge() -> Quest {
        return Quest(
            title: "Desafío Matemático con Movimiento",
            description: "Resuelve problemas matemáticos inclinando tu dispositivo en diferentes direcciones",
            xpReward: 180,
            duration: 15,
            difficulty: .intermediate,
            learningStyles: ["kinesthetic", "visual"],
            iconName: "function",
            isCompleted: false,
            completionPercentage: 0,
            destination: AnyView(MotionMathChallengeView(onComplete: { score in
                // Update user XP when the challenge is completed
                UserDataManager.shared.userProfile.xpPoints += score
                UserDataManager.shared.userProfile.dailyProgress += score
                UserDataManager.shared.saveUserData()
                
                // Mark quest as completed
                UserDataManager.shared.markQuestAsCompleted("Desafío Matemático con Movimiento")
            })),
            isRecommended: true,
            recommendationReason: "Perfecto para tu estilo de aprendizaje kinestésico"
        )
    }
}
