//
//  HomeView.swift
//  knowi
//
//  Created by Alumno on 29/03/25.
//

import SwiftUI

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
    let isCompleted: Bool
    let completionPercentage: Double
    
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
    @Published var currentQuest: Quest?
    @Published var suggestedQuest: Quest?
    @Published var recentTopics: [Quest] = []
    
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
        // In a real app, these would be loaded from a database or API
        // Sample data for development
        currentQuest = Quest(
            title: "Python Basics",
            description: "Learn the fundamentals of Python programming language",
            xpReward: 150,
            duration: 25,
            difficulty: .intermediate,
            learningStyles: ["visual", "reading"],
            iconName: "laptopcomputer",
            isCompleted: false,
            completionPercentage: 0.45
        )
        
        suggestedQuest = Quest(
            title: "Data Visualization",
            description: "Create interactive charts using Python libraries",
            xpReward: 200,
            duration: 30,
            difficulty: .intermediate,
            learningStyles: ["visual", "kinesthetic"],
            iconName: "chart.bar.fill",
            isCompleted: false,
            completionPercentage: 0,
            isRecommended: true,
            recommendationReason: "Matches your visual learning style"
        )
        
        recentTopics = [
            Quest(
                title: "Variables & Types",
                description: "Understanding data types and variables in Python",
                xpReward: 100,
                duration: 15,
                difficulty: .beginner,
                learningStyles: ["reading", "visual"],
                iconName: "doc.text",
                isCompleted: true,
                completionPercentage: 1.0
            ),
            Quest(
                title: "Control Flow",
                description: "Learn if-else statements and loops in Python",
                xpReward: 120,
                duration: 20,
                difficulty: .beginner,
                learningStyles: ["visual", "kinesthetic"],
                iconName: "arrow.branch",
                isCompleted: true,
                completionPercentage: 1.0
            ),
            Quest(
                title: "Functions",
                description: "Create and use functions in Python",
                xpReward: 130,
                duration: 20,
                difficulty: .intermediate,
                learningStyles: ["reading", "auditory"],
                iconName: "function",
                isCompleted: false,
                completionPercentage: 0.8
            )
        ]
    }
    
    func generateRecommendations() {
        // This is where Core ML integration would happen
        // Based on user behavior, learning styles, and progress
        // For now, we're just using the sample suggestedQuest
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
            Image(avatarName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
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
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.white.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: max(20, UIScreen.main.bounds.width - 40) * CGFloat(levelProgress), height: 8)
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            
            // Daily goal progress
            HStack(alignment: .center) {
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
                        .frame(width: 150 * CGFloat(dailyProgress) / CGFloat(dailyGoal), height: 8)
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
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Continúa aprendiendo")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: quest.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(quest.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundColor(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .foregroundColor(.blue)
                            .frame(width: CGFloat(quest.completionPercentage) * (UIScreen.main.bounds.width - 115), height: 6)
                            .cornerRadius(3)
                    }
                    
                    HStack {
                        Text("\(Int(quest.completionPercentage * 100))% completado")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(quest.duration) min restantes")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Button(action: {
                // Action to continue the lesson
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
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct SuggestedQuestCard: View {
    let quest: Quest
    
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
            
            Button(action: {
                // Action to start this quest
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
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct RecentTopicsView: View {
    let topics: [Quest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Temas recientes")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(topics) { topic in
                        VStack(alignment: .leading, spacing: 12) {
                            // Topic icon and completion indicator
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(topic.difficulty.color.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: topic.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(topic.difficulty.color)
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
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .foregroundColor(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .foregroundColor(topic.difficulty.color)
                                        .frame(width: CGFloat(topic.completionPercentage) * 120, height: 4)
                                        .cornerRadius(2)
                                }
                            }
                        }
                        .padding()
                        .frame(width: 150, height: 150)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct HomeView: View {
    @StateObject private var userDataManager = UserDataManager.shared
    
    var body: some View {
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
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
                
                // Main content
                VStack(spacing: 20) {
                    // Continue learning card
                    if let currentQuest = userDataManager.currentQuest {
                        ContinueLearningCard(quest: currentQuest)
                            .padding(.horizontal)
                    }
                    
                    // AI-suggested quest
                    if let suggestedQuest = userDataManager.suggestedQuest {
                        SuggestedQuestCard(quest: suggestedQuest)
                            .padding(.horizontal)
                    }
                    
                    // Recent topics
                    if !userDataManager.recentTopics.isEmpty {
                        RecentTopicsView(topics: userDataManager.recentTopics)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
    }
}

// Extension for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
