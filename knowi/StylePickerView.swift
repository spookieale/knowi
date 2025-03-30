import SwiftUI

// Model for avatar selection
struct AvatarOption: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

// Model for learning style preference
struct LearningStyle: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    var isSelected: Bool = false
    
    static let allStyles = [
        LearningStyle(id: "visual", name: "Visual", icon: "eye.fill"),
        LearningStyle(id: "auditory", name: "Auditivo", icon: "speaker.wave.2.fill"),
        LearningStyle(id: "reading", name: "Lectura", icon: "book.fill"),
        LearningStyle(id: "kinesthetic", name: "Kinestésico", icon: "hand.tap.fill")
    ]
}

// UserDefaults manager for preferences
class LearningPreferences: ObservableObject {
    static let shared = LearningPreferences()
    
    @Published var selectedStyles: [String] = [] {
        didSet {
            savePreferences()
        }
    }
    
    init() {
        loadPreferences()
    }
    
    func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "learningStyles") {
            if let decoded = try? JSONDecoder().decode([String].self, from: data) {
                self.selectedStyles = decoded
                return
            }
        }
        // Default if nothing saved
        self.selectedStyles = []
    }
    
    func savePreferences() {
        if let encoded = try? JSONEncoder().encode(selectedStyles) {
            UserDefaults.standard.set(encoded, forKey: "learningStyles")
        }
    }
    
    func toggleStyle(id: String) {
        if selectedStyles.contains(id) {
            selectedStyles.removeAll { $0 == id }
        } else {
            selectedStyles.append(id)
        }
    }
    
    func isStyleSelected(id: String) -> Bool {
        return selectedStyles.contains(id)
    }
}

struct StyleOptionButton: View {
    let style: LearningStyle
    @ObservedObject var preferences: LearningPreferences
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                preferences.toggleStyle(id: style.id)
                isPressed = true
                
                // Reset the press animation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }) {
            HStack {
                Image(systemName: style.icon)
                    .font(.system(size: 22))
                    .foregroundColor(preferences.isStyleSelected(id: style.id) ? Color.blue : Color.blue.opacity(0.7))
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .padding(.leading, 25)
                
                Text(style.name)
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(preferences.isStyleSelected(id: style.id) ? Color.blue : Color.blue.opacity(0.7))
                    .padding(.leading, 15)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 65)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .shadow(color: preferences.isStyleSelected(id: style.id) ? Color.blue.opacity(0.3) : Color.black.opacity(0.05),
                            radius: preferences.isStyleSelected(id: style.id) ? 8 : 4,
                           x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(preferences.isStyleSelected(id: style.id) ? Color.blue.opacity(0.7) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

// Floating particles for background animation
struct FloatingParticle: View {
    let size: CGFloat
    let position: CGPoint
    let color: Color
    let speed: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(x: position.x, y: position.y)
            .opacity(0.2)
            .blur(radius: 2)
            .offset(y: isAnimating ? 400 : 0)
            .animation(
                Animation.linear(duration: speed)
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...3)),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// Steps in onboarding process
enum OnboardingStep {
    case learningStyles
    case nameInput
    case avatarSelection
    case complete
}

struct StylePickerView: View {
    @StateObject private var preferences = LearningPreferences.shared
    @State private var currentStep: OnboardingStep = .learningStyles
    @State private var userName: String = ""
    @State private var selectedAvatar: AvatarOption?
    @State private var isNextButtonActive = false
    @State private var showParticles = false
    @State private var navigateToHome = false
    
    // Avatar options
    let avatarOptions = [
        AvatarOption(name: "Wizard", imageName: "avatar1"),
        AvatarOption(name: "Scholar", imageName: "avatar2"),
        AvatarOption(name: "Explorer", imageName: "avatar3"),
        AvatarOption(name: "Scientist", imageName: "avatar4"),
        AvatarOption(name: "Sage", imageName: "avatar5")
    ]
    
    // Create random particles for background
    private var particles: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                FloatingParticle(
                    size: CGFloat.random(in: 10...30),
                    position: CGPoint(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...100)
                    ),
                    color: [Color.blue, Color.purple].randomElement() ?? Color.blue,
                    speed: Double.random(in: 15...25)
                )
            }
        }
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
            
            // Animated particles
            if showParticles {
                particles
            }
            
            // Main content based on current step
            Group {
                if currentStep == .learningStyles {
                    learningStylesView
                } else if currentStep == .nameInput {
                    nameInputView
                } else if currentStep == .avatarSelection {
                    avatarSelectionView
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: currentStep)
            
            // Navigation link to HomeView
            NavigationLink(
                destination: HomeView(),
                isActive: $navigateToHome,
                label: { EmptyView() }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            // Delay particle effect for smoother loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showParticles = true
                }
            }
        }
    }
    
    // MARK: - Learning Styles View
    private var learningStylesView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)
            
            // Title with animation
            Text("¿Cómo te gustaría aprender?")
                .font(.custom("Poppins-Bold", size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            
            // Subtitle
            Text("Escoge los estilos que quieras probar.")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Learning style options
            VStack(spacing: 12) {
                ForEach(LearningStyle.allStyles, id: \.id) { style in
                    StyleOptionButton(style: style, preferences: preferences)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                withAnimation {
                    currentStep = .nameInput
                }
            }) {
                Text("Continuar")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 40)
                    .opacity(preferences.selectedStyles.isEmpty ? 0.7 : 1.0)
            }
            .disabled(preferences.selectedStyles.isEmpty)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Name Input View
    private var nameInputView: some View {
        VStack(spacing: 25) {
            Spacer()
                .frame(height: 60)
            
            Text("¿Cómo te llamas?")
                .font(.custom("Poppins-Bold", size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            
            Text("Dinos tu nombre para personalizar tu experiencia")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Name text field
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(height: 60)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                TextField("Escribe tu nombre", text: $userName)
                    .font(.custom("Poppins-Regular", size: 18))
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 20) {
                // Back button
                Button(action: {
                    withAnimation {
                        currentStep = .learningStyles
                    }
                }) {
                    Text("Atrás")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                
                // Next button
                Button(action: {
                    withAnimation {
                        currentStep = .avatarSelection
                    }
                }) {
                    Text("Continuar")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .opacity(userName.isEmpty ? 0.7 : 1.0)
                }
                .disabled(userName.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Avatar Selection View
    private var avatarSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 40)
                
                Text("Escoge tu avatar")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                Text("¿Quién te representará en tu viaje de aprendizaje?")
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            
            // Avatar grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
                    ForEach(avatarOptions) { avatar in
                        VStack {
                            // Avatar image with selection indicator
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                // Using wizardWicho for all avatars
                                Image("wizardWicho")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                
                                // Selection indicator
                                if selectedAvatar?.id == avatar.id {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 4)
                                        .frame(width: 84, height: 84)
                                }
                            }
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedAvatar = avatar
                                }
                            }
                            
                            Text(avatar.name)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .frame(maxHeight: 300)
            
                // Navigation buttons
                HStack(spacing: 20) {
                    // Back button
                    Button(action: {
                        withAnimation {
                            currentStep = .nameInput
                        }
                    }) {
                        Text("Atrás")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    
                    // Complete button
                    Button(action: {
                        // Save user profile data
                        let userProfile = UserProfile(
                            name: userName,
                            avatarName: selectedAvatar?.imageName ?? "avatar1",
                            xpPoints: 0,
                            dailyGoal: 100,
                            dailyProgress: 0,
                            streak: 0,
                            learningStyles: preferences.selectedStyles
                        )
                        
                        // Save to UserDataManager
                        UserDataManager.shared.userProfile = userProfile
                        UserDataManager.shared.saveUserData()
                        
                        // Navigate to HomeView
                        navigateToHome = true
                    }) {
                        Text("¡Empezar!")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .opacity(selectedAvatar == nil ? 0.7 : 1.0)
                    }
                    .disabled(selectedAvatar == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

// Extension to navigate from landing to style picker
extension LandingView {
    func navigateToStylePicker() -> some View {
        NavigationLink(destination: StylePickerView()) {
            Text("Empezar")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(Color.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(40)
                .padding(.horizontal, 80)
                .offset(y: 60)
        }
    }
}

struct StylePickerView_Previews: PreviewProvider {
    static var previews: some View {
        StylePickerView()
    }
}
