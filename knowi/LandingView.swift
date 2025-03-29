import SwiftUI

struct FloatingBubble: View {
    let size: CGFloat
    let offset: CGPoint
    let color: Color
    let animationDuration: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .offset(x: offset.x + (isAnimating ? 15 : -15),
                    y: offset.y + (isAnimating ? 10 : -10))
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct LandingView: View {
    @State private var isAppearing = false
    @State private var isButtonAnimating = false
    @State private var isTextAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated floating bubbles
            ZStack {
                FloatingBubble(size: 120, offset: CGPoint(x: -100, y: -200), color: .white, animationDuration: 4)
                FloatingBubble(size: 80, offset: CGPoint(x: 120, y: -150), color: .purple, animationDuration: 3.5)
                FloatingBubble(size: 150, offset: CGPoint(x: 140, y: 200), color: .blue, animationDuration: 5)
                FloatingBubble(size: 50, offset: CGPoint(x: -130, y: 180), color: .white, animationDuration: 4.2)
                FloatingBubble(size: 70, offset: CGPoint(x: 0, y: 100), color: .purple, animationDuration: 3.8)
            }
            .opacity(0.4)
            
            // Content
            VStack(spacing: 32) {
                Spacer()
                
                // Logo image with animation
                Image("wizardKitty")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    .offset(y: isAppearing ? 40 : -40)
                    .opacity(isAppearing ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAppearing)
                
                // App name with glow and animation
                Text("KnowQuest")
                    .font(.custom("Poppins-Bold", size: 42))
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.8), radius: 10, x: 0, y: 0)
                    .scaleEffect(isTextAnimating ? 1.03 : 1)
                    .opacity(isAppearing ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.3), value: isAppearing)
                    .animation(
                        Animation.easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                        value: isTextAnimating
                    )
                
                // Tagline
                Text("Embark on a magical journey of knowledge")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(isAppearing ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: isAppearing)
                
                Spacer()
                
                // Button with pulse animation
                Button(action: {
                    // Navigate to next view
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.white)
                            .frame(height: 60)
                            .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
                            .scaleEffect(isButtonAnimating ? 1.03 : 1)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isButtonAnimating
                            )
                        
                        Text("Empezar")
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundColor(Color.blue)
                    }
                    .padding(.horizontal, 80)
                    .offset(y: 60)
                }
                .opacity(isAppearing ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.7), value: isAppearing)
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            // Start animations with slight delay for better effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAppearing = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isButtonAnimating = true
                    isTextAnimating = true
                }
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
