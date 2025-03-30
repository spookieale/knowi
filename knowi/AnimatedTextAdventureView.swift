import SwiftUI

struct AnimatedTextAdventureView: View {
    // Enhanced story segments with more properties
    struct StorySegment {
        let text: String
        let choices: [Choice]
        let info: String? // extra educational info (optional)
        let emoji: String // visual representation using emoji
        let backgroundName: String // dynamic backgrounds
        let learningPoints: Int // points awarded for this segment
        let quiz: Quiz? // optional quiz for interactive learning
    }
    
    struct Choice: Identifiable {
        let id = UUID()
        let text: String
        let nextSegment: Int? // if nil, the story ends
        let emoji: String // emoji for visual context
    }
    
    struct Quiz {
        let question: String
        let options: [String]
        let correctOptionIndex: Int
        let explanation: String
    }
    
    // A sample story about Ancient Egypt that teaches historical concepts.
    let segments: [StorySegment] = [
        StorySegment(
            text: "Bienvenido a tu aventura en el Antiguo Egipto. Hoy aprenderás sobre las pirámides y la escritura jeroglífica. ¿Qué te gustaría explorar primero?",
            choices: [
                Choice(text: "Las Pirámides", nextSegment: 1, emoji: "🏔️"),
                Choice(text: "Jeroglíficos", nextSegment: 2, emoji: "📜")
            ],
            info: nil,
            emoji: "🏺",
            backgroundName: "ChallengeStart",
            learningPoints: 5,
            quiz: nil
        ),
        StorySegment(
            text: "Las pirámides no solo eran tumbas, sino obras maestras de ingeniería y matemáticas. Su construcción refleja un profundo conocimiento de la astronomía.",
            choices: [
                Choice(text: "Continuar", nextSegment: 3, emoji: "➡️")
            ],
            info: "Estudiar las pirámides ayuda a comprender cómo se aplicaban principios matemáticos en la antigüedad.",
            emoji: "🔺",
            backgroundName: "AdventureStart",
            learningPoints: 10,
            quiz: nil
        ),
        StorySegment(
            text: "Los jeroglíficos eran mucho más que un simple alfabeto; eran un sistema complejo que combinaba imágenes y sonidos para transmitir ideas.",
            choices: [
                Choice(text: "Continuar", nextSegment: 3, emoji: "➡️")
            ],
            info: "Los jeroglíficos ofrecen una ventana a la cultura, la religión y la política del antiguo Egipto.",
            emoji: "𓀀",
            backgroundName: "ChallengeEnd",
            learningPoints: 10,
            quiz: nil
        ),
        StorySegment(
            text: "Ahora, responde: ¿Cuál era la principal función de las pirámides?",
            choices: [
                Choice(text: "Residencia de los faraones", nextSegment: 4, emoji: "🏠"),
                Choice(text: "Tumbas reales", nextSegment: 5, emoji: "⚰️"),
                Choice(text: "Centros de comercio", nextSegment: 4, emoji: "🛒")
            ],
            info: nil,
            emoji: "❓",
            backgroundName: "AdventureEnd",
            learningPoints: 15,
            quiz: Quiz(
                question: "¿Cuál era la principal función de las pirámides?",
                options: [
                    "Residencia de los faraones",
                    "Tumbas reales",
                    "Centros de comercio",
                    "Observatorios astronómicos"
                ],
                correctOptionIndex: 1,
                explanation: "Las pirámides eran principalmente tumbas reales diseñadas para preservar el cuerpo del faraón y ayudar a su espíritu en su viaje al más allá."
            )
        ),
        StorySegment(
            text: "Incorrecto. La respuesta correcta es que eran tumbas reales para los faraones. ¡Inténtalo de nuevo!",
            choices: [
                Choice(text: "Reintentar", nextSegment: 3, emoji: "🔄")
            ],
            info: nil,
            emoji: "❌",
            backgroundName: "ChallengeStart",
            learningPoints: 0,
            quiz: nil
        ),
        StorySegment(
            text: "¡Correcto! Las pirámides eran tumbas reales. Gracias a tu curiosidad, has descubierto aspectos esenciales de la civilización egipcia.",
            choices: [
                Choice(text: "Finalizar", nextSegment: 0, emoji: "🏁")
            ],
            info: "Este conocimiento te ayudará a entender cómo la tecnología y el arte se entrelazaban en la antigüedad.",
            emoji: "✅",
            backgroundName: "ChallengeEnd",
            learningPoints: 25,
            quiz: nil
        )
    ]
    
    @State private var currentSegmentIndex: Int = 0
    @State private var displayedText: String = ""
    @State private var isAnimatingText: Bool = true
    @State private var showChoices: Bool = false
    @State private var showQuiz: Bool = false
    @State private var showExplanation: Bool = false
    @State private var selectedQuizOption: Int? = nil
    @State private var isCorrectAnswer: Bool = false
    @State private var totalLearningPoints: Int = 0
    @State private var earnedPoints: Int = 0
    @State private var showEarnedPoints: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var backgroundOpacity: Double = 0.5
    @State private var emojiScale: CGFloat = 1.0
    @State private var timer: Timer? = nil
    
    // Animation states
    @State private var textScaleEffect: CGFloat = 1.0
    @State private var starOpacity: Double = 0.0
    @State private var showStars: Bool = false
    
    var currentSegment: StorySegment {
        segments[currentSegmentIndex]
    }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            backgroundGradient
            
            // Floating emojis for visual interest
            floatingEmojis
            
            // Main scrollable content
            ScrollView {
                contentStack
            }
        }
        .onAppear {
            startTextAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(currentSegment.backgroundName), Color("AdventureEnd")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(backgroundOpacity)
        .animation(.easeInOut(duration: 2.0), value: backgroundOpacity)
        .ignoresSafeArea()
        .onAppear {
            startBackgroundAnimation()
        }
    }
    
    private var floatingEmojis: some View {
        ZStack {
            // Main emoji
            Text(currentSegment.emoji)
                .font(.system(size: 80))
                .scaleEffect(emojiScale)
                .opacity(0.6)
                .position(x: UIScreen.main.bounds.width * 0.8, y: UIScreen.main.bounds.height * 0.2)
                .animation(
                    Animation.easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: emojiScale
                )
            
            // Background emojis
            backgroundEmojiView(index: 0)
            backgroundEmojiView(index: 1)
            backgroundEmojiView(index: 2)
        }
    }
    
    private func backgroundEmojiView(index: Int) -> some View {
        Text(currentSegment.emoji)
            .font(.system(size: 30 + CGFloat(index * 10)))
            .position(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
            )
            .opacity(0.2)
            .rotationEffect(.degrees(Double(index) * 45))
    }
    
    private var contentStack: some View {
        VStack(spacing: 20) {
            // Learning points and progress display
            pointsDisplayView
            
            // Animated text container with thematic decoration
            textContainerView
            
            // Optional info section
            infoSectionView
            
            // Quiz section (if applicable)
            quizContainerView
            
            // Display choices when text animation is finished
            choicesContainerView
            
            Spacer(minLength: 50) // Extra space at bottom
        }
        .padding(.bottom, 30)
    }
    
    private var pointsDisplayView: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            
            Text("\(totalLearningPoints) puntos")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
            
            if showEarnedPoints {
                Text("+\(earnedPoints)")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.yellow)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseAnimation)
            }
            
            Spacer()
            
            // Segment progress indicator
            Text("\(currentSegmentIndex + 1)/\(segments.count)")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var textContainerView: some View {
        VStack(spacing: 0) {
            // Egyptian-themed header
            headerView
            
            // Main text content
            textContentView
        }
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var headerView: some View {
        HStack {
            Text("🏺")
                .font(.system(size: 24))
            
            Text("Aventura en Egipto")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.black)
            
            Text("🏺")
                .font(.system(size: 24))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.yellow.opacity(0.7))
        .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: 15))
    }
    
    private var textContentView: some View {
        Text(displayedText)
            .font(.custom("Poppins-Regular", size: 20))
            .foregroundColor(.black)
            .padding(20)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 15))
            .scaleEffect(textScaleEffect)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: textScaleEffect)
            .overlay(
                Group {
                    if showStars {
                        starsOverlayView
                    }
                }
            )
    }
    
    private var starsOverlayView: some View {
        ZStack {
            ForEach(0..<5) { i in
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .opacity(starOpacity)
                    .scaleEffect(starOpacity)
                    .position(
                        x: CGFloat.random(in: 50...300),
                        y: CGFloat.random(in: 50...200)
                    )
            }
        }
    }
    
    private var infoSectionView: some View {
        Group {
            if let info = currentSegment.info, !info.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .padding(.top, 3)
                    
                    Text(info)
                        .font(.custom("Poppins-Italic", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding(.horizontal)
                .transition(.opacity)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
            }
        }
    }
    
    private var quizContainerView: some View {
        Group {
            if showQuiz, let quiz = currentSegment.quiz {
                quizView(quiz: quiz)
            }
        }
    }
    
    // Quiz view component
    private func quizView(quiz: Quiz) -> some View {
        VStack(spacing: 15) {
            quizHeaderView(quiz: quiz)
            
            // Quiz options
            quizOptionsView(quiz: quiz)
            
            // Explanation when answer is selected
            if showExplanation {
                quizExplanationView(quiz: quiz)
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.7))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func quizHeaderView(quiz: Quiz) -> some View {
        VStack {
            Text("¡Pon a prueba tu conocimiento!")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.top)
            
            Text(quiz.question)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func quizOptionsView(quiz: Quiz) -> some View {
        VStack(spacing: 10) {
            ForEach(0..<quiz.options.count, id: \.self) { index in
                Button(action: {
                    checkAnswer(index)
                }) {
                    quizOptionRowView(index: index, option: quiz.options[index], quiz: quiz)
                }
                .disabled(selectedQuizOption != nil)
            }
        }
        .padding(.horizontal)
    }
    
    private func quizOptionRowView(index: Int, option: String, quiz: Quiz) -> some View {
        HStack {
            Text(option)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if selectedQuizOption == index {
                Image(systemName: index == quiz.correctOptionIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(index == quiz.correctOptionIndex ? .green : .red)
            }
        }
        .padding()
        .background(
            quizOptionBackground(index: index, correctIndex: quiz.correctOptionIndex)
        )
    }
    
    private func quizOptionBackground(index: Int, correctIndex: Int) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(selectedQuizOption == index
                  ? (index == correctIndex ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                  : Color.black.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedQuizOption == index
                            ? (index == correctIndex ? Color.green : Color.red)
                            : Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func quizExplanationView(quiz: Quiz) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isCorrectAnswer ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(isCorrectAnswer ? .green : .blue)
                    .padding(.top, 3)
                
                Text(quiz.explanation)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
            .padding(.horizontal)
            .transition(.opacity)
            
            Button(action: {
                withAnimation {
                    showQuiz = false
                    showChoices = true
                }
            }) {
                Text("Continuar")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 10)
        }
    }
    
    private var choicesContainerView: some View {
        Group {
            if showChoices {
                choiceButtonsView
            }
        }
    }
    
    private var choiceButtonsView: some View {
        VStack(spacing: 15) {
            ForEach(currentSegment.choices) { choice in
                Button(action: {
                    moveToSegment(choice.nextSegment)
                }) {
                    choiceRowView(choice: choice)
                }
                .buttonStyle(PlainButtonStyle()) // Prevents default button styling
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private func choiceRowView(choice: Choice) -> some View {
        HStack(spacing: 15) {
            Text(choice.emoji)
                .font(.system(size: 24))
                .padding(.leading, 5)
            
            Text(choice.text)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
                .padding(.trailing, 5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Functions
    
    private func startBackgroundAnimation() {
        // Subtle background animation
        withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            backgroundOpacity = 0.8
            emojiScale = 1.3
        }
    }
    
    private func startTextAnimation() {
        // Reset states
        displayedText = ""
        isAnimatingText = true
        showChoices = false
        showQuiz = false
        showExplanation = false
        selectedQuizOption = nil
        textScaleEffect = 1.0
        showStars = false
        starOpacity = 0.0
        
        let fullText = currentSegment.text
        var charIndex = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { t in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText.append(fullText[index])
                charIndex += 1
            } else {
                t.invalidate()
                isAnimatingText = false
                
                // Check if segment has a quiz
                if let _ = currentSegment.quiz {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showQuiz = true
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showChoices = true
                    }
                    // Award learning points if no quiz
                    awardLearningPoints()
                }
            }
        }
    }
    
    private func checkAnswer(_ index: Int) {
        guard let quiz = currentSegment.quiz else { return }
        
        selectedQuizOption = index
        isCorrectAnswer = index == quiz.correctOptionIndex
        
        withAnimation {
            showExplanation = true
        }
        
        // Award points for correct answer or half points for wrong answer
        if isCorrectAnswer {
            earnedPoints = currentSegment.learningPoints * 2 // Bonus for correct answer
            totalLearningPoints += earnedPoints
            showEarnedPoints = true
            pulseAnimation = true
            
            // Show celebration effect
            withAnimation {
                showStars = true
                starOpacity = 1.0
                textScaleEffect = 1.05
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showStars = false
                    starOpacity = 0.0
                    textScaleEffect = 1.0
                }
            }
        } else {
            earnedPoints = currentSegment.learningPoints / 2 // Reduced points for incorrect
            totalLearningPoints += earnedPoints
            showEarnedPoints = true
            pulseAnimation = true
        }
        
        // Reset pulse animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pulseAnimation = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showEarnedPoints = false
            }
        }
    }
    
    private func awardLearningPoints() {
        earnedPoints = currentSegment.learningPoints
        totalLearningPoints += earnedPoints
        showEarnedPoints = true
        pulseAnimation = true
        
        // Reset pulse animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pulseAnimation = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showEarnedPoints = false
            }
        }
    }
    
    private func moveToSegment(_ next: Int?) {
        guard let nextIndex = next else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            displayedText = ""
            showChoices = false
            showQuiz = false
            showExplanation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentSegmentIndex = nextIndex
            startTextAnimation()
        }
    }
}

// Custom shape for rounded corners on specific sides
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Integration with the rest of the app
extension UserDataManager {
    func addEgyptAdventure() {
        // Check if quest already exists
        if availableQuests.contains(where: { $0.title == "Aventura en Egipto" }) {
            return
        }
        
        // Create the Egyptian adventure quest
        let egyptQuest = Quest(
            title: "Aventura en Egipto",
            description: "Embárcate en un viaje interactivo al Antiguo Egipto y aprende sobre su fascinante historia y cultura",
            xpReward: 180,
            duration: 25,
            difficulty: .intermediate,
            learningStyles: ["visual", "reading"],
            iconName: "scroll",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(AnimatedTextAdventureView())
        )
        
        // Add to available quests
        availableQuests.append(egyptQuest)
        
        // If user has visual or reading learning style, make it the suggested quest
        if userProfile.learningStyles.contains("visual") || userProfile.learningStyles.contains("reading") {
            var suggestedCopy = egyptQuest
            suggestedCopy.isRecommended = true
            suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje a través de historias interactivas"
            suggestedQuest = suggestedCopy
        }
        
        // Save changes
        saveUserData()
    }
}
