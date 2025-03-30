//
//  NLPQuizView.swift
//  knowi
//
//  Created by Alumno on 29/03/25.
//

import SwiftUI
import NaturalLanguage
import UIKit

struct NLPQuizView: View {
    // Environment for navigation
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var currentQuestionIndex = 0
    @State private var userAnswer = ""
    @State private var feedback = ""
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var showSuccessView = false
    @State private var xpEarned = 0
    @State private var attemptCount = 0
    @State private var quizCompleted = false
    @State private var isAnalyzing = false
    
    // Haptic feedback
    private let hapticFeedback = UINotificationFeedbackGenerator()
    
    // Current question computed property
    private var currentQuestion: ProgrammingQuestion {
        programmingQuestions[currentQuestionIndex]
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Progress indicator
                    ProgressBar(
                        currentQuestion: currentQuestionIndex + 1,
                        totalQuestions: programmingQuestions.count
                    )
                    .padding(.top, 20)
                    
                    // Question card
                    QuestionCard(
                        question: currentQuestion,
                        userAnswer: $userAnswer,
                        isAnalyzing: $isAnalyzing
                    )
                    .padding(.horizontal)
                    
                    // Submit button
                    Button(action: submitAnswer) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 18))
                            }
                            
                            Text(isAnalyzing ? "Analizando..." : "Enviar respuesta")
                                .font(.custom("Poppins-SemiBold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing ?
                                   Color.blue.opacity(0.5) : Color.blue)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
                    
                    Spacer()
                }
            }
            
            // Feedback overlay
            if showFeedback {
                FeedbackView(
                    isCorrect: isCorrect,
                    feedback: feedback,
                    onContinue: continueToBNextQuestion
                )
                .transition(.opacity)
                .zIndex(1)
            }
            
            // Success view overlay
            if showSuccessView {
                QuizSuccessView(
                    xpEarned: xpEarned,
                    onContinue: {
                        // Return to dashboard
                        updateUserProgress()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .navigationTitle("Quiz de Programación")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hapticFeedback.prepare()
        }
    }
    
    // Handle answer submission
    private func submitAnswer() {
        guard !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isAnalyzing = true
        
        // Use Natural Language Processing to analyze the answer
        DispatchQueue.global(qos: .userInitiated).async {
            let result = analyzeAnswer(userAnswer: userAnswer, question: currentQuestion)
            
            DispatchQueue.main.async {
                isAnalyzing = false
                isCorrect = result.isCorrect
                feedback = result.feedback
                
                // Show feedback
                withAnimation(.easeIn(duration: 0.3)) {
                    showFeedback = true
                }
                
                // Provide haptic feedback
                hapticFeedback.notificationOccurred(isCorrect ? .success : .error)
                
                // Track attempt
                attemptCount += 1
            }
        }
    }
    
    // Continue to next question or show success
    private func continueToBNextQuestion() {
        withAnimation {
            showFeedback = false
        }
        
        // Calculate XP based on attempts (max 50 XP per question)
        let questionXP = max(50 - (attemptCount - 1) * 10, 10)
        xpEarned += questionXP
        
        // Reset for next question
        userAnswer = ""
        attemptCount = 0
        
        // Check if quiz is complete
        if currentQuestionIndex >= programmingQuestions.count - 1 {
            // Show success view
            withAnimation(.easeIn(duration: 0.3)) {
                quizCompleted = true
                showSuccessView = true
            }
        } else {
            // Move to next question
            currentQuestionIndex += 1
        }
    }
    
    // Update user progress in UserDataManager
    private func updateUserProgress() {
        // Access the shared UserDataManager
        let userManager = UserDataManager.shared
        
        // Update user's XP points
        userManager.userProfile.xpPoints += xpEarned
        
        // Update daily progress
        userManager.userProfile.dailyProgress += xpEarned
        
        // Mark this quest as completed
        userManager.markQuestAsCompleted("Quiz de Programación")
        
        // Save the updated user data
        userManager.saveUserData()
    }
    
    // Analyze user answer using NLP
    private func analyzeAnswer(userAnswer: String, question: ProgrammingQuestion) -> (isCorrect: Bool, feedback: String) {
        // 1. Preprocess the answer
        let cleanedAnswer = userAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty answer check
        if cleanedAnswer.isEmpty {
            return (false, "Por favor, escribe una respuesta antes de enviarla.")
        }
        
        // Very short answer check
        if cleanedAnswer.count < 5 {
            return (false, "Tu respuesta es demasiado corta. Por favor, elabora más.")
        }
        
        // 2. Extract key terms from the user's answer
        let userKeyTerms = extractKeyTerms(from: cleanedAnswer)
        
        // 3. Compare with expected key terms
        let correctTerms = question.keyTerms
        let matchedTerms = correctTerms.filter { term in
            userKeyTerms.contains { userTerm in
                userTerm.contains(term.lowercased()) || term.lowercased().contains(userTerm)
            }
        }
        
        // 4. Calculate match percentage
        let matchPercentage = Double(matchedTerms.count) / Double(correctTerms.count)
        
        // 5. Sentiment analysis to detect confusion
        let sentiment = analyzeSentiment(text: cleanedAnswer)
        let confused = sentiment < -0.3
        
        // 6. Determine correctness and generate feedback
        if matchPercentage >= 0.7 {
            // Good answer
            var feedback = "¡Excelente! Tu respuesta incluye conceptos importantes como: \(matchedTerms.joined(separator: ", "))."
            
            // If they missed something important
            if matchPercentage < 1.0 {
                let missedTerms = correctTerms.filter { !matchedTerms.contains($0) }
                feedback += "\n\nPodrías considerar también: \(missedTerms.joined(separator: ", "))."
            }
            
            return (true, feedback)
        } else if matchPercentage >= 0.4 {
            // Partial answer
            let missedTerms = correctTerms.filter { !matchedTerms.contains($0) }
            let feedback = "Respuesta parcial. Mencionaste: \(matchedTerms.joined(separator: ", ")).\n\nPero es importante incluir: \(missedTerms.joined(separator: ", "))."
            return (false, feedback)
        } else if confused {
            // Confused answer
            return (false, "Parece que hay confusión en tu respuesta. Recuerda que \(question.hint)")
        } else {
            // Incorrect answer
            return (false, "Tu respuesta no incluye los conceptos clave. Recuerda que \(question.hint)")
        }
    }
    
    // Extract key terms using NL Tagger
    private func extractKeyTerms(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lemma])
        tagger.string = text
        
        var keyTerms: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .personalName || tag == .organizationName || tag == .placeName {
                let term = String(text[range]).lowercased()
                keyTerms.append(term)
            }
            return true
        }
        
        // Also extract nouns and verbs
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if tag == .noun || tag == .verb {
                let term = String(text[range]).lowercased()
                if term.count > 2 && !keyTerms.contains(term) { // Avoid short words
                    keyTerms.append(term)
                }
            }
            return true
        }
        
        // Handle technical terms that might not be recognized as named entities
        let techTerms = ["algoritmo", "variable", "función", "clase", "objeto", "herencia",
                        "condición", "bucle", "for", "while", "if", "else", "array", "lista",
                        "diccionario", "int", "string", "boolean", "float", "método", "propiedad",
                        "api", "framework", "lenguaje", "programación", "desarrollo", "biblioteca",
                        "librería", "stack", "heap", "memoria", "puntero", "referencia", "valor",
                        "compilador", "intérprete", "código", "sintaxis", "operador", "recursión"]
        
        for term in techTerms {
            if text.lowercased().contains(term) && !keyTerms.contains(term) {
                keyTerms.append(term)
            }
        }
        
        return keyTerms
    }
    
    // Analyze sentiment using NLTagger
    private func analyzeSentiment(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentiment?.rawValue ?? "0") ?? 0
        
        return score
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let currentQuestion: Int
    let totalQuestions: Int
    
    private var progress: CGFloat {
        CGFloat(currentQuestion) / CGFloat(totalQuestions)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Pregunta \(currentQuestion) de \(totalQuestions)")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .foregroundColor(Color.white.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress fill
                    Rectangle()
                        .foregroundColor(Color.white)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}

// MARK: - Question Card Component
struct QuestionCard: View {
    let question: ProgrammingQuestion
    @Binding var userAnswer: String
    @Binding var isAnalyzing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Difficulty pill
            HStack {
                Text(question.difficulty.rawValue)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(question.difficulty.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(question.difficulty.color.opacity(0.2))
                    .cornerRadius(15)
                
                Spacer()
                
                // Category tag
                Text(question.category)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(15)
            }
            
            // Question text
            Text(question.text)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.top, 5)
            
            // Code example if available
            if let codeExample = question.codeExample {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(codeExample)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            // Answer input
            VStack(alignment: .leading, spacing: 10) {
                Text("Tu respuesta:")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.black.opacity(0.7))
                
                ZStack(alignment: .topLeading) {
                    if userAnswer.isEmpty {
                        Text("Escribe tu respuesta aquí...")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    
                    TextEditor(text: $userAnswer)
                        .font(.custom("Poppins-Regular", size: 16))
                        .padding(5)
                        .frame(minHeight: 120)
                        .cornerRadius(8)
                        .disabled(isAnalyzing)
                        .opacity(userAnswer.isEmpty ? 0.85 : 1)
                    
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Feedback View Component
struct FeedbackView: View {
    let isCorrect: Bool
    let feedback: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {} // Prevents taps from passing through
            
            VStack(spacing: 20) {
                // Feedback icon
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(isCorrect ? .green : .orange)
                
                // Feedback title
                Text(isCorrect ? "¡Correcto!" : "Revisa tu respuesta")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                
                // Feedback text
                ScrollView {
                    Text(feedback)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 200)
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continuar")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(isCorrect ? Color.green : Color.orange)
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Success View Component
struct QuizSuccessView: View {
    let xpEarned: Int
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {} // Prevents taps from passing through
            
            VStack(spacing: 25) {
                // Success icon
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                // Success title
                Text("¡Quiz completado!")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.white)
                
                // Success message
                Text("Has demostrado un buen entendimiento de conceptos de programación.")
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // XP earned
                VStack {
                    Text("XP ganado:")
                        .font(.custom("Poppins-Medium", size: 18))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(xpEarned)")
                        .font(.custom("Poppins-Bold", size: 36))
                        .foregroundColor(.yellow)
                }
                .padding(.vertical, 10)
                
                // Return to dashboard button
                Button(action: onContinue) {
                    Text("Volver al inicio")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 15)
            .padding(30)
        }
    }
}

// MARK: - Programming Question Model
struct ProgrammingQuestion {
    let id = UUID()
    let text: String
    let codeExample: String?
    let difficulty: QuestDifficulty
    let category: String
    let keyTerms: [String]
    let hint: String
}

// MARK: - Questions Data
extension NLPQuizView {
    var programmingQuestions: [ProgrammingQuestion] {
        [
            // Question 1: Variables
            ProgrammingQuestion(
                text: "Explica qué son las variables en programación y para qué se utilizan.",
                codeExample: """
                // Ejemplos de variables en Swift
                var puntuación = 0
                var nombre = "Jugador1"
                var activo = true
                """,
                difficulty: .beginner,
                category: "Fundamentos",
                keyTerms: ["variables", "almacenar", "datos", "valor", "memoria", "nombre", "contenedor", "cambiar", "asignar"],
                hint: "las variables son contenedores que almacenan datos en la memoria del programa y pueden cambiar de valor."
            ),
            
            // Question 2: Functions
            ProgrammingQuestion(
                text: "¿Qué es una función en programación y cuáles son sus beneficios?",
                codeExample: """
                // Ejemplo de función en Swift
                func calcularÁrea(largo: Int, ancho: Int) -> Int {
                    return largo * ancho
                }
                
                // Llamar a la función
                let área = calcularÁrea(largo: 5, ancho: 3)
                """,
                difficulty: .beginner,
                category: "Fundamentos",
                keyTerms: ["función", "reutilizar", "código", "tarea", "parámetros", "devolver", "retornar", "modular", "organizar"],
                hint: "las funciones son bloques de código reutilizables que realizan tareas específicas y pueden recibir parámetros y devolver valores."
            ),
            
            // Question 3: Conditionals
            ProgrammingQuestion(
                text: "Explica cómo funcionan las estructuras condicionales (if-else) y por qué son importantes.",
                codeExample: """
                // Ejemplo de estructura condicional en Swift
                let temperatura = 25
                
                if temperatura > 30 {
                    print("Hace calor")
                } else if temperatura > 20 {
                    print("Temperatura agradable")
                } else {
                    print("Hace frío")
                }
                """,
                difficulty: .beginner,
                category: "Control de Flujo",
                keyTerms: ["condición", "decisión", "if", "else", "verdadero", "falso", "rama", "evaluar", "comparación"],
                hint: "las estructuras condicionales permiten a un programa tomar decisiones basadas en si una condición es verdadera o falsa."
            ),
            
            // Question 4: Loops
            ProgrammingQuestion(
                text: "Describe los diferentes tipos de bucles (loops) y cómo se utilizan en programación.",
                codeExample: """
                // Ejemplo de bucles en Swift
                
                // For loop
                for i in 1...5 {
                    print("Número: \\(i)")
                }
                
                // While loop
                var contador = 0
                while contador < 5 {
                    print("Contador: \\(contador)")
                    contador += 1
                }
                """,
                difficulty: .intermediate,
                category: "Control de Flujo",
                keyTerms: ["bucle", "repetición", "for", "while", "iteración", "condición", "incremento", "recorrer", "colección"],
                hint: "los bucles permiten repetir un bloque de código múltiples veces, ya sea un número determinado de veces o mientras se cumpla una condición."
            ),
            
            // Question 5: Object-Oriented Programming
            ProgrammingQuestion(
                text: "Explica los conceptos básicos de la Programación Orientada a Objetos (POO).",
                codeExample: """
                // Ejemplo de clase en Swift
                class Persona {
                    var nombre: String
                    var edad: Int
                    
                    init(nombre: String, edad: Int) {
                        self.nombre = nombre
                        self.edad = edad
                    }
                    
                    func saludar() {
                        print("Hola, me llamo \\(nombre)")
                    }
                }
                
                // Crear un objeto
                let ana = Persona(nombre: "Ana", edad: 25)
                ana.saludar()
                """,
                difficulty: .intermediate,
                category: "POO",
                keyTerms: ["clase", "objeto", "instancia", "atributo", "método", "encapsulamiento", "herencia", "polimorfismo", "propiedad"],
                hint: "la POO es un paradigma que se basa en el concepto de clases y objetos, donde los objetos son instancias de clases que tienen propiedades y métodos."
            )
        ]
    }
}

// MARK: - Preview Provider
struct NLPQuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NLPQuizView()
        }
    }
}
