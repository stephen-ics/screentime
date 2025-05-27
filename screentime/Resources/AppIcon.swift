import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.1, green: 0.3, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Hourglass shape
            ZStack {
                // Top triangle
                Path { path in
                    path.move(to: CGPoint(x: size * 0.5, y: size * 0.25))
                    path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.25))
                    path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.45))
                    path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.25))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Bottom triangle
                Path { path in
                    path.move(to: CGPoint(x: size * 0.5, y: size * 0.55))
                    path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.75))
                    path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.75))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Sand particles
                ForEach(0..<8) { i in
                    Circle()
                        .fill(Color.yellow.opacity(0.8))
                        .frame(width: size * 0.02, height: size * 0.02)
                        .offset(
                            x: size * 0.5 + CGFloat.random(in: -0.05...0.05) * size,
                            y: size * 0.5 + CGFloat(i) * size * 0.015
                        )
                }
                
                // Hourglass frame
                Path { path in
                    // Left side
                    path.move(to: CGPoint(x: size * 0.3, y: size * 0.25))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.3, y: size * 0.75),
                        control: CGPoint(x: size * 0.45, y: size * 0.5)
                    )
                    
                    // Right side
                    path.move(to: CGPoint(x: size * 0.7, y: size * 0.25))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.7, y: size * 0.75),
                        control: CGPoint(x: size * 0.55, y: size * 0.5)
                    )
                    
                    // Top line
                    path.move(to: CGPoint(x: size * 0.3, y: size * 0.25))
                    path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.25))
                    
                    // Bottom line
                    path.move(to: CGPoint(x: size * 0.3, y: size * 0.75))
                    path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.75))
                }
                .stroke(Color.white, lineWidth: size * 0.03)
                
                // Center connection
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.08)
                    .position(x: size * 0.5, y: size * 0.5)
            }
            .shadow(color: Color.black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.01)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237))
    }
}

// Preview for different icon sizes
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppIconView(size: 180)
            AppIconView(size: 120)
            AppIconView(size: 60)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
} 