//
//  AnimatedTextAdventureView.swift
//  knowi
//
//  Created on 29/03/25.
//

import SwiftUI

struct AnimatedTextAdventureView: View {
    // Story segments represent parts of the adventure.
    struct StorySegment {
        let text: String
        let choices: [Choice]
        let info: String? // extra educational info (optional)
    }
    struct Choice: Identifiable {
        let id = UUID()
        let text: String
        let nextSegment: Int? // if nil, the story ends
    }
    
    // A sample story about Ancient Egypt that teaches historical concepts.
    let segments: [StorySegment] = [
        StorySegment(
            text: "Bienvenido a tu aventura en el Antiguo Egipto. Hoy aprenderás sobre las pirámides y la escritura jeroglífica. ¿Qué te gustaría explorar primero?",
            choices: [
                Choice(text: "Las Pirámides", nextSegment: 1),
                Choice(text: "Jeroglíficos", nextSegment: 2)
            ],
            info: nil
        ),
        StorySegment(
            text: "Las pirámides no solo eran tumbas, sino obras maestras de ingeniería y matemáticas. Su construcción refleja un profundo conocimiento de la astronomía.",
            choices: [
                Choice(text: "Continuar", nextSegment: 3)
            ],
            info: "Estudiar las pirámides ayuda a comprender cómo se aplicaban principios matemáticos en la antigüedad."
        ),
        StorySegment(
            text: "Los jeroglíficos eran mucho más que un simple alfabeto; eran un sistema complejo que combinaba imágenes y sonidos para transmitir ideas.",
            choices: [
                Choice(text: "Continuar", nextSegment: 3)
            ],
            info: "Los jeroglíficos ofrecen una ventana a la cultura, la religión y la política del antiguo Egipto."
        ),
        StorySegment(
            text: "Ahora, responde: ¿Cuál era la principal función de las pirámides?",
            choices: [
                Choice(text: "Residencia de los faraones", nextSegment: 4),
                Choice(text: "Tumbas reales", nextSegment: 5),
                Choice(text: "Centros de comercio", nextSegment: 4)
            ],
            info: nil
        ),
        StorySegment(
            text: "Incorrecto. La respuesta correcta es que eran tumbas reales para los faraones. ¡Inténtalo de nuevo!",
            choices: [
                Choice(text: "Reintentar", nextSegment: 3)
            ],
            info: nil
        ),
        StorySegment(
            text: "¡Correcto! Las pirámides eran tumbas reales. Gracias a tu curiosidad, has descubierto aspectos esenciales de la civilización egipcia.",
            choices: [],
            info: "Este conocimiento te ayudará a entender cómo la tecnología y el arte se entrelazaban en la antigüedad."
        )
    ]
    
    @State private var currentSegmentIndex: Int = 0
    @State private var displayedText: String = ""
    @State private var isAnimatingText: Bool = true
    @State private var showChoices: Bool = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // A dynamic gradient background (adjust the colors in your Assets if needed)
            LinearGradient(
                gradient: Gradient(colors: [Color("AdventureStart"), Color("AdventureEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(Animation.linear(duration: 10).repeatForever(autoreverses: true), value: currentSegmentIndex)
            
            VStack(spacing: 20) {
                // Animated text container
                ScrollView {
                    Text(displayedText)
                        .font(.custom("Poppins-Regular", size: 24))
                        .foregroundColor(.black)
                        .padding()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 300)
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .shadow(radius: 5)
                
                // Optional extra info to reinforce learning
                if let info = segments[currentSegmentIndex].info, !info.isEmpty {
                    Text(info)
                        .font(.custom("Poppins-Italic", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Display choices when text animation is finished
                if showChoices {
                    ForEach(segments[currentSegmentIndex].choices) { choice in
                        Button(action: {
                            moveToSegment(choice.nextSegment)
                        }) {
                            Text(choice.text)
                                .font(.custom("Poppins-SemiBold", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(25)
                                .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startTextAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTextAnimation() {
        displayedText = ""
        isAnimatingText = true
        showChoices = false
        let fullText = segments[currentSegmentIndex].text
        var charIndex = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText.append(fullText[index])
                charIndex += 1
            } else {
                t.invalidate()
                isAnimatingText = false
                withAnimation(.easeIn(duration: 0.5)) {
                    showChoices = true
                }
            }
        }
    }
    
    private func moveToSegment(_ next: Int?) {
        guard let nextIndex = next else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            displayedText = ""
            showChoices = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentSegmentIndex = nextIndex
            startTextAnimation()
        }
    }
}

struct AnimatedTextAdventureView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedTextAdventureView()
    }
}
