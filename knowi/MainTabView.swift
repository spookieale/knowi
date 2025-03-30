import SwiftUI

// Main tab view to include our new Learning Tree screen and Profile View
struct MainTabView: View {
    @StateObject private var userDataManager = UserDataManager.shared
    @StateObject private var learningAnalyzer = LearningStyleAnalyzer.shared
    
    var body: some View {
        TabView {
            // Home tab
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
            
            // Learning Tree tab - use your existing LearningStyleTreeView
            LearningStyleTreeView()
                .tabItem {
                    Label("Árbol de Aprendizaje", systemImage: "chart.bar.fill")
                }
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Initialize ML recommendation system data if needed
            initializeMLData()
        }
    }
    
    private func initializeMLData() {
        // Initialize sample learning data if there's none
        // In a real app, this would come from actual usage
        if learningAnalyzer.stylePerformances.isEmpty {
            learningAnalyzer.loadPerformanceData()
        }
        
        // For testing: Generate sample data if we have no performance history
        #if DEBUG
        if learningAnalyzer.performanceHistory.isEmpty {
            generateTestData()
        }
        #endif
    }
    
    // Generate test data for development and testing purposes
    private func generateTestData() {
        // Only generate test data in debug mode
        let styles = ["visual", "auditory", "reading", "kinesthetic"]
        let questTitles = [
            "Música y Programación",
            "Quiz de Programación",
            "Rompecabezas AR"
        ]
        
        // Generate some sample history data
        for _ in 1...10 {
            let randomStyle = styles.randomElement()!
            let randomQuest = questTitles.randomElement()!
            let randomScore = Double.random(in: 60...95)
            let randomTime = TimeInterval(Double.random(in: 10...30) * 60)
            
            // Add data to analyzer
            learningAnalyzer.recordQuestCompletionWithHistory(
                styleId: randomStyle,
                score: randomScore,
                timeSpent: randomTime,
                questTitle: randomQuest
            )
        }
        
        // Create a slight bias toward one learning style to demonstrate recommendations
        let primaryStyle = styles.randomElement()!
        for _ in 1...5 {
            let randomQuest = questTitles.randomElement()!
            // Higher scores for this style
            let score = Double.random(in: 80...95)
            let time = TimeInterval(Double.random(in: 5...15) * 60) // Better efficiency
            
            learningAnalyzer.recordQuestCompletionWithHistory(
                styleId: primaryStyle,
                score: score,
                timeSpent: time,
                questTitle: randomQuest
            )
        }
        
        // Update recommendation
        learningAnalyzer.updateRecommendation()
    }
}

// ML data collection extension for quests
class QuestMLDataCollector {
    static let shared = QuestMLDataCollector()
    
    // Start tracking a quest session
    private var sessionStartTimes: [String: Date] = [:]
    private var questSessionData: [String: [String: Any]] = [:]
    
    // Call this when user starts a quest
    func startQuestSession(questTitle: String) {
        sessionStartTimes[questTitle] = Date()
        questSessionData[questTitle] = [
            "interactionCount": 0,
            "correctAnswers": 0,
            "incorrectAnswers": 0,
            "hints": 0
        ]
    }
    
    // Call this during a quest to track interactions
    func recordInteraction(questTitle: String, type: String, value: Any = true) {
        guard var data = questSessionData[questTitle] else {
            return
        }
        
        switch type {
        case "interaction":
            if let count = data["interactionCount"] as? Int {
                data["interactionCount"] = count + 1
            }
        case "correct":
            if let count = data["correctAnswers"] as? Int {
                data["correctAnswers"] = count + 1
            }
        case "incorrect":
            if let count = data["incorrectAnswers"] as? Int {
                data["incorrectAnswers"] = count + 1
            }
        case "hint":
            if let count = data["hints"] as? Int {
                data["hints"] = count + 1
            }
        default:
            // Store custom data
            data[type] = value
        }
        
        questSessionData[questTitle] = data
    }
    
    // Call this when quest completes
    func completeQuestSession(questTitle: String, completion: @escaping (Double, TimeInterval) -> Void) {
        // Calculate time spent
        guard let startTime = sessionStartTimes[questTitle],
              let data = questSessionData[questTitle] else {
            completion(0.0, 0.0)
            return
        }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        
        // Calculate score based on correct/incorrect answers and hints used
        var score = 0.0
        let correctAnswers = data["correctAnswers"] as? Int ?? 0
        let incorrectAnswers = data["incorrectAnswers"] as? Int ?? 0
        let hintsUsed = data["hints"] as? Int ?? 0
        
        if correctAnswers + incorrectAnswers > 0 {
            // Base score calculation
            let baseScore = Double(correctAnswers) / Double(correctAnswers + incorrectAnswers) * 100.0
            
            // Apply penalty for hints (each hint reduces score by 5%, up to 25%)
            let hintPenalty = min(25.0, Double(hintsUsed) * 5.0)
            score = max(0.0, baseScore - hintPenalty)
        } else {
            // If no answers tracked, base score on completion time relative to expected duration
            if let quest = UserDataManager.shared.availableQuests.first(where: { $0.title == questTitle }) {
                let expectedTime = Double(quest.duration * 60) // Expected duration in seconds
                let timeEfficiency = min(1.5, expectedTime / max(1.0, timeSpent)) // Cap at 150%
                score = timeEfficiency * 80.0 // Base completion is worth 80%, can go up to 120%
            } else {
                score = 70.0 // Default score if we can't find the quest
            }
        }
        
        // Clean up tracking data
        sessionStartTimes.removeValue(forKey: questTitle)
        questSessionData.removeValue(forKey: questTitle)
        
        // Return the calculated score and time spent
        completion(score, timeSpent)
    }
}

// Add a helper protocol for quest views to record ML data
protocol LearningStyleAware {
    var quest: Quest { get }
    var mlDataCollector: QuestMLDataCollector { get }
    
    func startTracking()
    func completeTracking(manualScore: Double?)
    func recordInteraction(type: String, value: Any)
}

// Default implementation
extension LearningStyleAware {
    var mlDataCollector: QuestMLDataCollector {
        return QuestMLDataCollector.shared
    }
    
    func startTracking() {
        mlDataCollector.startQuestSession(questTitle: quest.title)
    }
    
    func completeTracking(manualScore: Double? = nil) {
        mlDataCollector.completeQuestSession(questTitle: quest.title) { score, timeSpent in
            // Use manual score if provided
            let finalScore = manualScore ?? score
            
            // Record in UserDataManager
            UserDataManager.shared.recordQuestCompletion(
                questTitle: quest.title,
                score: finalScore,
                timeSpent: timeSpent
            )
        }
    }
    
    func recordInteraction(type: String, value: Any = true) {
        mlDataCollector.recordInteraction(questTitle: quest.title, type: type, value: value)
    }
}
