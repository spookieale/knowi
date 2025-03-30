//
//  LearningStyleTree.swift
//  knowi
//
//  Created by Alumno on 30/03/25.
//

import SwiftUI
import CoreML

// Learning style performance metrics
struct StylePerformance: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    var completedQuests: Int
    var averageScore: Double
    var totalTimeSpent: TimeInterval
    var skillLevel: Int
    
    // Skills that can be unlocked within this learning style
    var unlockedSkills: [String]
    var lockedSkills: [String]
    
    var progressPercentage: Double {
        if unlockedSkills.isEmpty && lockedSkills.isEmpty {
            return 0.0
        }
        return Double(unlockedSkills.count) / Double(unlockedSkills.count + lockedSkills.count)
    }
    
    // Initialize with default values
    init(id: String, name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.completedQuests = 0
        self.averageScore = 0.0
        self.totalTimeSpent = 0.0
        self.skillLevel = 1
        self.unlockedSkills = []
        self.lockedSkills = [
            "Principiante",
            "Intermedio",
            "Avanzado",
            "Experto",
            "Maestro"
        ]
    }
    
    // Sample for previews
    static func sample(for styleId: String) -> StylePerformance {
        let styles = [
            "visual": StylePerformance(id: "visual", name: "Visual", icon: "eye.fill"),
            "auditory": StylePerformance(id: "auditory", name: "Auditivo", icon: "speaker.wave.2.fill"),
            "reading": StylePerformance(id: "reading", name: "Lectura", icon: "book.fill"),
            "kinesthetic": StylePerformance(id: "kinesthetic", name: "Kinestésico", icon: "hand.tap.fill")
        ]
        
        guard var performance = styles[styleId] else {
            return StylePerformance(id: "visual", name: "Visual", icon: "eye.fill")
        }
        
        // Add some sample data
        performance.completedQuests = Int.random(in: 0...12)
        performance.averageScore = Double.random(in: 50...95)
        performance.totalTimeSpent = TimeInterval(Int.random(in: 10...120) * 60)
        performance.skillLevel = Int.random(in: 1...5)
        
        // Add some unlocked skills based on level
        if performance.skillLevel >= 1 {
            performance.unlockedSkills.append("Principiante")
            performance.lockedSkills.removeAll { $0 == "Principiante" }
        }
        if performance.skillLevel >= 2 {
            performance.unlockedSkills.append("Intermedio")
            performance.lockedSkills.removeAll { $0 == "Intermedio" }
        }
        if performance.skillLevel >= 3 {
            performance.unlockedSkills.append("Avanzado")
            performance.lockedSkills.removeAll { $0 == "Avanzado" }
        }
        if performance.skillLevel >= 4 {
            performance.unlockedSkills.append("Experto")
            performance.lockedSkills.removeAll { $0 == "Experto" }
        }
        if performance.skillLevel >= 5 {
            performance.unlockedSkills.append("Maestro")
            performance.lockedSkills.removeAll { $0 == "Maestro" }
        }
        
        return performance
    }
}

// Data structure for historical learning performance
struct HistoricalPerformance: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let styleId: String
    let score: Double
    let questTitle: String
    
    // For chart display
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// ML learning system for style recommendations
class LearningStyleAnalyzer: ObservableObject {
    static let shared = LearningStyleAnalyzer()
    
    @Published var stylePerformances: [StylePerformance] = []
    @Published var recommendedStyle: String = ""
    @Published var recommendationConfidence: Double = 0.0
    @Published var recentCompletions: [(styleId: String, score: Double, timeSpent: TimeInterval)] = []
    @Published var performanceHistory: [HistoricalPerformance] = []
    
    // Prediction model (to be replaced with actual CoreML implementation)
    private var model: MLModel? = nil
    
    init() {
        loadPerformanceData()
        loadHistoricalData()
        setupModel()
    }
    
    private func setupModel() {
        // TODO: Load actual ML model
        // In a real implementation, you would load the CoreML model here
        // For now, we'll use a simple heuristic approach
    }
    
    func loadPerformanceData() {
        if let data = UserDefaults.standard.data(forKey: "stylePerformances") {
            if let decoded = try? JSONDecoder().decode([StylePerformance].self, from: data) {
                self.stylePerformances = decoded
                return
            }
        }
        
        // Initialize with default learning styles if no saved data
        self.stylePerformances = [
            StylePerformance(id: "visual", name: "Visual", icon: "eye.fill"),
            StylePerformance(id: "auditory", name: "Auditivo", icon: "speaker.wave.2.fill"),
            StylePerformance(id: "reading", name: "Lectura", icon: "book.fill"),
            StylePerformance(id: "kinesthetic", name: "Kinestésico", icon: "hand.tap.fill")
        ]
        
        savePerformanceData()
    }
    
    func savePerformanceData() {
        if let encoded = try? JSONEncoder().encode(stylePerformances) {
            UserDefaults.standard.set(encoded, forKey: "stylePerformances")
        }
    }
    
    // Record a completed quest with its learning style and performance metrics
    func recordQuestCompletion(styleId: String, score: Double, timeSpent: TimeInterval) {
        recentCompletions.append((styleId: styleId, score: score, timeSpent: timeSpent))
        
        // Update the performance metrics for this style
        if let index = stylePerformances.firstIndex(where: { $0.id == styleId }) {
            stylePerformances[index].completedQuests += 1
            
            // Update average score (weighted)
            let currentTotal = stylePerformances[index].averageScore * Double(stylePerformances[index].completedQuests - 1)
            let newAverage = (currentTotal + score) / Double(stylePerformances[index].completedQuests)
            stylePerformances[index].averageScore = newAverage
            
            // Update total time spent
            stylePerformances[index].totalTimeSpent += timeSpent
            
            // Check if we should level up this skill
            updateSkillLevel(for: styleId)
            
            savePerformanceData()
            updateRecommendation()
        }
    }
    
    // Update skill level based on quest completions and scores
    private func updateSkillLevel(for styleId: String) {
        guard let index = stylePerformances.firstIndex(where: { $0.id == styleId }) else {
            return
        }
        
        let performance = stylePerformances[index]
        let completedQuests = performance.completedQuests
        let averageScore = performance.averageScore
        
        // Simple level calculation based on completed quests and average score
        var newLevel = 1
        
        if completedQuests >= 3 && averageScore >= 50 {
            newLevel = 2
        }
        if completedQuests >= 7 && averageScore >= 65 {
            newLevel = 3
        }
        if completedQuests >= 12 && averageScore >= 75 {
            newLevel = 4
        }
        if completedQuests >= 20 && averageScore >= 85 {
            newLevel = 5
        }
        
        // Only update if level has changed
        if newLevel != performance.skillLevel {
            stylePerformances[index].skillLevel = newLevel
            
            // Update unlocked skills based on new level
            updateUnlockedSkills(for: styleId, newLevel: newLevel)
        }
    }
    
    // Update the skills that are unlocked for this learning style
    private func updateUnlockedSkills(for styleId: String, newLevel: Int) {
        guard let index = stylePerformances.firstIndex(where: { $0.id == styleId }) else {
            return
        }
        
        var unlocked = [String]()
        var locked = ["Principiante", "Intermedio", "Avanzado", "Experto", "Maestro"]
        
        if newLevel >= 1 {
            unlocked.append("Principiante")
            locked.removeAll { $0 == "Principiante" }
        }
        if newLevel >= 2 {
            unlocked.append("Intermedio")
            locked.removeAll { $0 == "Intermedio" }
        }
        if newLevel >= 3 {
            unlocked.append("Avanzado")
            locked.removeAll { $0 == "Avanzado" }
        }
        if newLevel >= 4 {
            unlocked.append("Experto")
            locked.removeAll { $0 == "Experto" }
        }
        if newLevel >= 5 {
            unlocked.append("Maestro")
            locked.removeAll { $0 == "Maestro" }
        }
        
        stylePerformances[index].unlockedSkills = unlocked
        stylePerformances[index].lockedSkills = locked
    }
    
    // Update the recommended learning style based on performance metrics
    func updateRecommendation() {
        // In a real app, this would use the ML model prediction
        // For now, we'll use a simple heuristic based on progress and scores
        
        // Find the style with the best performance metrics
        var bestStyle = ""
        var bestScore = 0.0
        
        for performance in stylePerformances {
            // Skip styles with very little data
            if performance.completedQuests < 2 {
                continue
            }
            
            // Calculate a combined score based on multiple metrics
            let completionWeight = 0.3
            let scoreWeight = 0.5
            let efficiencyWeight = 0.2
            
            let completionScore = min(1.0, Double(performance.completedQuests) / 10.0)
            let performanceScore = performance.averageScore / 100.0
            
            // Efficiency is based on average time per quest (shorter is better)
            let avgTimePerQuest = performance.totalTimeSpent / Double(max(1, performance.completedQuests))
            let efficiencyScore = 1.0 - min(1.0, avgTimePerQuest / (30 * 60)) // Normalize to 30 minutes
            
            let combinedScore = (completionScore * completionWeight) +
                                (performanceScore * scoreWeight) +
                                (efficiencyScore * efficiencyWeight)
            
            if combinedScore > bestScore {
                bestScore = combinedScore
                bestStyle = performance.id
            }
        }
        
        if !bestStyle.isEmpty {
            recommendedStyle = bestStyle
            recommendationConfidence = bestScore
        } else if let firstStyle = stylePerformances.first {
            // Default to first style if we don't have enough data
            recommendedStyle = firstStyle.id
            recommendationConfidence = 0.5
        }
    }
    
    // Get performance for a specific learning style
    func getPerformance(for styleId: String) -> StylePerformance? {
        return stylePerformances.first { $0.id == styleId }
    }
    
    // Get the next quest recommendation based on learning style
    func getNextQuestRecommendation(from availableQuests: [Quest]) -> Quest? {
        guard !recommendedStyle.isEmpty else {
            return availableQuests.first
        }
        
        // Look for quests that match the recommended learning style
        let matchingQuests = availableQuests.filter {
            quest in !quest.isCompleted && quest.learningStyles.contains(recommendedStyle)
        }
        
        return matchingQuests.first
    }
    
    // Generate insights about the user's learning style preferences
    func generateInsights() -> [String] {
        var insights = [String]()
        
        // Add insights based on completed quests and performance
        if let bestPerformance = stylePerformances.max(by: { $0.averageScore < $1.averageScore }) {
            if bestPerformance.completedQuests >= 3 {
                insights.append("Tienes un rendimiento excepcional con el estilo de aprendizaje \(bestPerformance.name).")
            }
        }
        
        if let fastestStyle = stylePerformances.filter({ $0.completedQuests >= 3 }).min(by: {
            $0.totalTimeSpent / Double($0.completedQuests) < $1.totalTimeSpent / Double($1.completedQuests)
        }) {
            insights.append("Aprendes más rápido con el estilo \(fastestStyle.name).")
        }
        
        // Add insights about styles that need more exploration
        let unexploredStyles = stylePerformances.filter { $0.completedQuests < 2 }
        if !unexploredStyles.isEmpty {
            let styleNames = unexploredStyles.map { $0.name }.joined(separator: ", ")
            insights.append("Podrías explorar más los estilos de aprendizaje: \(styleNames).")
        }
        
        // Add insight about the dominant learning style
        if !recommendedStyle.isEmpty, let style = getPerformance(for: recommendedStyle) {
            insights.append("Tu estilo de aprendizaje dominante parece ser \(style.name).")
        }
        
        return insights
    }
    
    // Load historical performance data
    func loadHistoricalData() {
        if let data = UserDefaults.standard.data(forKey: "stylePerformanceHistory") {
            if let decoded = try? JSONDecoder().decode([HistoricalPerformance].self, from: data) {
                // Sort by date
                self.performanceHistory = decoded.sorted(by: { $0.date < $1.date })
                return
            }
        }
        
        // Initialize with empty array if no saved data
        self.performanceHistory = []
    }
    
    // Save historical performance data
    func saveHistoricalData() {
        if let encoded = try? JSONEncoder().encode(performanceHistory) {
            UserDefaults.standard.set(encoded, forKey: "stylePerformanceHistory")
        }
    }
    
    // Add a new data point to history
    func addHistoricalDataPoint(styleId: String, score: Double, questTitle: String) {
        let newPoint = HistoricalPerformance(
            date: Date(),
            styleId: styleId,
            score: score,
            questTitle: questTitle
        )
        
        performanceHistory.append(newPoint)
        saveHistoricalData()
    }
    
    // Get performance history for a specific style
    func getHistoryForStyle(styleId: String) -> [HistoricalPerformance] {
        return performanceHistory.filter { $0.styleId == styleId }
    }
    
    // Record quest completion with history tracking
    func recordQuestCompletionWithHistory(styleId: String, score: Double, timeSpent: TimeInterval, questTitle: String) {
        // Record for performance metrics
        recordQuestCompletion(styleId: styleId, score: score, timeSpent: timeSpent)
        
        // Add to history
        addHistoricalDataPoint(styleId: styleId, score: score, questTitle: questTitle)
    }
    
    // Simplified API for quest views to record completion
    func recordQuestCompleted(quest: Quest, score: Double, timeSpent: TimeInterval) {
        // Record for each learning style this quest covers
        for styleId in quest.learningStyles {
            recordQuestCompletion(
                styleId: styleId,
                score: score,
                timeSpent: timeSpent
            )
        }
        
        // Update recommendations based on new data
        updateRecommendation()
    }
}

// Node in the skill tree
struct SkillNode: Identifiable {
    let id = UUID()
    let name: String
    let level: Int
    var isUnlocked: Bool
    let color: Color
    let position: CGPoint
    
    static let levelColors: [Color] = [
        .green,
        .blue,
        .purple,
        .orange,
        .red
    ]
}

// Connector between nodes in the skill tree
struct SkillConnector: Identifiable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
    let isUnlocked: Bool
}

// Visualizing the tree structure
struct SkillTreeView: View {
    let styleId: String
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    
    @State private var nodes: [SkillNode] = []
    @State private var connectors: [SkillConnector] = []
    
    private func setupNodes() {
        guard let performance = analyzer.getPerformance(for: styleId) else {
            return
        }
        
        // Create nodes for unlocked and locked skills
        var newNodes: [SkillNode] = []
        var newConnectors: [SkillConnector] = []
        
        // Center node is the learning style itself
        let centerPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 150)
        
        // Add nodes in a tree-like structure
        let skillLevels = ["Principiante", "Intermedio", "Avanzado", "Experto", "Maestro"]
        let radius: CGFloat = 120
        
        for (index, skillName) in skillLevels.enumerated() {
            let level = index + 1
            let isUnlocked = performance.unlockedSkills.contains(skillName)
            let angle = CGFloat(index) * (CGFloat.pi * 2 / CGFloat(skillLevels.count)) - CGFloat.pi / 2
            
            let xOffset = cos(angle) * radius
            let yOffset = sin(angle) * radius
            let position = CGPoint(x: centerPosition.x + xOffset, y: centerPosition.y + yOffset + 100)
            
            let node = SkillNode(
                name: skillName,
                level: level,
                isUnlocked: isUnlocked,
                color: SkillNode.levelColors[index % SkillNode.levelColors.count],
                position: position
            )
            
            newNodes.append(node)
            
            // Connect to center
            newConnectors.append(
                SkillConnector(
                    from: centerPosition,
                    to: position,
                    isUnlocked: isUnlocked
                )
            )
            
            // Connect to previous node in a circle
            if index > 0 {
                let prevAngle = CGFloat(index - 1) * (CGFloat.pi * 2 / CGFloat(skillLevels.count)) - CGFloat.pi / 2
                let prevXOffset = cos(prevAngle) * radius
                let prevYOffset = sin(prevAngle) * radius
                let prevPosition = CGPoint(x: centerPosition.x + prevXOffset, y: centerPosition.y + prevYOffset + 100)
                
                newConnectors.append(
                    SkillConnector(
                        from: prevPosition,
                        to: position,
                        isUnlocked: isUnlocked && newNodes[index - 1].isUnlocked
                    )
                )
            }
            
            // Connect first and last in the circle
            if index == skillLevels.count - 1 {
                let firstAngle = CGFloat(0) * (CGFloat.pi * 2 / CGFloat(skillLevels.count)) - CGFloat.pi / 2
                let firstXOffset = cos(firstAngle) * radius
                let firstYOffset = sin(firstAngle) * radius
                let firstPosition = CGPoint(x: centerPosition.x + firstXOffset, y: centerPosition.y + firstYOffset + 100)
                
                newConnectors.append(
                    SkillConnector(
                        from: position,
                        to: firstPosition,
                        isUnlocked: isUnlocked && newNodes[0].isUnlocked
                    )
                )
            }
        }
        
        // Add center node for the learning style itself
        newNodes.append(SkillNode(
            name: performance.name,
            level: 0,
            isUnlocked: true,
            color: .blue,
            position: centerPosition
        ))
        
        nodes = newNodes
        connectors = newConnectors
    }
    
    var body: some View {
        ZStack {
            // Draw connectors
            ForEach(connectors) { connector in
                Path { path in
                    path.move(to: connector.from)
                    path.addLine(to: connector.to)
                }
                .stroke(
                    connector.isUnlocked ? Color.blue : Color.gray,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: connector.isUnlocked ? [] : [5, 5])
                )
            }
            
            // Draw nodes
            ForEach(nodes) { node in
                VStack(spacing: 5) {
                    if node.level == 0 {
                        // Center node (learning style)
                        Image(systemName: analyzer.getPerformance(for: styleId)?.icon ?? "questionmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    } else {
                        // Skill level nodes
                        Text("\(node.level)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: node.level == 0 ? 70 : 50, height: node.level == 0 ? 70 : 50)
                .background(node.isUnlocked ? node.color : Color.gray.opacity(0.5))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: node.isUnlocked ? node.color.opacity(0.7) : Color.gray.opacity(0.3), radius: 5, x: 0, y: 3)
                .position(node.position)
                .overlay(
                    Text(node.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(node.isUnlocked ? .black : .gray)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                        .padding(4)
                        .offset(y: 30)
                        .position(node.position)
                )
            }
        }
        .frame(height: 400)
        .onAppear {
            setupNodes()
        }
    }
}

// Performance detail card
struct StylePerformanceCard: View {
    let performance: StylePerformance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: performance.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(performance.name)
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("Nivel \(performance.skillLevel)")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SkillNode.levelColors[min(4, performance.skillLevel - 1)])
                    .cornerRadius(20)
            }
            
            Divider()
            
            // Performance metrics
            VStack(spacing: 12) {
                HStack {
                    Label {
                        Text("Misiones completadas")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Text("\(performance.completedQuests)")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                }
                
                HStack {
                    Label {
                        Text("Puntuación promedio")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", performance.averageScore))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                }
                
                HStack {
                    Label {
                        Text("Tiempo total")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(timeString(from: performance.totalTimeSpent))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
            
            // Skills unlocked
            VStack(alignment: .leading, spacing: 8) {
                Text("Habilidades desbloqueadas")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                
                if performance.unlockedSkills.isEmpty {
                    Text("Completa misiones para desbloquear habilidades")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    HStack {
                        ForEach(performance.unlockedSkills, id: \.self) { skill in
                            Text(skill)
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // Format time interval to human-readable string
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutos"
        }
    }
}

// Main learning style tree view
struct LearningStyleTreeView: View {
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    @ObservedObject var userDataManager = UserDataManager.shared
    @State private var selectedStyleId: String = ""
    @State private var showingInsights = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("Árbol de Estilos de Aprendizaje")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    Text("Explora tu progreso y descubre qué estilo se adapta mejor a ti")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Recommended style card
                                if !analyzer.recommendedStyle.isEmpty, let style = analyzer.getPerformance(for: analyzer.recommendedStyle) {
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            Text("Estilo recomendado para ti")
                                                .font(.custom("Poppins-SemiBold", size: 18))
                                                .foregroundColor(.black)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                showingInsights = true
                                            }) {
                                                Image(systemName: "info.circle")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        HStack(spacing: 15) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.1))
                                                    .frame(width: 60, height: 60)
                                                
                                                Image(systemName: style.icon)
                                                    .font(.system(size: 26))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(style.name)
                                                    .font(.custom("Poppins-SemiBold", size: 18))
                                                    .foregroundColor(.black)
                                                
                                                Text("Confianza: \(Int(analyzer.recommendationConfidence * 100))%")
                                                    .font(.custom("Poppins-Regular", size: 14))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                selectedStyleId = style.id
                                            }) {
                                                Text("Ver detalles")
                                                    .font(.custom("Poppins-SemiBold", size: 14))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 15)
                                                    .padding(.vertical, 8)
                                                    .background(Color.blue)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal)
                                }
                                
                                // Style selector tabs
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(analyzer.stylePerformances) { style in
                                            Button(action: {
                                                selectedStyleId = style.id
                                            }) {
                                                HStack {
                                                    Image(systemName: style.icon)
                                                        .foregroundColor(selectedStyleId == style.id ? .white : .blue)
                                                    
                                                    Text(style.name)
                                                        .font(.custom("Poppins-SemiBold", size: 14))
                                                        .foregroundColor(selectedStyleId == style.id ? .white : .blue)
                                                }
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedStyleId == style.id
                                                        ? Color.blue
                                                        : Color.blue.opacity(0.1)
                                                )
                                                .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Selected style tree and details
                                if !selectedStyleId.isEmpty, let performance = analyzer.getPerformance(for: selectedStyleId) {
                                    VStack(spacing: 20) {
                                        // Skill tree visualization
                                        SkillTreeView(styleId: selectedStyleId)
                                            .frame(height: 400)
                                            .padding(.horizontal)
                                        
                                        // Performance details
                                        StylePerformanceCard(performance: performance)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    // Default view - show all styles
                                    Text("Selecciona un estilo para ver su árbol de habilidades")
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.gray)
                                        .frame(height: 300)
                                        .frame(maxWidth: .infinity)
                                }
                                
                                // Available quests based on selected style
                                if !selectedStyleId.isEmpty {
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Misiones recomendadas para este estilo")
                                            .font(.custom("Poppins-SemiBold", size: 18))
                                            .foregroundColor(.black)
                                            .padding(.horizontal)
                                        
                                        let filteredQuests = userDataManager.availableQuests.filter {
                                            quest in !quest.isCompleted && quest.learningStyles.contains(selectedStyleId)
                                        }
                                        
                                        if filteredQuests.isEmpty {
                                            Text("No hay misiones disponibles para este estilo de aprendizaje en este momento.")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(.gray)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        } else {
                                            VStack(spacing: 10) {
                                                ForEach(filteredQuests) { quest in
                                                    AvailableQuestRow(quest: quest)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical)
                                }
                                
                                // Insights section
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Análisis de aprendizaje")
                                        .font(.custom("Poppins-SemiBold", size: 18))
                                        .foregroundColor(.black)
                                    
                                    let insights = analyzer.generateInsights()
                                    
                                    if insights.isEmpty {
                                        Text("Completa más misiones para recibir análisis personalizados.")
                                            .font(.custom("Poppins-Regular", size: 14))
                                            .foregroundColor(.gray)
                                            .italic()
                                    } else {
                                        ForEach(insights, id: \.self) { insight in
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: "lightbulb.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.system(size: 16))
                                                
                                                Text(insight)
                                                    .font(.custom("Poppins-Regular", size: 14))
                                                    .foregroundColor(.black)
                                            }
                                            .padding()
                                            .background(Color.yellow.opacity(0.1))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
                        }
                        .navigationTitle("Árbol de Aprendizaje")
                        .onAppear {
                            // Set default selected style to the recommended one
                            if selectedStyleId.isEmpty && !analyzer.recommendedStyle.isEmpty {
                                selectedStyleId = analyzer.recommendedStyle
                            } else if selectedStyleId.isEmpty, let firstStyle = analyzer.stylePerformances.first {
                                selectedStyleId = firstStyle.id
                            }
                            NotificationCenter.default.addObserver(
                                forName: NSNotification.Name("SelectLearningStyle"),
                                object: nil,
                                queue: .main) { notification in
                                    if let styleId = notification.userInfo?["styleId"] as? String {
                                        selectedStyleId = styleId
                                    }
                                }
                        }
                        .onDisappear{
                            NotificationCenter.default.removeObserver(
                                self,
                                name: NSNotification.Name("SelectLearningStyle"),
                                object: nil
                            )
                        }
                        .sheet(isPresented: $showingInsights) {
                            LearningInsightsView()
                        }
                    }
                }

                // Learning style insights view
                struct LearningInsightsView: View {
                    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
                    @Environment(\.presentationMode) var presentationMode
                    
                    var body: some View {
                        NavigationView {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Análisis de tu aprendizaje")
                                        .font(.custom("Poppins-Bold", size: 24))
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                    
                                    Text("Basado en tu historial de aprendizaje, hemos identificado las siguientes características:")
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                    
                                    // Insights cards
                                    VStack(spacing: 15) {
                                        let insights = analyzer.generateInsights()
                                        
                                        if insights.isEmpty {
                                            Text("Completa más misiones para obtener insights personalizados sobre tu estilo de aprendizaje.")
                                                .font(.custom("Poppins-Regular", size: 16))
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(Color.blue.opacity(0.05))
                                                .cornerRadius(15)
                                        } else {
                                            ForEach(insights, id: \.self) { insight in
                                                HStack(alignment: .top, spacing: 15) {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.system(size: 24))
                                                        .frame(width: 30)
                                                    
                                                    Text(insight)
                                                        .font(.custom("Poppins-Regular", size: 16))
                                                        .foregroundColor(.black)
                                                    
                                                    Spacer()
                                                }
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(15)
                                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    // Learning style comparison
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Comparación de estilos")
                                            .font(.custom("Poppins-SemiBold", size: 18))
                                            .foregroundColor(.black)
                                            .padding(.horizontal)
                                        
                                        // Style performance bars
                                        ForEach(analyzer.stylePerformances) { style in
                                            VStack(alignment: .leading, spacing: 5) {
                                                HStack {
                                                    Image(systemName: style.icon)
                                                        .foregroundColor(.blue)
                                                    
                                                    Text(style.name)
                                                        .font(.custom("Poppins-SemiBold", size: 14))
                                                        .foregroundColor(.black)
                                                    
                                                    Spacer()
                                                    
                                                    if style.completedQuests > 0 {
                                                        Text("Nivel \(style.skillLevel)")
                                                            .font(.custom("Poppins-Regular", size: 12))
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                
                                                GeometryReader { geo in
                                                    ZStack(alignment: .leading) {
                                                        Rectangle()
                                                            .foregroundColor(Color.gray.opacity(0.2))
                                                            .frame(height: 10)
                                                            .cornerRadius(5)
                                                        
                                                        // Scale performance with completed quests and score
                                                        let performance = Double(style.completedQuests) * style.averageScore / 100.0
                                                        let normalizedPerformance = min(1.0, performance / 10.0) // Normalize to 10 quests with 100% score
                                                        
                                                        Rectangle()
                                                            .foregroundColor(style.id == analyzer.recommendedStyle ? Color.blue : Color.green)
                                                            .frame(width: max(0, geo.size.width * CGFloat(normalizedPerformance)), height: 10)
                                                            .cornerRadius(5)
                                                    }
                                                }
                                                .frame(height: 10)
                                                
                                                if style.completedQuests > 0 {
                                                    Text("\(style.completedQuests) misiones • \(Int(style.averageScore))% promedio")
                                                        .font(.custom("Poppins-Regular", size: 12))
                                                        .foregroundColor(.gray)
                                                } else {
                                                    Text("Sin datos suficientes")
                                                        .font(.custom("Poppins-Regular", size: 12))
                                                        .foregroundColor(.gray)
                                                        .italic()
                                                }
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.vertical)
                                    
                                    // Next step recommendations
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("¿Qué hacer ahora?")
                                            .font(.custom("Poppins-SemiBold", size: 18))
                                            .foregroundColor(.black)
                                            .padding(.horizontal)
                                        
                                        HStack {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 30))
                                            
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Explora más estilos de aprendizaje")
                                                    .font(.custom("Poppins-SemiBold", size: 16))
                                                    .foregroundColor(.black)
                                                
                                                Text("Prueba misiones con diferentes estilos para descubrir cuál funciona mejor para ti.")
                                                    .font(.custom("Poppins-Regular", size: 14))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                        
                                        if let recommendedStyle = analyzer.getPerformance(for: analyzer.recommendedStyle) {
                                            HStack {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.system(size: 30))
                                                
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text("Profundiza en tu estilo fuerte")
                                                        .font(.custom("Poppins-SemiBold", size: 16))
                                                        .foregroundColor(.black)
                                                    
                                                    Text("Continúa con más misiones de estilo \(recommendedStyle.name) para mejorar tu nivel.")
                                                        .font(.custom("Poppins-Regular", size: 14))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical)
                                }
                                .padding(.vertical, 20)
                            }
                            .navigationBarTitle("Insights de Aprendizaje", displayMode: .inline)
                            .navigationBarItems(trailing: Button("Cerrar") {
                                presentationMode.wrappedValue.dismiss()
                            })
                            .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
                        }
                    }
                }

                // ML Style Predictor implementation
                class MLStylePredictor {
                    // This is a placeholder for the Core ML model
                    // In a real app, you would implement the ML model logic here
                    
                    func predictBestStyle(from dataPoints: [HistoricalPerformance]) -> (styleId: String, confidence: Double)? {
                        guard !dataPoints.isEmpty else {
                            return nil
                        }
                        
                        // Group data points by style
                        var styleData: [String: [HistoricalPerformance]] = [:]
                        for point in dataPoints {
                            if styleData[point.styleId] == nil {
                                styleData[point.styleId] = []
                            }
                            styleData[point.styleId]?.append(point)
                        }
                        
                        // Analyze each style
                        var styleScores: [String: Double] = [:]
                        for (style, points) in styleData {
                            // Calculate average score
                            let avgScore = points.reduce(0.0) { $0 + $1.score } / Double(points.count)
                            
                            // Calculate recency factor (more recent learning is more important)
                            let mostRecentDate = points.max(by: { $0.date < $1.date })?.date ?? Date()
                            let daysSinceRecent = Double(Calendar.current.dateComponents([.day], from: mostRecentDate, to: Date()).day ?? 0)
                            let recencyFactor = 1.0 / max(1.0, daysSinceRecent + 1.0)
                            
                            // Calculate improvement trend
                            var improvementFactor = 1.0
                            if points.count > 1 {
                                let sortedPoints = points.sorted(by: { $0.date < $1.date })
                                let firstHalf = Array(sortedPoints.prefix(sortedPoints.count / 2))
                                let secondHalf = Array(sortedPoints.suffix(sortedPoints.count / 2))
                                
                                let firstHalfAvg = firstHalf.reduce(0.0) { $0 + $1.score } / Double(firstHalf.count)
                                let secondHalfAvg = secondHalf.reduce(0.0) { $0 + $1.score } / Double(secondHalf.count)
                                
                                improvementFactor = secondHalfAvg / max(1.0, firstHalfAvg)
                            }
                            
                            // Combine factors for final score
                            let styleScore = avgScore * 0.4 + Double(points.count) * 0.1 + recencyFactor * 0.1 + improvementFactor * 0.1
                            styleScores[style] = styleScore
                        }
                        
                        // Find the best style
                        if let bestStyle = styleScores.max(by: { $0.value < $1.value }) {
                            // Normalize confidence to 0-1 range
                            let maxPossibleScore = 100.0 // Perfect score on all factors
                            let confidence = min(1.0, bestStyle.value / maxPossibleScore)
                            return (bestStyle.key, confidence)
                        }
                        
                        return nil
                    }
                }

                // Update UserDataManager to integrate with LearningStyleAnalyzer
                extension UserDataManager {
                    // Record quest completion with learning style information
                    func recordQuestCompletion(questTitle: String, score: Double, timeSpent: TimeInterval) {
                        // Mark quest as completed
                        markQuestAsCompleted(questTitle)
                        
                        // Find the quest to get its learning styles
                        if let quest = availableQuests.first(where: { $0.title == questTitle }) {
                            // Update user XP
                            userProfile.xpPoints += quest.xpReward
                            userProfile.dailyProgress += quest.xpReward
                            
                            // Update streak if needed
                            // This would need more logic in a real app to track daily usage
                            
                            // Save user data
                            saveUserData()
                            
                            // Record learning style information
                            for styleId in quest.learningStyles {
                                LearningStyleAnalyzer.shared.recordQuestCompletionWithHistory(
                                    styleId: styleId,
                                    score: score,
                                    timeSpent: timeSpent,
                                    questTitle: questTitle
                                )
                            }
                            
                            // Update recommended style based on new data
                            LearningStyleAnalyzer.shared.updateRecommendation()
                        }
                    }
                    
                    // Get next recommended quest based on learning style
                    func getNextRecommendedQuest() -> Quest? {
                        return LearningStyleAnalyzer.shared.getNextQuestRecommendation(from: availableQuests)
                    }
                }

                // Add ML recommendation system to quest completion views
                extension Quest {
                    // Helper to get primary learning style
                    var primaryLearningStyle: String? {
                        return learningStyles.first
                    }
                    
                    // Helper to record completion with metrics
                    func recordCompletion(score: Double, timeSpent: TimeInterval) {
                        UserDataManager.shared.recordQuestCompletion(
                            questTitle: title,
                            score: score,
                            timeSpent: timeSpent
                        )
                    }
                }

                // Preview provider
                struct LearningStyleTreeView_Previews: PreviewProvider {
                    static var previews: some View {
                        LearningStyleTreeView()
                    }
                }
