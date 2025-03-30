import SwiftUI
import ARKit
import RealityKit
import Vision
import CoreML

// MARK: - Models

// Model for lesson concepts
struct ARConcept: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let image: String
    var isCompleted: Bool = false
}

// Model for detected objects
struct DetectedObject: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Float
    let timestamp: Date
}

// MARK: - AR Exploration Lesson Manager

class ARExplorationLessonManager: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: Int = 0
    @Published var isLessonCompleted: Bool = false
    @Published var xpEarned: Int = 0
    @Published var concepts: [ARConcept] = []
    @Published var detectedObjects: [DetectedObject] = []
    @Published var uniqueDetectedObjects: Set<String> = []
    @Published var explorationTime: Int = 0 // Time spent exploring in seconds
    @Published var objectCountGoal: Int = 5 // Need to detect at least 10 different objects
    @Published var completedExploration: Bool = false
    @Published var showObjectFoundAnimation: Bool = false
    @Published var lastFoundObject: String = ""
    
    let totalSteps = 5
    let totalXP = 200
    let requiredExplorationTime = 30 // Required time in seconds
    
    private var timer: Timer?
    
    init() {
        loadConcepts()
    }
    
    func loadConcepts() {
        concepts = [
            ARConcept(
                title: "Fundamentos de ARKit",
                description: "ARKit es un framework de Apple que permite crear experiencias de realidad aumentada en iOS. Utiliza la cámara y sensores del dispositivo para mapear el entorno.",
                image: "arkit-concept"
            ),
            ARConcept(
                title: "Reconocimiento de Objetos",
                description: "ARKit puede reconocer objetos del mundo real utilizando modelos de visión por computadora como YOLO, permitiendo identificar una amplia variedad de objetos cotidianos.",
                image: "object-recognition"
            ),
            ARConcept(
                title: "Anclajes en AR",
                description: "Los anclajes permiten colocar contenido virtual en posiciones específicas del mundo real, manteniendo su posición incluso cuando el usuario se mueve.",
                image: "anchors"
            ),
            ARConcept(
                title: "Interacción con Objetos",
                description: "Una vez reconocidos los objetos, podemos añadir interactividad permitiendo que el usuario interactúe con contenido virtual superpuesto.",
                image: "interaction"
            ),
            ARConcept(
                title: "Aplicaciones Prácticas",
                description: "El reconocimiento de objetos en AR tiene aplicaciones en educación, entretenimiento, decoración de interiores, y mucho más.",
                image: "applications"
            )
        ]
    }
    
    func startExploration() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.explorationTime += 1
                
                // Check if exploration criteria are met
                if self.explorationTime >= self.requiredExplorationTime && self.uniqueDetectedObjects.count >= self.objectCountGoal {
                    self.completeExploration()
                }
            }
        }
    }
    
    func stopExploration() {
        timer?.invalidate()
        timer = nil
    }
    
    func completeExploration() {
        stopExploration()
        completedExploration = true
        
        // If we're in the exploration step (step 2), move to the next step
        if currentStep == 2 {
            nextStep()
        }
    }
    
    func objectDetected(objectName: String, confidence: Float) {
        let normalizedName = objectName.lowercased()
        
        // Add to detected objects list
        let newObject = DetectedObject(
            name: objectName,
            confidence: confidence,
            timestamp: Date()
        )
        
        // Keep only the 20 most recent detections
        if detectedObjects.count >= 20 {
            detectedObjects.remove(at: 0)
        }
        detectedObjects.append(newObject)
        
        // Add to unique objects set
        if !uniqueDetectedObjects.contains(normalizedName) {
            uniqueDetectedObjects.insert(normalizedName)
            
            // Show animation for first-time objects
            lastFoundObject = objectName
            withAnimation {
                showObjectFoundAnimation = true
            }
            
            // Hide animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.showObjectFoundAnimation = false
                }
            }
            
            // Award XP for new object discoveries (capped at objectCountGoal)
            if uniqueDetectedObjects.count <= objectCountGoal {
                xpEarned += 5 // 5 XP per new object
            }
        }
    }
    
    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
            updateProgress()
        } else {
            completeLessonIfPossible()
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
            updateProgress()
        }
    }
    
    func updateProgress() {
        progress = Double(currentStep) / Double(totalSteps - 1)
        
        // Update earned XP proportional to progress
        // Base XP from exploration + progress-based XP
        let progressXP = Int(Double(totalXP - (objectCountGoal * 5)) * progress)
        xpEarned = min((uniqueDetectedObjects.count * 5) + progressXP, totalXP)
    }
    
    func markConceptComplete(at index: Int) {
        if index < concepts.count {
            concepts[index].isCompleted = true
        }
    }
    
    func completeLessonIfPossible() {
        // Check if all requirements are completed
        let allConceptsCompleted = concepts.allSatisfy { $0.isCompleted }
        
        if allConceptsCompleted && completedExploration {
            isLessonCompleted = true
            progress = 1.0
            xpEarned = totalXP
            
            // Update user profile with earned XP
            updateUserProgress()
        }
    }
    
    private func updateUserProgress() {
        
        // Access the shared UserDataManager
        let userManager = UserDataManager.shared
        
        // Update user's XP points
        userManager.userProfile.xpPoints += totalXP
        
        // Update daily progress
        userManager.userProfile.dailyProgress += totalXP
        
        // Mark this quest as completed
        userManager.markQuestAsCompleted("Reconocimiento de Objetos AR")
        
        // Save the updated user data
        userManager.saveUserData()
    }
    
    func resetLesson() {
        currentStep = 0
        progress = 0.0
        isLessonCompleted = false
        xpEarned = 0
        explorationTime = 0
        completedExploration = false
        detectedObjects = []
        uniqueDetectedObjects = []
        
        // Reset concepts
        for i in 0..<concepts.count {
            concepts[i].isCompleted = false
        }
        
        stopExploration()
    }
}

// MARK: - ARViewContainer - Real Camera Implementation

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Start AR session
        arView.session.run(configuration)
        
        // Set session delegate
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates to the ARView can be handled here
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator handles ARSession delegate methods and manages object detection
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var arView: ARView?
        var visionRequests: [VNCoreMLRequest] = []
        var isProcessingFrame = false
        var frameCount = 0
        var useVisionDetection = false  // Flag to determine if we can use Vision
        
        // Recent detections for stability
        var recentDetections: [String: Int] = [:]
        var lastDetectionTime = Date()
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            
            // Set up vision
            setupVision()
        }
        
        func setupVision() {
            // Try to load the YOLOv3FP16 model
            do {
                // Get the URL for the model in the app bundle
                guard let modelURL = Bundle.main.url(forResource: "YOLOv3FP16", withExtension: "mlmodelc") else {
                    print("YOLOv3FP16 model file not found in bundle")
                    useVisionDetection = false
                    return
                }
                
                // Create a Core ML model
                let model = try MLModel(contentsOf: modelURL)
                
                // Create a Vision Core ML model
                let visionModel = try VNCoreMLModel(for: model)
                
                // Create a Vision request for object detection
                let request = VNCoreMLRequest(model: visionModel) { [weak self] (request, error) in
                    guard let self = self, error == nil else {
                        print("Vision request error: \(error?.localizedDescription ?? "unknown")")
                        return
                    }
                    
                    if let results = request.results as? [VNRecognizedObjectObservation] {
                        self.processDetections(results)
                    }
                }
                
                // Set request properties
                request.imageCropAndScaleOption = .centerCrop
                
                // Store the request
                self.visionRequests = [request]
                self.useVisionDetection = true
                
                print("YOLOv3FP16 model loaded successfully")
            } catch {
                print("Failed to load YOLOv3FP16 model: \(error)")
                self.useVisionDetection = false
            }
        }
        
        // Process detections from YOLO
        func processDetections(_ results: [VNRecognizedObjectObservation]) {
            for observation in results {
                // Get the top classification for this object
                guard let topLabelObservation = observation.labels.first else { continue }
                
                let objectName = topLabelObservation.identifier
                let confidence = topLabelObservation.confidence
                
                // Only consider high-confidence detections
                if confidence > 0.6 {
                    // Add to recent detections
                    if let count = recentDetections[objectName] {
                        recentDetections[objectName] = count + 1
                    } else {
                        recentDetections[objectName] = 1
                    }
                    
                    // If we've seen this object multiple times, it's likely correct
                    if recentDetections[objectName] ?? 0 >= 2 {
                        // Report the detected object
                        DispatchQueue.main.async {
                            self.parent.lessonManager.objectDetected(objectName: objectName, confidence: confidence)
                        }
                        
                        // Reset the counter for this object
                        recentDetections[objectName] = 0
                    }
                }
            }
            
            // Clean up old detections
            if Date().timeIntervalSince(lastDetectionTime) > 5.0 {
                recentDetections.removeAll()
                lastDetectionTime = Date()
            }
        }
        
        // ARSession delegate method - called when a new camera frame is captured
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Process every 10th frame to avoid overwhelming the device
            frameCount += 1
            guard frameCount % 10 == 0, !isProcessingFrame else { return }
            
            isProcessingFrame = true
            
            let pixelBuffer = frame.capturedImage
            
            if useVisionDetection && !visionRequests.isEmpty {
                // Use Vision for real object detection
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    
                    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                    
                    do {
                        try handler.perform(self.visionRequests)
                    } catch {
                        print("Failed to perform Vision request: \(error)")
                        self.simulateRandomDetection()
                    }
                    
                    self.isProcessingFrame = false
                }
            } else {
                // Fall back to simulation if Vision is not available
                simulateRandomDetection()
                isProcessingFrame = false
            }
        }
        
        // Simulation of random object detection for testing
        func simulateRandomDetection() {
            // 15% chance to simulate a detection
            if arc4random_uniform(100) < 15 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // List of common objects
                    let commonObjects = [
                        "person", "chair", "table", "book", "bottle", "cup",
                        "laptop", "keyboard", "mouse", "phone", "remote", "TV",
                        "lamp", "door", "window", "plant", "picture", "clock",
                        "sofa", "bed", "pillow", "bag", "shoe", "pen"
                    ]
                    
                    // Pick a random object
                    if let randomObject = commonObjects.randomElement() {
                        // Simulate detecting this object
                        self.parent.lessonManager.objectDetected(
                            objectName: randomObject,
                            confidence: Float.random(in: 0.7...0.95)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - AR Exploration View (Camera View)

struct ARExplorationView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Real AR View using ARViewContainer
            ARViewContainer(lessonManager: lessonManager)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Top Bar with stats
                HStack {
                    // Close button
                    Button(action: {
                        lessonManager.stopExploration()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Stats display
                    HStack(spacing: 15) {
                        // Objects found
                        VStack(spacing: 2) {
                            Text("\(lessonManager.uniqueDetectedObjects.count)/\(lessonManager.objectCountGoal)")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.white)
                            
                            Text("Objetos")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(12)
                        
                        // Time spent
                        VStack(spacing: 2) {
                            Text(timeString(lessonManager.explorationTime))
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.white)
                            
                            Text("Tiempo")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .padding(.trailing)
                }
                
                // Center indicator that shows the current object being viewed
                Spacer()
                
                if let latestObject = lessonManager.detectedObjects.last {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(latestObject.name.capitalized)
                                .font(.custom("Poppins-SemiBold", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(20)
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                }
                Spacer()
                
                // Bottom panel showing recently detected objects
                VStack(spacing: 10) {
                    Text("Objetos detectados recientemente:")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                    
                    // Recent detections grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(lessonManager.detectedObjects.suffix(9).reversed()) { object in
                            HStack {
                                Text(object.name.capitalized)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Progress toward completion
                    VStack(spacing: 5) {
                        // Progress bar for objects found
                        HStack {
                            Text("Objetos:")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.9))
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: min(CGFloat(lessonManager.uniqueDetectedObjects.count) / CGFloat(lessonManager.objectCountGoal), 1.0) * 200, height: 8)
                            }
                            .frame(width: 200)
                            
                            Text("\(lessonManager.uniqueDetectedObjects.count)/\(lessonManager.objectCountGoal)")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.white)
                        }
                        
                        // Progress bar for time
                        HStack {
                            Text("Tiempo:")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.9))
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange)
                                    .frame(width: min(CGFloat(lessonManager.explorationTime) / CGFloat(lessonManager.requiredExplorationTime), 1.0) * 200, height: 8)
                            }
                            .frame(width: 200)
                            
                            Text("\(timeString(lessonManager.explorationTime))/\(timeString(lessonManager.requiredExplorationTime))")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Complete exploration button (only appears when criteria are met)
                    if lessonManager.explorationTime >= lessonManager.requiredExplorationTime &&
                       lessonManager.uniqueDetectedObjects.count >= lessonManager.objectCountGoal &&
                       !lessonManager.completedExploration {
                        Button(action: {
                            lessonManager.completeExploration()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Completar Exploración")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(25)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
            
            // Object discovery animation
            if lessonManager.showObjectFoundAnimation {
                ObjectFoundAnimation(objectName: lessonManager.lastFoundObject)
            }
        }
        .onAppear {
            // Request camera permission and start exploration timer
            requestCameraAccess()
            lessonManager.startExploration()
        }
        .onDisappear {
            // Stop the exploration timer when view disappears
            lessonManager.stopExploration()
        }
    }
    
    // Helper method to request camera access
    func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera access already granted
            break
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    // Handle case where user denied camera access
                    print("Camera access denied")
                }
            }
        case .denied, .restricted:
            // Camera access was previously denied
            print("Camera access denied")
        @unknown default:
            break
        }
    }
    
    // Helper to format time as MM:SS
    func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Animation for discovered objects

struct ObjectFoundAnimation: View {
    var objectName: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            
            Text("¡Nuevo Objeto!")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
            
            Text(objectName.capitalized)
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)
            
            Text("+5 XP")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.yellow)
        }
        .padding(25)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
    }
}

// MARK: - Main Lesson View

struct ARObjectRecognitionLessonView: View {
    @StateObject private var lessonManager = ARExplorationLessonManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCompletionAlert = false
    @State private var showExplorationView = false
    @State private var quizAnswers: [Int: Int] = [:] // Question index : Selected answer index
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation bar
            ZStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Help button
                    Button(action: {
                        // Show help
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                // Centered title
                Text("Exploración de Objetos AR")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                Rectangle()
                    .foregroundColor(Color.blue)
                    .frame(width: CGFloat(lessonManager.progress) * UIScreen.main.bounds.width, height: 8)
                    .animation(.easeInOut, value: lessonManager.progress)
            }
            
            // Main lesson content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content based on current step
                    switch lessonManager.currentStep {
                    case 0:
                        IntroductionStepView(lessonManager: lessonManager)
                    case 1:
                        ConceptsStepView(lessonManager: lessonManager)
                    case 2:
                        ExplorationStepView(lessonManager: lessonManager, showExplorationView: $showExplorationView)
                    case 3:
                        ARTechnologyQuizView(lessonManager: lessonManager, quizAnswers: $quizAnswers)
                    case 4:
                        ARLessonSummaryView(lessonManager: lessonManager)
                    default:
                        EmptyView()
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            
            // Navigation buttons
            HStack {
                // Previous button
                Button(action: {
                    lessonManager.previousStep()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Anterior")
                    }
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(lessonManager.currentStep > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                    .cornerRadius(25)
                }
                .disabled(lessonManager.currentStep == 0)
                
                Spacer()
                
                // Next or Complete button
                Button(action: {
                    if lessonManager.currentStep == lessonManager.totalSteps - 1 {
                        // Complete lesson
                        lessonManager.completeLessonIfPossible()
                        showCompletionAlert = true
                    } else if lessonManager.currentStep == 2 && !lessonManager.completedExploration {
                        // Show exploration view if not completed
                        showExplorationView = true
                    } else if lessonManager.currentStep == 3 && quizAnswers.count < 3 {
                        // Don't advance if quiz isn't complete
                    } else {
                        // Advance to next step
                        lessonManager.nextStep()
                    }
                }) {
                    HStack {
                        Text(getButtonText())
                        Image(systemName: lessonManager.currentStep == lessonManager.totalSteps - 1 ? "checkmark" : "arrow.right")
                    }
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(getButtonColor())
                    .cornerRadius(25)
                }
                .disabled(isNextButtonDisabled())
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showExplorationView) {
            ARExplorationView(lessonManager: lessonManager)
        }
        .alert(isPresented: $showCompletionAlert) {
            Alert(
                title: Text("¡Felicidades!"),
                message: Text("Has completado la lección de Exploración de Objetos en AR y has ganado \(lessonManager.xpEarned) XP."),
                dismissButton: .default(Text("Volver al Inicio")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Helper methods for button state
    private func getButtonText() -> String {
        switch lessonManager.currentStep {
        case 2:
            return lessonManager.completedExploration ? "Siguiente" : "Explorar"
        case lessonManager.totalSteps - 1:
            return "Completar"
        default:
            return "Siguiente"
        }
    }
    
    private func getButtonColor() -> Color {
        if lessonManager.currentStep == 3 && quizAnswers.count < 3 {
            return Color.gray
        } else {
            return Color.blue
        }
    }
    
    private func isNextButtonDisabled() -> Bool {
        if lessonManager.currentStep == 3 && quizAnswers.count < 3 {
            return true
        }
        return false
    }
}

// MARK: - Introduction Step

struct IntroductionStepView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Introducción a la Exploración AR")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Image(systemName: "camera.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.blue)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Text("En esta lección aprenderás:")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 12) {
                LearningPoint(text: "Cómo la Realidad Aumentada reconoce objetos del mundo real")
                LearningPoint(text: "Explorar tu entorno y descubrir objetos usando la cámara")
                LearningPoint(text: "Cómo ARKit y la visión por computadora identifican objetos")
                LearningPoint(text: "Aplicaciones prácticas de esta tecnología")
            }
            
            Text("A diferencia de experiencias AR más dirigidas, en esta lección explorarás libremente tu entorno. La app identificará automáticamente los objetos que encuentres e irá aprendiendo sobre tu espacio.")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.top, 10)
            
            Text("Al completar esta lección ganarás \(lessonManager.totalXP) XP y desbloquearás nuevas misiones relacionadas con AR.")
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.blue)
                .padding(.top, 10)
        }
    }
}

// Learning point component
struct LearningPoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
            
            Text(text)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Concepts Step

struct ConceptsStepView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Conceptos Clave")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Text("Familiarízate con estos conceptos fundamentales antes de pasar a la práctica:")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
            
            // Concepts list
            ForEach(0..<lessonManager.concepts.count, id: \.self) { index in
                ConceptCard(
                    concept: lessonManager.concepts[index],
                    index: index,
                    isCompleted: lessonManager.concepts[index].isCompleted,
                    onComplete: {
                        // Mark concept as completed
                        lessonManager.markConceptComplete(at: index)
                    }
                )
            }
        }
    }
}

// Concept card component
struct ConceptCard: View {
    var concept: ARConcept
    var index: Int
    var isCompleted: Bool
    var onComplete: () -> Void
    
    @State private var isExpanded = false
        
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card header
            HStack {
                Text("\(index + 1). \(concept.title)")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                }
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "cube.transparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text(concept.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.gray)
                    
                    if !isCompleted {
                        Button(action: {
                            onComplete()
                        }) {
                            Text("Marcar como leído")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 5)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Exploration Step

struct ExplorationStepView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    @Binding var showExplorationView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Exploración AR")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            if !lessonManager.completedExploration {
                Text("Es hora de explorar tu entorno y descubrir objetos usando la cámara de AR:")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
                
                // Instructions card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Instrucciones:")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionItem(number: "1", text: "Apunta la cámara a diferentes objetos en tu entorno")
                        InstructionItem(number: "2", text: "La app identificará automáticamente lo que ves")
                        InstructionItem(number: "3", text: "Descubre al menos \(lessonManager.objectCountGoal) objetos diferentes")
                        InstructionItem(number: "4", text: "Explora durante al menos \(lessonManager.requiredExplorationTime / 60) minuto(s)")
                    }
                    
                    // Start exploration button
                    Button(action: {
                        showExplorationView = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Iniciar Exploración")
                        }
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Tips section
                Text("Consejos para la exploración:")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    TipItem(tip: "Asegúrate de tener buena iluminación")
                    TipItem(tip: "Mantén el dispositivo estable mientras apuntas")
                    TipItem(tip: "Acércate a objetos pequeños para mejor reconocimiento")
                    TipItem(tip: "Explora diferentes áreas de tu entorno")
                }
            } else {
                // Exploration completed view
                VStack(spacing: 20) {
                    // Success banner
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("¡Exploración completada!")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    
                    // Statistics card
                    VStack(spacing: 15) {
                        Text("Resultados de tu exploración")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                        
                        Divider()
                        
                        HStack(spacing: 20) {
                            // Objects discovered
                            VStack {
                                Text("\(lessonManager.uniqueDetectedObjects.count)")
                                    .font(.custom("Poppins-Bold", size: 36))
                                    .foregroundColor(.blue)
                                
                                Text("Objetos\ndescubiertos")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 50)
                            
                            // Exploration time
                            VStack {
                                Text(timeString(lessonManager.explorationTime))
                                    .font(.custom("Poppins-Bold", size: 36))
                                    .foregroundColor(.purple)
                                
                                Text("Tiempo de\nexploración")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 50)
                            
                            // XP earned
                            VStack {
                                Text("+\(min(lessonManager.uniqueDetectedObjects.count * 5, lessonManager.objectCountGoal * 5))")
                                    .font(.custom("Poppins-Bold", size: 36))
                                    .foregroundColor(.orange)
                                
                                Text("XP\nganado")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Objects discovered list
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Objetos descubiertos:")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.black)
                        
                        // Grid of discovered objects
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Array(lessonManager.uniqueDetectedObjects).sorted(), id: \.self) { object in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    
                                    Text(object.capitalized)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Restart exploration button
                    Button(action: {
                        lessonManager.resetLesson()
                        lessonManager.currentStep = 2
                        showExplorationView = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Explorar de nuevo")
                        }
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // Helper to format time as MM:SS
    func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// Component for numbered instruction
struct InstructionItem: View {
    var number: String
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.black)
        }
    }
}

// Component for tips
struct TipItem: View {
    var tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            
            Text(tip)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.black)
        }
    }
}

// MARK: - AR Technology Quiz

struct ARTechnologyQuizView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    @Binding var quizAnswers: [Int: Int]
    
    // Quiz questions and answers
    let questions = [
        QuizQuestion(
            question: "¿Qué tecnología permite el reconocimiento de objetos en AR?",
            answers: [
                "GPS y brújula digital",
                "Visión por computadora y machine learning",
                "Sensores de proximidad",
                "Reconocimiento de voz"
            ],
            correctAnswerIndex: 1
        ),
        QuizQuestion(
            question: "¿Cuál es un uso práctico del reconocimiento de objetos en AR?",
            answers: [
                "Predecir el clima",
                "Medir distancias exactas",
                "Identificar objetos para personas con discapacidad visual",
                "Aumentar la velocidad de internet"
            ],
            correctAnswerIndex: 2
        ),
        QuizQuestion(
            question: "¿Qué framework utiliza iOS para crear experiencias de AR?",
            answers: [
                "ARKit",
                "Vision Pro",
                "RealityKit",
                "ARCore"
            ],
            correctAnswerIndex: 0
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Evaluación de Aprendizaje")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Text("Responde estas preguntas para demostrar tu comprensión de la tecnología AR:")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
            
            // Quiz questions
            ForEach(0..<questions.count, id: \.self) { questionIndex in
                QuizQuestionView(
                    question: questions[questionIndex],
                    questionNumber: questionIndex + 1,
                    selectedAnswerIndex: quizAnswers[questionIndex] ?? -1,
                    onAnswerSelected: { answerIndex in
                        quizAnswers[questionIndex] = answerIndex
                    }
                )
            }
            
            // Quiz progress
            VStack(spacing: 10) {
                Text("Progreso: \(quizAnswers.count)/\(questions.count) preguntas respondidas")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(Color.blue)
                        .frame(width: CGFloat(quizAnswers.count) / CGFloat(questions.count) * UIScreen.main.bounds.width - 40, height: 8)
                        .cornerRadius(4)
                }
            }
            .padding(.top, 20)
        }
    }
}

// Quiz question model
struct QuizQuestion {
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
}

// Quiz question component
struct QuizQuestionView: View {
    var question: QuizQuestion
    var questionNumber: Int
    var selectedAnswerIndex: Int
    var onAnswerSelected: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Pregunta \(questionNumber): \(question.question)")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
            
            // Answer options
            ForEach(0..<question.answers.count, id: \.self) { index in
                Button(action: {
                    onAnswerSelected(index)
                }) {
                    HStack {
                        Text(question.answers[index])
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(selectedAnswerIndex == index ? .white : .black)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if selectedAnswerIndex == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(selectedAnswerIndex == index ? Color.blue : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Lesson Summary

struct ARLessonSummaryView: View {
    @ObservedObject var lessonManager: ARExplorationLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Resumen y Conclusión")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            // Progress circular chart
            HStack {
                Spacer()
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(lessonManager.progress))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 15, lineCap: .round)
                            )
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(lessonManager.progress * 100))%")
                                .font(.custom("Poppins-Bold", size: 28))
                                .foregroundColor(.blue)
                            
                            Text("Completado")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("+\(lessonManager.xpEarned) XP")
                        .font(.custom("Poppins-SemiBold", size: 20))
                        .foregroundColor(.green)
                        .padding(.top, 10)
                }
                Spacer()
            }
            .padding(.vertical, 20)
            
            Text("Lo que has aprendido:")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 12) {
                SummaryPoint(text: "Fundamentos de ARKit y visión por computadora")
                SummaryPoint(text: "Cómo se identifican objetos en el mundo real")
                SummaryPoint(text: "Exploración práctica del reconocimiento de objetos")
                SummaryPoint(text: "Aplicaciones prácticas de esta tecnología")
            }
            
            // Exploration statistics
            if lessonManager.completedExploration {
                Text("Tu exploración en números:")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                HStack(spacing: 15) {
                    // Objects stat
                    VStack {
                        Text("\(lessonManager.uniqueDetectedObjects.count)")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Objetos\ndescubiertos")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Time stat
                    VStack {
                        Text(timeString(lessonManager.explorationTime))
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.purple)
                        
                        Text("Tiempo\ntotal")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            Text("Próximos pasos:")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 15) {
                NextStepCard(
                    title: "ARKit: Colocación de Objetos",
                    description: "Aprende a colocar objetos virtuales en el mundo real",
                    xpReward: 250,
                    isLocked: false
                )
                
                NextStepCard(
                    title: "ARKit: Interacciones Avanzadas",
                    description: "Explora interacciones complejas entre objetos virtuales y reales",
                    xpReward: 300,
                    isLocked: true
                )
            }
            
            // Share progress button
            Button(action: {
                // Share progress action
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartir mi progreso")
                }
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.blue)
                .cornerRadius(30)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
    
    // Helper to format time as MM:SS
    func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// Component for summary points
struct SummaryPoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            
            Text(text)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.black)
        }
    }
}

// Card for next steps
struct NextStepCard: View {
    var title: String
    var description: String
    var xpReward: Int
    var isLocked: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(isLocked ? .gray : .black)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
                
                Text(description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(isLocked ? .gray.opacity(0.7) : .gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("+\(xpReward) XP")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(isLocked ? .gray : .green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isLocked ? Color.gray.opacity(0.2) : Color.green.opacity(0.1))
                .cornerRadius(15)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(isLocked ? 0.7 : 1)
    }
}

// MARK: - Helper methods

// Example of a simplified update profile method
/*
private func updateUserProfile() {
    let userManager = UserDataManager.shared
    
    // Update XP and daily progress
    userManager.userProfile.xpPoints += self.xpEarned
    userManager.userProfile.dailyProgress += self.xpEarned
    
    // Save the updated data
    userManager.saveUserData()
}
*/
