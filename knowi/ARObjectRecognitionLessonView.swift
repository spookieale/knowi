//
//  ARObjectRecognitionLessonView.swift
//  knowi
//
//  Created by Alumno on 29/03/25.
//

import SwiftUI
import ARKit
import RealityKit

// Modelo para los conceptos de la lección
struct ARConcept: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let image: String
    var isCompleted: Bool = false
}

// Modelo para los objetos a reconocer
struct RecognizableObject: Identifiable {
    let id = UUID()
    let name: String
    let targetImage: String
    let description: String
    var isRecognized: Bool = false
}

class ARObjectLessonManager: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: Int = 0
    @Published var isLessonCompleted: Bool = false
    @Published var xpEarned: Int = 0
    @Published var concepts: [ARConcept] = []
    @Published var objectsToRecognize: [RecognizableObject] = []
    @Published var showObjectFoundAnimation: Bool = false
    @Published var lastFoundObject: String = ""
    
    let totalSteps = 5
    let totalXP = 200
    
    init() {
        loadConcepts()
        loadObjects()
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
                description: "ARKit puede reconocer objetos del mundo real que han sido previamente escaneados o configurados en la aplicación.",
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
    
    func loadObjects() {
        objectsToRecognize = [
            RecognizableObject(
                name: "Libro",
                targetImage: "book-target",
                description: "Los libros son detectados por su forma rectangular y portada. ARKit puede reconocer libros específicos si se han entrenado previamente."
            ),
            RecognizableObject(
                name: "Taza",
                targetImage: "cup-target",
                description: "Las tazas son reconocidas por su forma cilíndrica con asa. ARKit detecta sus bordes y contorno característico."
            ),
            RecognizableObject(
                name: "Teléfono",
                targetImage: "phone-target",
                description: "Los teléfonos son fácilmente reconocibles por su forma rectangular y pantalla. ARKit puede detectar sus bordes definidos."
            ),
            RecognizableObject(
                name: "Planta",
                targetImage: "plant-target",
                description: "Las plantas se reconocen por su forma orgánica y color verde característico. ARKit puede detectar las hojas y el contorno."
            )
        ]
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
        
        // Actualizar XP ganado proporcional al progreso
        xpEarned = Int(Double(totalXP) * progress)
    }
    
    func objectRecognized(objectName: String) {
        if let index = objectsToRecognize.firstIndex(where: { $0.name == objectName && !$0.isRecognized }) {
            objectsToRecognize[index].isRecognized = true
            lastFoundObject = objectName
            
            // Mostrar animación de objeto encontrado
            withAnimation {
                showObjectFoundAnimation = true
            }
            
            // Ocultar animación después de 3 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.showObjectFoundAnimation = false
                }
            }
            
            // Comprobar si todos los objetos han sido reconocidos
            checkAllObjectsRecognized()
        }
    }
    
    func checkAllObjectsRecognized() {
        let allRecognized = objectsToRecognize.allSatisfy { $0.isRecognized }
        if allRecognized {
            // Si estamos en el paso de reconocimiento (paso 3), pasar al siguiente
            if currentStep == 2 {
                nextStep()
            }
        }
    }
    
    func markConceptComplete(at index: Int) {
        if index < concepts.count {
            concepts[index].isCompleted = true
        }
    }
    
    func completeLessonIfPossible() {
        // Comprobar si se han completado todos los requisitos
        let allConceptsCompleted = concepts.allSatisfy { $0.isCompleted }
        let allObjectsRecognized = objectsToRecognize.allSatisfy { $0.isRecognized }
        
        if allConceptsCompleted && allObjectsRecognized {
            isLessonCompleted = true
            progress = 1.0
            xpEarned = totalXP
            
            // Actualizar perfil del usuario con el XP ganado
            updateUserProfile()
        }
    }
    
    func updateUserProfile() {
        let userManager = UserDataManager.shared
        userManager.userProfile.xpPoints += xpEarned
        userManager.userProfile.dailyProgress += xpEarned
        userManager.saveUserData()
    }
    
    func resetLesson() {
        currentStep = 0
        progress = 0.0
        isLessonCompleted = false
        xpEarned = 0
        
        // Resetear conceptos
        for i in 0..<concepts.count {
            concepts[i].isCompleted = false
        }
        
        // Resetear objetos
        for i in 0..<objectsToRecognize.count {
            objectsToRecognize[i].isRecognized = false
        }
    }
}

// Componente de barra de progreso específico para la lección de AR
struct ARLessonProgressBar: View {
    var value: Double
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .cornerRadius(4)
            
            Rectangle()
                .foregroundColor(Color.blue)
                .cornerRadius(4)
                .frame(width: max(0, CGFloat(value) * UIScreen.main.bounds.width - 32))
                .animation(.easeInOut, value: value)
        }
    }
}

// Tarjeta de aplicación práctica
struct PracticeCard: View {
    var title: String
    var description: String
    var iconName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icono
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Vista principal de la lección
struct ARObjectRecognitionLessonView: View {
    @StateObject private var lessonManager = ARObjectLessonManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCompletionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra de navegación personalizada
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
                    
                    // Botón de ayuda
                    Button(action: {
                        // Mostrar ayuda
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                // Título centrado
                Text("Reconocimiento de Objetos AR")
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
            
            // Barra de progreso
            ARLessonProgressBar(value: lessonManager.progress)
                .frame(height: 8)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Contenido principal de la lección
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Contenido basado en el paso actual
                    switch lessonManager.currentStep {
                    case 0:
                        IntroductionStepView(lessonManager: lessonManager)
                    case 1:
                        ConceptsStepView(lessonManager: lessonManager)
                    case 2:
                        ObjectRecognitionStepView(lessonManager: lessonManager)
                    case 3:
                        PracticeStepView(lessonManager: lessonManager)
                    case 4:
                        ARLessonSummaryView(lessonManager: lessonManager)
                    default:
                        EmptyView()
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            
            // Botones de navegación
            HStack {
                // Botón Anterior
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
                
                // Botón Siguiente o Completar
                Button(action: {
                    if lessonManager.currentStep == lessonManager.totalSteps - 1 {
                        // Completar lección
                        lessonManager.completeLessonIfPossible()
                        showCompletionAlert = true
                    } else {
                        // Avanzar al siguiente paso
                        lessonManager.nextStep()
                    }
                }) {
                    HStack {
                        Text(lessonManager.currentStep == lessonManager.totalSteps - 1 ? "Completar" : "Siguiente")
                        Image(systemName: lessonManager.currentStep == lessonManager.totalSteps - 1 ? "checkmark" : "arrow.right")
                    }
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $showCompletionAlert) {
            Alert(
                title: Text("¡Felicidades!"),
                message: Text("Has completado la lección de Reconocimiento de Objetos en AR y has ganado \(lessonManager.xpEarned) XP."),
                dismissButton: .default(Text("Volver al Inicio")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            // Inicializar la lección
        }
    }
}

// Vista del paso 1: Introducción
struct IntroductionStepView: View {
    @ObservedObject var lessonManager: ARObjectLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Introducción al Reconocimiento de Objetos en AR")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Image(systemName: "cube.transparent")
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
                LearningPoint(text: "Qué es el reconocimiento de objetos en Realidad Aumentada")
                LearningPoint(text: "Cómo ARKit identifica objetos del mundo real")
                LearningPoint(text: "Cómo crear interacciones basadas en objetos reconocidos")
                LearningPoint(text: "Aplicaciones prácticas de esta tecnología")
            }
            
            Text("Esta lección combina teoría y práctica. Tendrás la oportunidad de usar la cámara de tu dispositivo para identificar objetos comunes y ver cómo la tecnología AR puede enriquecer tu interacción con ellos.")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.top, 10)
            
            Text("Al completar esta lección ganarás \(lessonManager.totalXP) XP y desbloquearás nuevas misiones relacionadas con AR.")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.blue)
                .padding(.top, 10)
        }
    }
}

// Componente para puntos de aprendizaje
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

// Vista del paso 2: Conceptos
struct ConceptsStepView: View {
    @ObservedObject var lessonManager: ARObjectLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Conceptos Clave")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Text("Familiarízate con estos conceptos fundamentales antes de pasar a la práctica:")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
            
            // Lista de conceptos
            ForEach(0..<lessonManager.concepts.count, id: \.self) { index in
                ConceptCard(
                    concept: lessonManager.concepts[index],
                    index: index,
                    isCompleted: lessonManager.concepts[index].isCompleted,
                    onComplete: {
                        // Marcar concepto como completado
                        lessonManager.markConceptComplete(at: index)
                    }
                )
            }
        }
    }
}

// Tarjeta de concepto
struct ConceptCard: View {
    var concept: ARConcept
    var index: Int
    var isCompleted: Bool
    var onComplete: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Encabezado de la tarjeta
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
            
            // Contenido expandible
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

// Vista del paso 3: Reconocimiento de Objetos
struct ObjectRecognitionStepView: View {
    @ObservedObject var lessonManager: ARObjectLessonManager
    @State private var showARView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Reconocimiento de Objetos")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Text("Ahora vamos a practicar el reconocimiento de objetos. Busca estos objetos en tu entorno y apunta con la cámara para reconocerlos:")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
            
            // Lista de objetos a reconocer
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(lessonManager.objectsToRecognize) { object in
                    ObjectCard(object: object)
                }
            }
            
            // Botón para activar la cámara AR
            Button(action: {
                showARView = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Iniciar Reconocimiento")
                }
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 10)
            
            // Instrucciones adicionales
            Text("Consejos para el reconocimiento:")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.black)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 10) {
                TipItem(tip: "Asegúrate de tener buena iluminación")
                TipItem(tip: "Mantén el objeto centrado en la pantalla")
                TipItem(tip: "Muévete lentamente alrededor del objeto")
                TipItem(tip: "Intenta mostrar diferentes ángulos del objeto")
            }
        }
        .sheet(isPresented: $showARView) {
            ARObjectRecognitionView(lessonManager: lessonManager)
        }
        
        // Animación de objeto encontrado
        if lessonManager.showObjectFoundAnimation {
            ObjectFoundAnimation(objectName: lessonManager.lastFoundObject)
        }
    }
}

// Tarjeta de objeto
struct ObjectCard: View {
    var object: RecognizableObject
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                Image(systemName: "cube.box")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .padding()
                    .foregroundColor(.blue)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(object.isRecognized ? 0.6 : 1.0)
                
                if object.isRecognized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
            }
            
            Text(object.name)
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.black)
            
            Text(object.isRecognized ? "¡Encontrado!" : "Pendiente")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(object.isRecognized ? .green : .orange)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(object.isRecognized ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// Componente para tips
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

// Vista AR para reconocimiento de objetos
struct ARObjectRecognitionView: View {
    @ObservedObject var lessonManager: ARObjectLessonManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Simulación de vista AR (en una app real, aquí iría ARViewContainer)
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Interfaz de usuario superpuesta
            VStack {
                HStack {
                    Button(action: {
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
                }
                
                Spacer()
                
                // Barra inferior con instrucciones
                VStack(spacing: 15) {
                    Text("Busca objetos para reconocer")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                    
                    Text("Apunta la cámara hacia alguno de los objetos de la lista")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    // Botones de prueba para simular reconocimiento
                    // En una app real, estos botones serían reemplazados por detección real
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(lessonManager.objectsToRecognize) { object in
                                Button(action: {
                                    lessonManager.objectRecognized(objectName: object.name)
                                }) {
                                    Text("Simular: \(object.name)")
                                        .font(.custom("Poppins-Regular", size: 14))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                }
                                .disabled(object.isRecognized)
                                .opacity(object.isRecognized ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
    }
}

// Animación cuando se encuentra un objeto
struct ObjectFoundAnimation: View {
    var objectName: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("¡\(objectName) Encontrado!")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.white)
            
            Text("+25 XP")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.yellow)
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
    }
}

// Vista del paso 4: Práctica interactiva
struct PracticeStepView: View {
    @ObservedObject var lessonManager: ARObjectLessonManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Aplicaciones Prácticas")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.black)
            
            Text("Ahora que has aprendido a reconocer objetos en AR, veamos algunas aplicaciones prácticas:")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
            
            // Aplicaciones prácticas en tarjetas
            VStack(spacing: 15) {
                PracticeCard(
                    title: "Educación",
                    description: "Reconocer objetos y mostrar información adicional sobre ellos para ayudar en el aprendizaje.",
                    iconName: "book.fill"
                )
                
                PracticeCard(
                                    title: "Navegación",
                                    description: "Reconocer puntos de referencia y proporcionar direcciones en entornos complejos.",
                                    iconName: "map.fill"
                                )
                                
                                PracticeCard(
                                    title: "Accesibilidad",
                                    description: "Ayudar a personas con discapacidad visual a identificar objetos y obstáculos.",
                                    iconName: "accessibility.fill"
                                )
                            }
                            
                            // Preguntas para reflexionar
                            Text("Reflexiona:")
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundColor(.black)
                                .padding(.top, 10)
                            
                            Text("¿Cómo podrías aplicar el reconocimiento de objetos en AR a tus propios proyectos o intereses?")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.gray)
                                .padding(.bottom, 20)
                            
                            // Campo de texto para respuesta
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: .constant(""))
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .frame(minHeight: 100)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Text("Escribe tu respuesta aquí...")
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .opacity(true ? 1 : 0) // En una implementación real, esto estaría vinculado al estado del TextEditor
                            }
                            
                            // Botón para enviar respuesta
                            Button(action: {
                                // Aquí se procesaría la respuesta
                            }) {
                                Text("Enviar respuesta")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                            .padding(.top, 10)
                        }
                    }
                }

                // Vista del paso 5: Resumen y conclusión
                struct ARLessonSummaryView: View {
                    @ObservedObject var lessonManager: ARObjectLessonManager
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Resumen y Conclusión")
                                .font(.custom("Poppins-Bold", size: 24))
                                .foregroundColor(.black)
                            
                            // Gráfico de progreso circular
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
                                SummaryPoint(text: "Fundamentos de ARKit y reconocimiento de objetos")
                                SummaryPoint(text: "Cómo reconocer objetos en tu entorno usando la cámara")
                                SummaryPoint(text: "Aplicaciones prácticas de esta tecnología")
                                SummaryPoint(text: "Cómo implementar AR en tus propios proyectos")
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
                            
                            // Botón compartir progreso
                            Button(action: {
                                // Acción para compartir progreso
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
                }

                // Componente para puntos de resumen
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

                // Tarjeta para próximos pasos
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
