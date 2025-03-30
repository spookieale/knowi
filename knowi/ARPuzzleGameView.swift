//
//  ARPuzzleGameView.swift
//  knowi
//
//  Created on 29/03/25.
//

import SwiftUI
import ARKit
import RealityKit
import Combine

// Main AR Puzzle Game View
struct ARPuzzleGameView: View {
    @StateObject private var gameViewModel = ARPuzzleGameViewModel()
    @Environment(\.presentationMode) var presentationMode
    var onComplete: ((Int) -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // AR View container
            ARPuzzleViewContainer(viewModel: gameViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Game UI Overlay
            VStack {
                // Top bar with stats and close button
                HStack {
                    Button(action: {
                        gameViewModel.cleanup()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Score display
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(gameViewModel.score) XP")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // Level display
                    HStack {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(.green)
                        
                        Text("Nivel \(gameViewModel.currentLevel)")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
                .padding()
                
                Spacer()
                
                // Bottom controls and info
                VStack(spacing: 15) {
                    // Instructions or feedback
                    Text(gameViewModel.statusMessage)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    // Controls for gameplay
                    HStack(spacing: 20) {
                        if gameViewModel.gameState == .scanning {
                            Button(action: {
                                gameViewModel.startGame()
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Iniciar")
                                }
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(25)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .disabled(!gameViewModel.isPlaneDetected)
                            .opacity(gameViewModel.isPlaneDetected ? 1.0 : 0.5)
                        } else if gameViewModel.gameState == .playing {
                            Button(action: {
                                gameViewModel.showHint()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("Pista")
                                }
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .cornerRadius(25)
                                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            
                            Button(action: {
                                gameViewModel.resetCurrentPuzzle()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Reiniciar")
                                }
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(25)
                                .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        } else if gameViewModel.gameState == .completed {
                            Button(action: {
                                gameViewModel.cleanup()
                                onComplete?(gameViewModel.score)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Completado")
                                }
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(25)
                                .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Tutorial overlay (conditional)
            if gameViewModel.showTutorial {
                EquationTutorialOverlayView(gameViewModel: gameViewModel)
            }
            
            // Completion overlay (conditional)
            if gameViewModel.gameState == .completed {
                CompletionOverlayView(
                    score: gameViewModel.score,
                    puzzlesSolved: gameViewModel.currentLevel - 1,
                    timeUsed: gameViewModel.gameTime,
                    onDismiss: {
                        gameViewModel.cleanup()
                        onComplete?(gameViewModel.score)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .onAppear {
            ARPuzzleGameViewModel.checkCameraAuthorization()
        }
        .onDisappear {
            gameViewModel.cleanup()
        }
    }
}

// AR View Container remains the same
struct ARPuzzleViewContainer: UIViewRepresentable {
    var viewModel: ARPuzzleGameViewModel
    
    func makeUIView(context: Context) -> ARView {
        viewModel.arView = ARView(frame: .zero)
        
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.planeDetection = [.horizontal]
        viewModel.arView.session.run(arConfiguration)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = viewModel.arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.delegate = context.coordinator
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        viewModel.arView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: viewModel.arView.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: viewModel.arView.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: viewModel.arView.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: viewModel.arView.heightAnchor)
        ])
        
        viewModel.setupPlaneDetection()
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        viewModel.arView.addGestureRecognizer(tapGesture)
        
        return viewModel.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARCoachingOverlayViewDelegate {
        var parent: ARPuzzleViewContainer
        init(_ parent: ARPuzzleViewContainer) {
            self.parent = parent
        }
        
        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            parent.viewModel.isPlaneDetected = true
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard parent.viewModel.gameState == .playing else { return }
            let tapLocation = sender.location(in: parent.viewModel.arView)
            parent.viewModel.handleTap(at: tapLocation)
        }
    }
}

// Equation Tutorial overlay view
struct EquationTutorialOverlayView: View {
    @ObservedObject var gameViewModel: ARPuzzleGameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Text("Equation Builder en AR")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Image(systemName: "plus.slash.minus")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 15) {
                    TutorialStepView(
                        icon: "1.square.fill",
                        title: "Escanear",
                        description: "Apunta la cámara a una superficie plana hasta que aparezca un plano."
                    )
                    TutorialStepView(
                        icon: "2.square.fill",
                        title: "Recolectar",
                        description: "Toca los elementos de la ecuación en el orden correcto."
                    )
                    TutorialStepView(
                        icon: "3.square.fill",
                        title: "Resolver",
                        description: "Al tocar todos los elementos correctamente, habrás resuelto la ecuación."
                    )
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        gameViewModel.showTutorial = false
                        gameViewModel.gameState = .scanning
                    }
                }) {
                    Text("Comenzar")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(30)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 20)
            }
            .padding(.vertical, 40)
        }
    }
}

// A generic tutorial step (unchanged)
struct TutorialStepView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.blue)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
                Text(description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Completion overlay view (unchanged)
struct CompletionOverlayView: View {
    let score: Int
    let puzzlesSolved: Int
    let timeUsed: Int
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                }
                .padding(.top, 30)
                Text("¡Rompecabezas Completado!")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                Text("Has demostrado excelentes habilidades al resolver el puzzle.")
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Puntuación: \(score) XP")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(.blue)
                        Text("Niveles completados: \(puzzlesSolved)")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                        Text("Tiempo: \(formatTime(timeUsed))")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                Button(action: onDismiss) {
                    Text("Regresar al inicio")
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
            .background(Color.black.opacity(0.6))
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(remainingSeconds < 10 ? "0" : "")\(remainingSeconds)"
    }
}

// MARK: - ARPuzzleGameViewModel with Equation Builder Logic
class ARPuzzleGameViewModel: ObservableObject {
    enum GameState {
        case tutorial, scanning, playing, levelCompleted, completed
    }
    
    // Each equation part is represented by a text plate
    struct EquationPart {
        let id: UUID
        let text: String
        let modelEntity: ModelEntity
        var isCollected: Bool = false
    }
    
    @Published var gameState: GameState = .tutorial
    @Published var showTutorial: Bool = true
    @Published var isPlaneDetected: Bool = false
    @Published var score: Int = 0
    @Published var currentLevel: Int = 1
    @Published var statusMessage: String = "Escanea una superficie plana"
    @Published var gameTime: Int = 0
    
    // Equation puzzle properties
    private var equationParts: [EquationPart] = []
    @Published var collectedParts: [String] = []
    private var targetEquationParts: [String] = []
    private var nextExpectedIndex: Int = 0
    
    var arView: ARView!
    private var puzzleAnchor: AnchorEntity?
    private var gameTimer: Timer?
    private var planeSubscription: Cancellable?
    
    init() { }
    
    func cleanup() {
        gameTimer?.invalidate()
        planeSubscription?.cancel()
        arView?.session.pause()
    }
    
    func setupPlaneDetection() {
        guard let arView = arView else { return }
        planeSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            guard let self = self else { return }
            if self.gameState == .scanning && !self.isPlaneDetected {
                let planes = arView.session.currentFrame?.anchors.compactMap { $0 as? ARPlaneAnchor }
                if let planes = planes, !planes.isEmpty {
                    self.isPlaneDetected = true
                    self.statusMessage = "Superficie detectada. Pulsa 'Iniciar' para comenzar."
                }
            }
        }
    }
    
    func startGame() {
        guard isPlaneDetected, gameState == .scanning else { return }
        gameState = .playing
        statusMessage = "Resuelve la ecuación: Toca los elementos en el orden correcto"
        setupEquationPuzzle(level: currentLevel)
        startTimer()
    }
    
    // Set up an equation puzzle. For each level, choose a target equation.
    private func setupEquationPuzzle(level: Int) {
        guard let arView = arView else { return }
        clearCurrentPuzzle()
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)
        puzzleAnchor = anchor
        
        // Choose target equation parts based on level
        switch level {
        case 1:
            targetEquationParts = ["3", "+", "4", "=", "7"]
        case 2:
            targetEquationParts = ["5", "-", "2", "=", "3"]
        case 3:
            targetEquationParts = ["2", "*", "3", "=", "6"]
        default:
            targetEquationParts = ["1", "+", "1", "=", "2"]
        }
        nextExpectedIndex = 0
        collectedParts = []
        statusMessage = "Toca en: \(targetEquationParts.joined(separator: " "))"
        equationParts = []
        
        // Scatter each equation part at a random position near the anchor
        for part in targetEquationParts {
            let textMesh = MeshResource.generateText(part,
                                                     extrusionDepth: 0.005,
                                                     font: .systemFont(ofSize: 0.1),
                                                     containerFrame: .zero,
                                                     alignment: .center,
                                                     lineBreakMode: .byWordWrapping)
            let textEntity = ModelEntity(mesh: textMesh)
            // Give a material so the text is visible
            let material = SimpleMaterial(color: .white, isMetallic: false)
            textEntity.model?.materials = [material]
            textEntity.generateCollisionShapes(recursive: true)
            
            // Random offset within a range
            let randomX = Float.random(in: -0.3...0.3)
            let randomZ = Float.random(in: -0.3...0.3)
            textEntity.position = SIMD3<Float>(randomX, 0.05, randomZ)
            
            let eqPart = EquationPart(id: UUID(), text: part, modelEntity: textEntity, isCollected: false)
            equationParts.append(eqPart)
            anchor.addChild(textEntity)
        }
    }
    
    // When user taps in AR, check if an equation part was tapped
    func handleTap(at location: CGPoint) {
        guard let arView = arView, gameState == .playing else { return }
        let hitResults = arView.hitTest(location)
        if let result = hitResults.first, let entity = result.entity as? ModelEntity {
            if let index = equationParts.firstIndex(where: { $0.modelEntity == entity && !$0.isCollected }) {
                // Check if the tapped part is the next expected one
                let tappedPart = equationParts[index]
                if tappedPart.text == targetEquationParts[nextExpectedIndex] {
                    // Correct; mark as collected and animate removal
                    equationParts[index].isCollected = true
                    collectedParts.append(tappedPart.text)
                    nextExpectedIndex += 1
                    animateCollectedPart(entity: tappedPart.modelEntity)
                    // Check if complete
                    if nextExpectedIndex == targetEquationParts.count {
                        handleLevelCompletion()
                    }
                } else {
                    // Incorrect order – reset collected parts
                    statusMessage = "Orden incorrecto. Intenta de nuevo: \(targetEquationParts.joined(separator: " "))"
                    resetEquationPuzzle()
                }
            }
        }
    }
    
    private func animateCollectedPart(entity: ModelEntity) {
        // Animate the entity moving down to indicate collection
        var newTransform = entity.transform
        newTransform.translation.y -= 0.1
        entity.move(to: newTransform, relativeTo: entity.parent, duration: 0.3)
    }
    
    // Reset the equation puzzle if the user taps the wrong part
    private func resetEquationPuzzle() {
        nextExpectedIndex = 0
        collectedParts = []
        // Reset each equation part (if already collected, re-add it)
        for i in 0..<equationParts.count {
            if equationParts[i].isCollected {
                equationParts[i].isCollected = false
                // Optionally, animate it back to its original position (for simplicity, we simply re-add it)
                if let anchor = puzzleAnchor {
                    anchor.addChild(equationParts[i].modelEntity)
                }
            }
        }
    }
    
    private func handleLevelCompletion() {
        gameState = .levelCompleted
        let levelScore = calculateLevelScore()
        score += levelScore
        statusMessage = "¡Nivel \(currentLevel) completado! +\(levelScore) XP"
        celebrateEquationCompletion()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if self.currentLevel >= 3 {
                self.completeGame()
            } else {
                self.currentLevel += 1
                self.gameState = .playing
                self.statusMessage = "Toca en: \(self.targetEquationParts.joined(separator: " "))"
                self.setupEquationPuzzle(level: self.currentLevel)
            }
        }
    }
    
    private func calculateLevelScore() -> Int {
        let baseScore = 50 * currentLevel
        let timeBonus = max(0, 30 - min(30, gameTime / 10)) * 5
        return baseScore + timeBonus
    }
    
    private func celebrateEquationCompletion() {
        guard let anchor = puzzleAnchor else { return }
        // For remaining parts (if any), animate a glow effect
        for part in equationParts {
            if !part.isCollected {
                let material = SimpleMaterial(color: .yellow, isMetallic: true)
                part.modelEntity.model?.materials = [material]
                let originalTransform = part.modelEntity.transform
                let scaleUp = Transform(
                    scale: [originalTransform.scale.x * 1.2,
                            originalTransform.scale.y * 1.2,
                            originalTransform.scale.z * 1.2],
                    rotation: originalTransform.rotation,
                    translation: originalTransform.translation
                )
                part.modelEntity.move(to: scaleUp, relativeTo: anchor, duration: 0.3)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    part.modelEntity.move(to: originalTransform, relativeTo: anchor, duration: 0.3)
                }
            }
        }
    }
    
    private func completeGame() {
        gameState = .completed
        gameTimer?.invalidate()
        statusMessage = "¡Puzzle completado! 🎉"
    }
    
    func resetCurrentPuzzle() {
        guard gameState == .playing else { return }
        // Remove all equation parts and re-create the puzzle
        for part in equationParts {
            part.modelEntity.removeFromParent()
        }
        setupEquationPuzzle(level: currentLevel)
        statusMessage = "Toca en: \(targetEquationParts.joined(separator: " "))"
    }
    
    private func startTimer() {
        gameTime = 0
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.gameTime += 1
        }
    }
    
    func showHint() {
        guard gameState == .playing else { return }
        statusMessage = "Pista: Toca primero '\(targetEquationParts[nextExpectedIndex])'"
        // Briefly animate the expected part if possible
        if let expectedPart = equationParts.first(where: { !$0.isCollected && $0.text == targetEquationParts[nextExpectedIndex] }) {
            let originalScale = expectedPart.modelEntity.scale
            let scaleUp = Transform(
                scale: [originalScale.x * 1.2, originalScale.y * 1.2, originalScale.z * 1.2],
                rotation: expectedPart.modelEntity.orientation,
                translation: expectedPart.modelEntity.position
            )
            expectedPart.modelEntity.move(to: scaleUp, relativeTo: expectedPart.modelEntity.parent, duration: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                expectedPart.modelEntity.move(
                    to: Transform(scale: originalScale,
                                  rotation: expectedPart.modelEntity.orientation,
                                  translation: expectedPart.modelEntity.position),
                    relativeTo: expectedPart.modelEntity.parent,
                    duration: 0.3
                )
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.statusMessage = "Toca en: \(self.targetEquationParts.joined(separator: " "))"
        }
    }
    
    private func clearCurrentPuzzle() {
        equationParts = []
        if let anchor = puzzleAnchor {
            arView.scene.removeAnchor(anchor)
            puzzleAnchor = nil
        }
    }
    
    static func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted { print("Camera access denied") }
            }
        case .denied, .restricted:
            print("Camera access denied")
        @unknown default:
            break
        }
    }
}

// Extensions for HomeView and UserDataManager remain unchanged
extension UserDataManager {
    func addARPuzzleGame() {
        if availableQuests.contains(where: { $0.title == "Rompecabezas 3D en AR" }) {
            return
        }
        let arPuzzleQuest = Quest(
            title: "Rompecabezas 3D en AR",
            description: "Resuelve puzzles en AR para mejorar tus habilidades matemáticas y espaciales",
            xpReward: 200,
            duration: 20,
            difficulty: .intermediate,
            learningStyles: ["visual", "kinesthetic"],
            iconName: "cube.transparent",
            isCompleted: false,
            completionPercentage: 0.0,
            destination: AnyView(ARPuzzleGameView(onComplete: { score in
                self.userProfile.xpPoints += score
                self.userProfile.dailyProgress += score
                self.saveUserData()
                self.markQuestAsCompleted("Rompecabezas 3D en AR")
            })),
            isRecommended: false,
            recommendationReason: ""
        )
        availableQuests.append(arPuzzleQuest)
        
        if (userProfile.learningStyles.contains("visual") || userProfile.learningStyles.contains("kinesthetic")),
           !isQuestCompleted("Rompecabezas 3D en AR") {
            let shouldReplace = suggestedQuest == nil ||
                                (!suggestedQuest!.learningStyles.contains("visual") &&
                                 !suggestedQuest!.learningStyles.contains("kinesthetic"))
            if shouldReplace {
                var suggestedCopy = arPuzzleQuest
                suggestedCopy.isRecommended = true
                if userProfile.learningStyles.contains("visual") {
                    suggestedCopy.recommendationReason = "Perfecto para tu estilo de aprendizaje visual"
                } else {
                    suggestedCopy.recommendationReason = "Ideal para tu estilo de aprendizaje kinestésico"
                }
                suggestedQuest = suggestedCopy
            }
        }
        
        saveUserData()
    }
}

extension HomeView {
    func addARPuzzleGameToHomeView() {
        UserDataManager.shared.addARPuzzleGame()
    }
}

struct ARPuzzleGameView_Previews: PreviewProvider {
    static var previews: some View {
        ARPuzzleGameView()
    }
}
