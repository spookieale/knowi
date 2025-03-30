import SwiftUI

struct ProfileView: View {
    @ObservedObject private var userDataManager = UserDataManager.shared
    @ObservedObject private var learningAnalyzer = LearningStyleAnalyzer.shared
    @State private var showingStyleComparisonView = false
    @State private var showingLearningInsights = false
    @State private var selectedTab = 0
    @State private var navigateToStyle: String? = nil
    
    // For animation
    @State private var animateXP = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile header with avatar and basic info
                headerView
                
                // Stats cards
                HStack(spacing: 15) {
                    // Level card
                    statsCard(
                        title: "Nivel",
                        value: "\(userDataManager.calculateLevel())",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    // XP card
                    statsCard(
                        title: "XP Total",
                        value: "\(userDataManager.userProfile.xpPoints)",
                        icon: "bolt.fill",
                        color: .orange
                    )
                    
                    // Streak card
                    statsCard(
                        title: "Racha",
                        value: "\(userDataManager.userProfile.streak)",
                        icon: "flame.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Level progress
                levelProgressView
                
                // Tabs for different profile sections
                VStack(spacing: 5) {
                    // Tab selector
                    HStack(spacing: 0) {
                        tabButton(title: "Aprendizaje", index: 0)
                        tabButton(title: "Logros", index: 1)
                        tabButton(title: "Estadísticas", index: 2)
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(25)
                    .padding(.horizontal)
                    
                    // Tab content
                    VStack {
                        if selectedTab == 0 {
                            learningStylesView
                        } else if selectedTab == 1 {
                            achievementsView
                        } else {
                            statisticsView
                        }
                    }
                    .padding(.top, 10)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
        .navigationTitle("Mi Perfil")
        .sheet(isPresented: $showingStyleComparisonView) {
            StyleComparisonView()
        }
        .sheet(isPresented: $showingLearningInsights) {
            LearningInsightsView()
        }
        .background(
            // Navigation links
            NavigationLink(
                destination: LearningStyleTreeView().onAppear {
                    // This allows us to navigate to the tree view without directly
                    // accessing its private state variables
                    if let styleId = navigateToStyle {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SelectLearningStyle"),
                                object: nil,
                                userInfo: ["styleId": styleId]
                            )
                        }
                    }
                },
                tag: "treeView",
                selection: Binding(
                    get: { navigateToStyle != nil ? "treeView" : nil },
                    set: { _ in navigateToStyle = nil }
                )
            ) {
                EmptyView()
            }
        )
        .onAppear {
            // Start animation for XP progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    animateXP = true
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack {
            // Profile background and avatar
            ZStack(alignment: .bottom) {
                // Background gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                    .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                    .padding(.horizontal)
                
                // Avatar image
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Use system icon as fallback if no custom avatar
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue.opacity(0.8))
                        .frame(width: 80, height: 80)
                }
                .offset(y: 45)
            }
            
            // Name and info
            VStack(spacing: 5) {
                Text(userDataManager.userProfile.name)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.black)
                    .padding(.top, 55)
                
                // Learning style preferences
                Text("Estilos de aprendizaje: \(formattedLearningStyles)")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
                
                // Recommended style if available
                if !learningAnalyzer.recommendedStyle.isEmpty,
                   let style = learningAnalyzer.getPerformance(for: learningAnalyzer.recommendedStyle) {
                    HStack {
                        Image(systemName: style.icon)
                            .foregroundColor(.blue)
                        
                        Text("Estilo recomendado: \(style.name)")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            showingLearningInsights = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.top, 5)
                }
            }
        }
    }
    
    // MARK: - Level Progress View
    private var levelProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progreso de nivel")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                // XP remaining to next level
                let currentLevel = userDataManager.calculateLevel()
                let xpForNextLevel = currentLevel * 500
                let xpRemaining = xpForNextLevel - userDataManager.userProfile.xpPoints
                
                if xpRemaining > 0 {
                    Text("\(xpRemaining) XP para nivel \(currentLevel + 1)")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: animateXP ?
                           CGFloat(userDataManager.calculateLevelProgress()) * UIScreen.main.bounds.width - 40 : 0,
                           height: 12)
            }
            
            // Level indicators
            HStack {
                Text("Nivel \(userDataManager.calculateLevel())")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Nivel \(userDataManager.calculateLevel() + 1)")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Learning Styles Tab View
    private var learningStylesView: some View {
        VStack(spacing: 15) {
            // Header and buttons
            HStack {
                Text("Mi estilo de aprendizaje")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    showingStyleComparisonView = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Comparar")
                            .font(.custom("Poppins-SemiBold", size: 14))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            // Radar chart
            if !learningAnalyzer.stylePerformances.isEmpty {
                RadarChartView()
                    .frame(height: 250)
                    .padding()
            }
            
            // Learning style cards
            ForEach(learningAnalyzer.stylePerformances) { style in
                LearningStyleCardView(style: style, navigateToTreeView: { styleId in
                    navigateToStyle = styleId
                })
            }
            
            // Insights and recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                let insights = learningAnalyzer.generateInsights()
                
                if insights.isEmpty {
                    Text("Completa más misiones para obtener insights personalizados sobre tu estilo de aprendizaje.")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(insights.prefix(2), id: \.self) { insight in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                            
                            Text(insight)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    if insights.count > 2 {
                        Button(action: {
                            showingLearningInsights = true
                        }) {
                            Text("Ver todos los insights")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.blue)
                                .padding(.vertical, 5)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Achievements Tab View
    private var achievementsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Logros desbloqueados")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            // Calculate completed quests
            let completedQuests = userDataManager.availableQuests.filter(\.isCompleted)
            
            if completedQuests.isEmpty {
                Text("Aún no has desbloqueado ningún logro. ¡Completa misiones para ganar logros!")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(completedQuests) { quest in
                    achievementCard(
                        title: quest.title,
                        description: "Completaste la misión \(quest.title) y ganaste \(quest.xpReward) XP",
                        iconName: quest.iconName,
                        color: quest.difficulty.color
                    )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Statistics Tab View
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Mis estadísticas")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            // Learning stats
            Group {
                // Completed quests
                VStack(alignment: .leading, spacing: 5) {
                    Text("Misiones completadas")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    HStack {
                        let completedCount = userDataManager.availableQuests.filter(\.isCompleted).count
                        let totalCount = userDataManager.availableQuests.count
                        
                        Text("\(completedCount) de \(totalCount)")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 8)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green)
                                .frame(width: totalCount > 0 ? 120 * CGFloat(completedCount) / CGFloat(totalCount) : 0, height: 8)
                        }
                    }
                }
                
                // Mission success rate
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tasa de éxito")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    let correctResponses = learningAnalyzer.stylePerformances.reduce(0) { $0 + $1.completedQuests }
                    let totalInteractions = correctResponses + learningAnalyzer.recentCompletions.count
                    let successRate = totalInteractions > 0 ? Double(correctResponses) / Double(totalInteractions) * 100 : 0
                    
                    HStack {
                        Text(String(format: "%.1f%%", successRate))
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 8)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.blue)
                                .frame(width: 120 * CGFloat(successRate) / 100, height: 8)
                        }
                    }
                }
                
                // Average score
                VStack(alignment: .leading, spacing: 5) {
                    Text("Puntuación promedio")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    let avgScore = learningAnalyzer.stylePerformances.count > 0 ?
                        learningAnalyzer.stylePerformances.reduce(0.0) { $0 + $1.averageScore } /
                        Double(learningAnalyzer.stylePerformances.count) : 0
                    
                    HStack {
                        Text(String(format: "%.1f/100", avgScore))
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 8)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.purple)
                                .frame(width: 120 * CGFloat(avgScore) / 100, height: 8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            
            // Daily streak stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Estadísticas diarias")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Hoy")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\(userDataManager.userProfile.dailyProgress) XP")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                    }
                    
                    VStack {
                        Text("Meta diaria")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\(userDataManager.userProfile.dailyGoal) XP")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                    }
                    
                    VStack {
                        Text("Racha")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\(userDataManager.userProfile.streak) días")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Daily progress bar
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Progreso de hoy:")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        let progress = min(Double(userDataManager.userProfile.dailyProgress) /
                                           Double(userDataManager.userProfile.dailyGoal), 1.0)
                        Text("\(Int(progress * 100))%")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(progress >= 1.0 ? .green : .blue)
                    }
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width - 70, height: 8)
                            .scaleEffect(x: CGFloat(min(Double(userDataManager.userProfile.dailyProgress) /
                                                         Double(userDataManager.userProfile.dailyGoal), 1.0)),
                                         y: 1, anchor: .leading)
                            .animation(.spring(), value: userDataManager.userProfile.dailyProgress)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Views
    
    // Stats card for top section
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
            
            Text(value)
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.black)
            
            Text(title)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Tab selector button
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(selectedTab == index ? .white : .gray)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(selectedTab == index ?
                            Capsule().fill(Color.blue) :
                            Capsule().fill(Color.clear))
                .animation(.spring(), value: selectedTab)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    // Achievement card for achievements tab
    private func achievementCard(title: String, description: String, iconName: String, color: Color) -> some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .foregroundColor(color)
                    .font(.system(size: 22))
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Achievement badge
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Helper computed properties
    private var formattedLearningStyles: String {
        let styleNames = userDataManager.userProfile.learningStyles.compactMap { styleId in
            learningAnalyzer.stylePerformances.first(where: { $0.id == styleId })?.name
        }
        
        return styleNames.isEmpty ? "No seleccionado" : styleNames.joined(separator: ", ")
    }
}

// MARK: - Learning Style Card View
struct LearningStyleCardView: View {
    let style: StylePerformance
    let navigateToTreeView: (String) -> Void
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and name
            HStack {
                Image(systemName: style.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(style.id == analyzer.recommendedStyle ? Color.blue : Color.gray)
                    )
                
                Text(style.name)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                if style.id == analyzer.recommendedStyle {
                    Text("Recomendado")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 5) {
                Text("Nivel \(style.skillLevel)")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.gray)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(style.id == analyzer.recommendedStyle ? Color.blue : Color.green)
                        .frame(width: UIScreen.main.bounds.width - 90, height: 6)
                        .scaleEffect(x: style.progressPercentage, y: 1, anchor: .leading)
                }
            }
            
            // Stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Misiones")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.gray)
                    
                    Text("\(style.completedQuests)")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Promedio")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f%%", style.averageScore))
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Button to navigate to learning tree
                Button(action: {
                    navigateToTreeView(style.id)
                }) {
                    Text("Ver árbol")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Extensions
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
