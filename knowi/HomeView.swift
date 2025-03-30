//
//  HomeView.swift
//  knowi
//
//  Created by Alumno on 29/03/25.
//

import SwiftUI
import CoreMotion

// Model for user profile data
struct UserProfile: Codable {
    var name: String
    var avatarName: String
    var xpPoints: Int
    var dailyGoal: Int
    var dailyProgress: Int
    var streak: Int
    var learningStyles: [String]
    
    // Sample user for preview
    static let sample = UserProfile(
        name: "Alex",
        avatarName: "avatar1",
        xpPoints: 1250,
        dailyGoal: 100,
        dailyProgress: 65,
        streak: 7,
        learningStyles: ["visual", "kinesthetic"]
    )
}

// Model for quest/lesson data
struct Quest: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let xpReward: Int
    let duration: Int // minutes
    let difficulty: QuestDifficulty
    let learningStyles: [String]
    let iconName: String
    var isCompleted: Bool
    var completionPercentage: Double
    let destination: AnyView?
    
    // For AI-suggested quests
    var isRecommended: Bool = false
    var recommendationReason: String = ""
}

enum QuestDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        }
    }
}

// Manager for user data and quests
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    @Published var userProfile: UserProfile
    @Published var availableQuests: [Quest] = []
    @Published var recentQuests: [Quest] = []
    @Published var suggestedQuest: Quest?
    
    // Core ML integration points will be added here
    private var mlRecommendationSystem: Any? = nil
    
    init() {
        // Load user data from UserDefaults or create sample
        if let userData = UserDefaults.standard.data(forKey: "userProfile"),
           let decodedUser = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            self.userProfile = decodedUser
        } else {
            // Sample data for development
            self.userProfile = UserProfile.sample
        }
        
        // Load quests and generate recommendations
        loadQuests()
        generateRecommendations()
    }
    
    func saveUserData() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
    
    private func loadQuests() {
        // Create quests with real destinations to our learning activities
        let musicProgrammingQuest = Quest(
            title: "Música y Programación",
            description: "Aprende conceptos de programación a través de patrones musicales",
            xpReward: 150,
            duration: 25,
            difficulty: .intermediate,
            learningStyles: ["auditory"],
            iconName: "music.note",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(MusicProgrammingView())
        )
        
        let nlpQuizQuest = Quest(
            title: "Quiz de Programación",
            description: "Demuestra tus conocimientos respondiendo preguntas sobre programación",
            xpReward: 200,
            duration: 30,
            difficulty: .intermediate,
            learningStyles: ["reading"],
            iconName: "text.book.closed",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(NLPQuizView())
        )
        
        let arPuzzleQuest = Quest(
            title: "Rompecabezas AR",
            description: "Resuelve rompecabezas en realidad aumentada",
            xpReward: 180,
            duration: 20,
            difficulty: .beginner,
            learningStyles: ["kinesthetic", "visual"],
            iconName: "cube",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(ARPuzzleGameView())
        )
        
        // Add all quests to available quests
        availableQuests = [musicProgrammingQuest, nlpQuizQuest, arPuzzleQuest]
        
        // Add some quests to recent for a good UI appearance
        recentQuests = []
        
        // Set a suggested quest based on user's learning style
        if let suggested = availableQuests.first(where: {
            quest in !Set(quest.learningStyles).isDisjoint(with: Set(userProfile.learningStyles)) && quest.destination != nil
        }) {
            var suggestedCopy = suggested
            suggestedCopy.isRecommended = true
            suggestedCopy.recommendationReason = "Coincide con tu estilo de aprendizaje \(userProfile.learningStyles.first ?? "")"
            suggestedQuest = suggestedCopy
        } else {
            suggestedQuest = musicProgrammingQuest
        }
    }
    
    func generateRecommendations() {
        // This is where Core ML integration would happen
        // Based on user behavior, learning styles, and progress
    }
    
    func calculateLevel() -> Int {
        // Simple level calculation based on XP
        return (userProfile.xpPoints / 500) + 1
    }
    
    func calculateLevelProgress() -> Double {
        let currentLevel = calculateLevel()
        let xpForCurrentLevel = (currentLevel - 1) * 500
        let xpForNextLevel = currentLevel * 500
        let xpInCurrentLevel = userProfile.xpPoints - xpForCurrentLevel
        let xpRequiredForNextLevel = xpForNextLevel - xpForCurrentLevel
        
        return Double(xpInCurrentLevel) / Double(xpRequiredForNextLevel)
    }
    
    func markQuestAsStarted(_ questTitle: String) {
        // Find the quest and update its completion percentage
        if let index = availableQuests.firstIndex(where: { $0.title == questTitle }) {
            var updatedQuest = availableQuests[index]
            // Only update if it's not completed yet
            if !updatedQuest.isCompleted && updatedQuest.completionPercentage < 0.1 {
                updatedQuest.completionPercentage = 0.1  // Started
                availableQuests[index] = updatedQuest
                
                // Add to recent if not already there
                if !recentQuests.contains(where: { $0.title == questTitle }) {
                    recentQuests.insert(updatedQuest, at: 0)
                    if recentQuests.count > 3 {
                        recentQuests.removeLast()
                    }
                }
            }
        }
    }
    
    func markQuestAsCompleted(_ questTitle: String) {
        // Update in available quests
        if let index = availableQuests.firstIndex(where: { $0.title == questTitle }) {
            var updatedQuest = availableQuests[index]
            updatedQuest.isCompleted = true
            updatedQuest.completionPercentage = 1.0
            availableQuests[index] = updatedQuest
            
            // Update in recent quests if present
            if let recentIndex = recentQuests.firstIndex(where: { $0.title == questTitle }) {
                var recentQuest = recentQuests[recentIndex]
                recentQuest.isCompleted = true
                recentQuest.completionPercentage = 1.0
                recentQuests[recentIndex] = recentQuest
            }
            
            // Save user data
            saveUserData()
        }
    }
    
    // Helper to check if a quest is completed
    func isQuestCompleted(_ questTitle: String) -> Bool {
        return availableQuests.first(where: { $0.title == questTitle })?.isCompleted ?? false
    }
    
    func addMotionMathChallenge() {
            // Check if the challenge already exists
            if availableQuests.contains(where: { $0.title == "Desafío Matemático con Movimiento" }) {
                return
            }
            
            let motionMathQuest = Quest(
                title: "Desafío Matemático con Movimiento",
                description: "Resuelve problemas matemáticos inclinando tu dispositivo en diferentes direcciones",
                xpReward: 180,
                duration: 15,
                difficulty: .intermediate,
                learningStyles: ["kinesthetic", "visual"],
                iconName: "function",
                isCompleted: false,
                completionPercentage: 0.0,
                destination: AnyView(MotionMathChallengeView()),
                isRecommended: true,
                recommendationReason: "Perfecto para tu estilo de aprendizaje kinestésico"
            )
            
            // Add to available quests
            availableQuests.append(motionMathQuest)
            
            // If user has kinesthetic or visual learning style, make it the suggested quest
            if (userProfile.learningStyles.contains("kinesthetic") || userProfile.learningStyles.contains("visual")),
               !isQuestCompleted("Desafío Matemático con Movimiento") {
                var suggestedCopy = motionMathQuest
                suggestedCopy.isRecommended = true
                
                // Set recommendation reason based on learning style
                if userProfile.learningStyles.contains("kinesthetic") {
                    suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje kinestésico"
                } else {
                    suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje visual"
                }
                
                suggestedQuest = suggestedCopy
            }
            
            // Save changes
            saveUserData()
        }
    
    func addVoiceCommandsChallengeQuest() {
            if availableQuests.contains(where: { $0.title == "Desafío de Comandos de Voz" }) {
                return
            }
            let voiceQuest = Quest(
                title: "Desafío de Comandos de Voz",
                description: "Resuelve desafíos de programación hablando comandos en español.",
                xpReward: 180,
                duration: 15,
                difficulty: .intermediate,
                learningStyles: ["auditory", "kinesthetic"],
                iconName: "waveform", // SF Symbol representing audio/waveform
                isCompleted: false,
                completionPercentage: 0.0,
                destination: AnyView(VoiceCommandsChallengeView())
            )
            availableQuests.append(voiceQuest)
            saveUserData()
        }
    
    // Add dictation lesson quest
    func addDictationLesson() {
        // Check if the lesson already exists
        if availableQuests.contains(where: { $0.title == "Dictado y Comprensión Auditiva" }) {
            return
        }
        
        // Create the dictation lesson quest
        let dictationQuest = Quest(
            title: "Dictado y Comprensión Auditiva",
            description: "Aprende a utilizar AVSpeechSynthesizer para la lectura de texto y mejora tu comprensión auditiva",
            xpReward: 150,
            duration: 20,
            difficulty: .intermediate,
            learningStyles: ["auditory", "reading"],
            iconName: "ear.and.waveform",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(DictationLessonView())
        )
        
        // Add to available quests
        availableQuests.append(dictationQuest)
        
        // If user has auditory learning style, make it the suggested quest
        if userProfile.learningStyles.contains("auditory") && suggestedQuest?.title != "Dictado y Comprensión Auditiva" {
            var suggestedCopy = dictationQuest
            suggestedCopy.isRecommended = true
            suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje auditivo"
            suggestedQuest = suggestedCopy
        }
        
        // Save changes
        saveUserData()
    }
    
    func addAnimatedTextAdventureQuest() {
            // Check if the quest is already added.
            if availableQuests.contains(where: { $0.title == "Aventura Textual Histórica" }) {
                return
            }
            let textAdventureQuest = Quest(
                title: "Aventura Textual Histórica",
                description: "Embárcate en una aventura interactiva y descubre secretos del antiguo Egipto mediante una historia animada.",
                xpReward: 150,
                duration: 20,
                difficulty: .beginner,
                learningStyles: ["reading", "visual"],
                iconName: "textformat.size", // Use a suitable SF Symbol
                isCompleted: false,
                completionPercentage: 0.0,
                destination: AnyView(AnimatedTextAdventureView())
            )
            availableQuests.append(textAdventureQuest)
            saveUserData()
        }
    
    // Add AR Object Recognition lesson quest
    func addARLessons() {
        // First, add the dictation lesson
        addDictationLesson()
        
        // If the AR lesson already exists, don't add it again
        if availableQuests.contains(where: { $0.title == "Reconocimiento de Objetos AR" }) {
            return
        }
        
        // Create the AR recognition lesson quest
        let arQuest = Quest(
            title: "Reconocimiento de Objetos AR",
            description: "Aprende a reconocer objetos en Realidad Aumentada y aplicar esta tecnología en situaciones prácticas",
            xpReward: 200,
            duration: 25,
            difficulty: .intermediate,
            learningStyles: ["visual", "kinesthetic"],
            iconName: "cube.transparent",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(ARObjectRecognitionLessonView())
        )
        
        // Add to available quests
        availableQuests.append(arQuest)
        
        // If user has visual or kinesthetic learning style, make it the suggested quest
        if userProfile.learningStyles.contains("visual") || userProfile.learningStyles.contains("kinesthetic"),
           suggestedQuest?.title != "Reconocimiento de Objetos AR" {
            var suggestedCopy = arQuest
            suggestedCopy.isRecommended = true
            
            // Set recommendation reason based on learning style
            if userProfile.learningStyles.contains("visual") {
                suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje visual"
            } else {
                suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje kinestésico"
            }
            
            suggestedQuest = suggestedCopy
        }
        
        // Save changes
        saveUserData()
    }
    func getCategorizedQuests() -> (programmingQuests: [Quest], mathQuests: [Quest], otherQuests: [Quest]) {
            var programmingQuests: [Quest] = []
            var mathQuests: [Quest] = []
            var otherQuests: [Quest] = []
            
            for quest in availableQuests {
                if quest.title.contains("Python") ||
                   quest.title.contains("Programación") ||
                   quest.title.contains("Quiz") ||
                   quest.title.contains("NLP") ||
                   quest.title.contains("Comandos de Voz") {
                    programmingQuests.append(quest)
                } else if quest.title.contains("Matemát") || quest.title.contains("Math") || quest.iconName == "function" {
                    mathQuests.append(quest)
                } else {
                    otherQuests.append(quest)
                }
            }
            return (programmingQuests, mathQuests, otherQuests)
        }
}

struct QuestCategoryView: View {
    let categoryTitle: String
    let categoryIcon: String
    let quests: [Quest]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(categoryTitle)
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(quests) { quest in
                    AvailableQuestRow(quest: quest)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
}

// Custom greeting based on time of day
func getGreeting() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    
    if hour < 12 {
        return "¡Buenos días"
    } else if hour < 18 {
        return "¡Buenas tardes"
    } else {
        return "¡Buenas noches"
    }
}

// Components for the dashboard
struct AvatarView: View {
    let name: String
    let avatarName: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar image
            Image(systemName: "person.circle.fill")  // Fallback to system icon if image not available
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getGreeting() + ",")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(name + "!")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ProgressStatsView: View {
    let xpPoints: Int
    let level: Int
    let levelProgress: Double
    let dailyGoal: Int
    let dailyProgress: Int
    let streak: Int
    
    var body: some View {
        VStack(spacing: 15) {
            // XP and level
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Nivel \(level)")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                    
                    Text("\(xpPoints) XP")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Streak counter
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(streak)")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.2))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            // Level progress bar
            HStack {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(width: max(4, UIScreen.main.bounds.width - 40) * CGFloat(levelProgress), height: 8)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            
            // Daily goal progress
            HStack {
                Text("Meta diaria:")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.white.opacity(0.2))
                        .frame(width: 150, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(.green)
                        .frame(width: max(0, min(150, 150 * CGFloat(dailyProgress) / CGFloat(max(1, dailyGoal)))), height: 8)
                        .cornerRadius(4)
                }
                
                Text("\(dailyProgress)/\(dailyGoal) XP")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
    }
}

struct ContinueLearningCard: View {
    let quest: Quest
    let screenWidth: CGFloat
    @ObservedObject private var userDataManager = UserDataManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(quest.isCompleted ? "Lección Completada" : "Continúa aprendiendo")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 22))
                }
            }
            
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    Circle()
                        .fill(quest.isCompleted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: quest.isCompleted ? "checkmark" : quest.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(quest.isCompleted ? .green : .blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(quest.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .foregroundColor(quest.isCompleted ? .green : .blue)
                                .frame(width: geo.size.width * CGFloat(quest.completionPercentage), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text("\(Int(quest.completionPercentage * 100))% completado")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if quest.isCompleted {
                            Text("Completado")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.green)
                        } else {
                            Text("\(quest.duration) min restantes")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            
            if let destination = quest.destination, !quest.isCompleted {
                NavigationLink(destination: destination) {
                    Text("Continuar")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    userDataManager.markQuestAsStarted(quest.title)
                })
            } else if !quest.isCompleted {
                Button(action: {
                    userDataManager.markQuestAsStarted(quest.title)
                }) {
                    Text("Continuar")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            } else {
                Button(action: {}) {
                    Text("Completado")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct SuggestedQuestCard: View {
    let quest: Quest
    let screenWidth: CGFloat
    @ObservedObject private var userDataManager = UserDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Misión recomendada para ti")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    Circle()
                        .fill(quest.difficulty.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: quest.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(quest.difficulty.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(quest.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                    
                    Text(quest.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack {
                        // XP Reward
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text("\(quest.xpReward) XP")
                                .font(.custom("Poppins-SemiBold", size: 12))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            Text("\(quest.duration) min")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Difficulty
                        Text(quest.difficulty.rawValue)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(quest.difficulty.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(quest.difficulty.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            if !quest.recommendationReason.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text(quest.recommendationReason)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            
            if let destination = quest.destination, !quest.isCompleted {
                NavigationLink(destination: destination) {
                    Text("Empezar")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(quest.difficulty.color)
                        .cornerRadius(25)
                        .shadow(color: quest.difficulty.color.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    userDataManager.markQuestAsStarted(quest.title)
                })
            } else if quest.isCompleted {
                Button(action: {}) {
                    Text("Completado")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(25)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(true)
            } else {
                Button(action: {
                    // Action to start this quest
                    userDataManager.markQuestAsStarted(quest.title)
                }) {
                    Text("Empezar")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(quest.difficulty.color)
                        .cornerRadius(25)
                        .shadow(color: quest.difficulty.color.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct RecentTopicsView: View {
    let topics: [Quest]
    @ObservedObject private var userDataManager = UserDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Temas recientes")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(topics) { topic in
                                    RecentTopicCard(topic: topic)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            struct RecentTopicCard: View {
                let topic: Quest
                @ObservedObject private var userDataManager = UserDataManager.shared
                
                var body: some View {
                    VStack(alignment: .leading, spacing: 12) {
                        // Topic icon and completion indicator
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(topic.isCompleted ? Color.green.opacity(0.1) : topic.difficulty.color.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: topic.isCompleted ? "checkmark" : topic.iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(topic.isCompleted ? .green : topic.difficulty.color)
                            }
                            
                            Spacer()
                            
                            if topic.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("\(Int(topic.completionPercentage * 100))%")
                                    .font(.custom("Poppins-SemiBold", size: 14))
                                    .foregroundColor(topic.difficulty.color)
                            }
                        }
                        
                        Spacer()
                        
                        Text(topic.title)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Progress bar for incomplete topics
                        if !topic.isCompleted {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .foregroundColor(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .foregroundColor(topic.difficulty.color)
                                        .frame(width: geo.size.width * CGFloat(topic.completionPercentage), height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .frame(height: 4)
                        }
                        
                        if let destination = topic.destination, !topic.isCompleted {
                            NavigationLink(destination: destination) {
                                Text("Continuar")
                                    .font(.custom("Poppins-SemiBold", size: 12))
                                    .foregroundColor(topic.difficulty.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(topic.difficulty.color.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .simultaneousGesture(TapGesture().onEnded {
                                userDataManager.markQuestAsStarted(topic.title)
                            })
                        } else if topic.isCompleted {
                            Text("Completado")
                                .font(.custom("Poppins-SemiBold", size: 12))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            Button(action: {
                                userDataManager.markQuestAsStarted(topic.title)
                            }) {
                                Text("Continuar")
                                    .font(.custom("Poppins-SemiBold", size: 12))
                                    .foregroundColor(topic.difficulty.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(topic.difficulty.color.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .frame(width: 150, height: 180)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }

            struct AvailableQuestRow: View {
                let quest: Quest
                @ObservedObject private var userDataManager = UserDataManager.shared
                
                var body: some View {
                    HStack(spacing: 15) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(quest.isCompleted ? Color.green.opacity(0.1) : quest.difficulty.color.opacity(0.1))
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: quest.isCompleted ? "checkmark" : quest.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(quest.isCompleted ? .green : quest.difficulty.color)
                        }
                        
                        // Title and description
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.title)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.black)
                            
                            if quest.isCompleted {
                                Text("Completado • \(quest.xpReward) XP ganados")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.green)
                            } else {
                                Text("\(quest.duration) min • \(quest.xpReward) XP")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Navigation to quest
                        if let destination = quest.destination, !quest.isCompleted {
                            NavigationLink(destination: destination) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(quest.difficulty.color)
                                    .padding(8)
                                    .background(quest.difficulty.color.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                userDataManager.markQuestAsStarted(quest.title)
                            })
                        } else if quest.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(8)
                        } else {
                            Button(action: {
                                userDataManager.markQuestAsStarted(quest.title)
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(quest.difficulty.color)
                                    .padding(8)
                                    .background(quest.difficulty.color.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                }
            }

struct HomeView: View {
    @StateObject private var userDataManager = UserDataManager.shared
    @State private var refreshTrigger = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Header section with gradient background
                    VStack(spacing: 20) {
                        // Avatar and greeting
                        AvatarView(
                            name: userDataManager.userProfile.name,
                            avatarName: userDataManager.userProfile.avatarName
                        )
                        .padding(.top, 20)
                        
                        // Progress stats
                        ProgressStatsView(
                            xpPoints: userDataManager.userProfile.xpPoints,
                            level: userDataManager.calculateLevel(),
                            levelProgress: userDataManager.calculateLevelProgress(),
                            dailyGoal: userDataManager.userProfile.dailyGoal,
                            dailyProgress: userDataManager.userProfile.dailyProgress,
                            streak: userDataManager.userProfile.streak
                        )
                        .padding(.bottom, 25)
                    }
                    .frame(width: geometry.size.width)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(30)
                    
                    // Main content
                    VStack(spacing: 20) {
                        // Continue learning card - show if has recent quests
                        if !userDataManager.recentQuests.isEmpty {
                            ContinueLearningCard(quest: userDataManager.recentQuests[0], screenWidth: geometry.size.width)
                                .padding(.horizontal)
                        }
                        
                        // AI-suggested quest
                        if let suggestedQuest = userDataManager.suggestedQuest {
                            SuggestedQuestCard(quest: suggestedQuest, screenWidth: geometry.size.width)
                                .padding(.horizontal)
                        }
                        
                        // Recent topics
                        if !userDataManager.recentQuests.isEmpty {
                            RecentTopicsView(topics: userDataManager.recentQuests)
                        }
                        
                        // Divider with title
                        HStack {
                            Text("Explora por categoría")
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Get categorized quests
                        let categorizedQuests = userDataManager.getCategorizedQuests()
                        
                        // Programming section
                        if !categorizedQuests.programmingQuests.isEmpty {
                            QuestCategoryView(
                                categoryTitle: "Programación",
                                categoryIcon: "laptopcomputer",
                                quests: categorizedQuests.programmingQuests,
                                color: .blue
                            )
                        }
                        
                        // Math section
                        if !categorizedQuests.mathQuests.isEmpty {
                            QuestCategoryView(
                                categoryTitle: "Matemáticas",
                                categoryIcon: "function",
                                quests: categorizedQuests.mathQuests,
                                color: .purple
                            )
                        }
                        
                        // Other quests section
                        if !categorizedQuests.otherQuests.isEmpty {
                            QuestCategoryView(
                                categoryTitle: "Otros Temas",
                                categoryIcon: "square.stack.3d.up",
                                quests: categorizedQuests.otherQuests,
                                color: .orange
                            )
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .frame(width: geometry.size.width)
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                // Refresh view when appearing
                refreshTrigger.toggle()
                
                // Add all lessons to the available quests
                userDataManager.addARLessons() // This also calls addDictationLesson() internally
                userDataManager.addMotionMathChallenge() // Add the new math challenge
                userDataManager.addAnimatedTextAdventureQuest()
                userDataManager.addVoiceCommandsChallengeQuest()  // NEW: add voice challenge quest
            }
        }
    }
}

// Helper extension for HomeView
extension HomeView {
    func addAllLessons() {
        userDataManager.addARLessons() // This calls addDictationLesson() internally
        userDataManager.addMotionMathChallenge() // Add motion math challenge
    }
}

            struct HomeView_Previews: PreviewProvider {
                static var previews: some View {
                    HomeView()
                }
            }
