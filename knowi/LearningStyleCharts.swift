import SwiftUI

// Chart for learning style progress over time
struct LearningStyleChart: View {
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    let styleId: String
    
    private var chartData: [(date: String, score: Double)] {
        let history = analyzer.getHistoryForStyle(styleId: styleId)
        
        // Group by date and calculate average scores
        var groupedData: [String: [Double]] = [:]
        
        for point in history {
            if groupedData[point.dateString] == nil {
                groupedData[point.dateString] = []
            }
            groupedData[point.dateString]?.append(point.score)
        }
        
        // Calculate averages and sort by date
        let dateScorePairs = groupedData.map { (date, scores) in
            let averageScore = scores.reduce(0, +) / Double(scores.count)
            return (date: date, score: averageScore)
        }
        
        return dateScorePairs.sorted { $0.date < $1.date }
    }
    
    // Check if we have enough data to display
    private var hasEnoughData: Bool {
        return chartData.count >= 2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let style = analyzer.getPerformance(for: styleId) {
                HStack {
                    Image(systemName: style.icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                    
                    Text(style.name)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if style.completedQuests > 0 {
                        Text("\(style.completedQuests) misiones")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if hasEnoughData {
                // Chart visualization
                GeometryReader { geometry in
                    ZStack {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                Spacer()
                            }
                        }
                        
                        // Score values
                        HStack(spacing: 0) {
                            // Y-axis labels
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("100%")
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("75%")
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("50%")
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("25%")
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("0%")
                                    .font(.custom("Poppins-Regular", size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 30)
                            
                            // Chart area
                            ZStack {
                                // Line chart
                                Path { path in
                                    let chartWidth = geometry.size.width - 40
                                    let chartHeight = geometry.size.height
                                    let xStep = chartWidth / CGFloat(max(1, chartData.count - 1))
                                    
                                    for (index, point) in chartData.enumerated() {
                                        let x = CGFloat(index) * xStep + 30
                                        let y = chartHeight - (chartHeight * CGFloat(point.score / 100.0))
                                        
                                        if index == 0 {
                                            path.move(to: CGPoint(x: x, y: y))
                                        } else {
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                    }
                                }
                                .stroke(Color.blue, lineWidth: 2)
                                
                                // Data points
                                ForEach(0..<chartData.count, id: \.self) { index in
                                    let point = chartData[index]
                                    let chartWidth = geometry.size.width - 40
                                    let chartHeight = geometry.size.height
                                    let xStep = chartWidth / CGFloat(max(1, chartData.count - 1))
                                    let x = CGFloat(index) * xStep + 30
                                    let y = chartHeight - (chartHeight * CGFloat(point.score / 100.0))
                                    
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                        .position(x: x, y: y)
                                }
                                
                                // X-axis labels
                                VStack {
                                    Spacer()
                                    HStack(spacing: 0) {
                                        ForEach(0..<chartData.count, id: \.self) { index in
                                            let point = chartData[index]
                                            let chartWidth = geometry.size.width - 40
                                            let xStep = chartWidth / CGFloat(max(1, chartData.count - 1))
                                            let x = CGFloat(index) * xStep
                                            
                                            Text(point.date)
                                                .font(.custom("Poppins-Regular", size: 10))
                                                .foregroundColor(.gray)
                                                .frame(width: xStep)
                                                .offset(x: x)
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                }
                .frame(height: 150)
            } else {
                // Not enough data
                VStack {
                    Text("No hay suficientes datos para mostrar la gráfica")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(20)
                }
                .frame(height: 150)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// View to compare all learning styles in a single chart
struct ComparisonChartView: View {
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Comparación de Estilos")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
            
            // Style radar chart
            RadarChartView()
            
            // Progress over time
            Text("Progreso a lo largo del tiempo")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            // Individual style charts
            ForEach(analyzer.stylePerformances) { style in
                if analyzer.getHistoryForStyle(styleId: style.id).count > 0 {
                    LearningStyleChart(styleId: style.id)
                }
            }
        }
        .padding()
    }
}

// Radar chart for style comparison
struct RadarChartView: View {
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    
    // Get normalized scores for each style (0-1 range)
    private var normalizedScores: [String: Double] {
        var scores: [String: Double] = [:]
        
        for style in analyzer.stylePerformances {
            let completedFactor = min(1.0, Double(style.completedQuests) / 10.0)
            let scoreFactor = style.averageScore / 100.0
            
            // Weight completed quests (40%) and average score (60%)
            let normalizedScore = (completedFactor * 0.4) + (scoreFactor * 0.6)
            scores[style.id] = normalizedScore
        }
        
        return scores
    }
    
    private let radarPoints = 4
    private let radius: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Background rings
                ForEach(1...3, id: \.self) { ring in
                    let ringRadius = radius * CGFloat(ring) / 3.0
                    
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        .frame(width: ringRadius * 2, height: ringRadius * 2)
                        .position(center)
                }
                
                // Radar axes
                ForEach(0..<radarPoints, id: \.self) { i in
                    let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(radarPoints) - CGFloat.pi / 2
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        ))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
                
                // Style labels
                ForEach(0..<radarPoints, id: \.self) { i in
                    if i < analyzer.stylePerformances.count {
                        let style = analyzer.stylePerformances[i]
                        let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(radarPoints) - CGFloat.pi / 2
                        let labelPos = CGPoint(
                            x: center.x + cos(angle) * (radius + 15),
                            y: center.y + sin(angle) * (radius + 15)
                        )
                        
                        Text(style.name)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color.black)
                            .position(labelPos)
                    }
                }
                
                // Radar shape based on scores
                if !normalizedScores.isEmpty {
                    Path { path in
                        var firstPoint: CGPoint? = nil
                        
                        for i in 0..<radarPoints {
                            if i < analyzer.stylePerformances.count {
                                let style = analyzer.stylePerformances[i]
                                let score = normalizedScores[style.id] ?? 0
                                let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(radarPoints) - CGFloat.pi / 2
                                
                                let point = CGPoint(
                                    x: center.x + cos(angle) * radius * CGFloat(score),
                                    y: center.y + sin(angle) * radius * CGFloat(score)
                                )
                                
                                if i == 0 {
                                    path.move(to: point)
                                    firstPoint = point
                                } else {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        
                        if let firstPoint = firstPoint {
                            path.addLine(to: firstPoint)
                        }
                    }
                    .fill(Color.blue.opacity(0.3))
                    
                    // Radar outline
                    Path { path in
                        var firstPoint: CGPoint? = nil
                        
                        for i in 0..<radarPoints {
                            if i < analyzer.stylePerformances.count {
                                let style = analyzer.stylePerformances[i]
                                let score = normalizedScores[style.id] ?? 0
                                let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(radarPoints) - CGFloat.pi / 2
                                
                                let point = CGPoint(
                                    x: center.x + cos(angle) * radius * CGFloat(score),
                                    y: center.y + sin(angle) * radius * CGFloat(score)
                                )
                                
                                if i == 0 {
                                    path.move(to: point)
                                    firstPoint = point
                                } else {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        
                        if let firstPoint = firstPoint {
                            path.addLine(to: firstPoint)
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // Data points
                    ForEach(0..<radarPoints, id: \.self) { i in
                        if i < analyzer.stylePerformances.count {
                            let style = analyzer.stylePerformances[i]
                            let score = normalizedScores[style.id] ?? 0
                            let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(radarPoints) - CGFloat.pi / 2
                            
                            let point = CGPoint(
                                x: center.x + cos(angle) * radius * CGFloat(score),
                                y: center.y + sin(angle) * radius * CGFloat(score)
                            )
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .position(point)
                        }
                    }
                }
                
                // Center label
                Text("Estilos")
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(.gray)
                    .position(center)
            }
        }
        .frame(height: 250)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Style comparison view accessible from learning tree
struct StyleComparisonView: View {
    @ObservedObject var analyzer = LearningStyleAnalyzer.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Radar chart
                    Text("Perfil de Aprendizaje")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    RadarChartView()
                        .padding(.horizontal)
                    
                    // Style breakdown
                    Text("Desglose por Estilo")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ForEach(analyzer.stylePerformances) { style in
                        StylePerformanceCard(performance: style)
                            .padding(.horizontal)
                    }
                    
                    // Historical comparison
                    if !analyzer.performanceHistory.isEmpty && analyzer.performanceHistory.count >= 3 {
                        Text("Evolución de Rendimiento")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        ForEach(analyzer.stylePerformances) { style in
                            if analyzer.getHistoryForStyle(styleId: style.id).count > 0 {
                                LearningStyleChart(styleId: style.id)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationBarTitle("Comparación de Estilos", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
        }
    }
}

// Button to add to Learning Style Tree view
struct CompareStylesButton: View {
    @State private var showingComparisonView = false
    
    var body: some View {
        Button(action: {
            showingComparisonView = true
        }) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                Text("Comparar Estilos")
                    .font(.custom("Poppins-SemiBold", size: 14))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .sheet(isPresented: $showingComparisonView) {
            StyleComparisonView()
        }
    }
}

// Preview providers
struct RadarChartView_Previews: PreviewProvider {
    static var previews: some View {
        RadarChartView()
            .frame(height: 250)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct LearningStyleChart_Previews: PreviewProvider {
    static var previews: some View {
        LearningStyleChart(styleId: "visual")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct StyleComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        StyleComparisonView()
    }
}
