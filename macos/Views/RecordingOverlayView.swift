import SwiftUI

struct RecordingOverlayView: View {
    @State private var pulse: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    
    var body: some View {
        ZStack {
            // 1. Premium Glassmorphic Background Blur
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(red: 0.01, green: 0.03, blue: 0.08).opacity(0.72))
                .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).cornerRadius(30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.82, blue: 1.0, opacity: 0.28),
                                    Color(red: 0.0, green: 0.82, blue: 1.0, opacity: 0.05),
                                    Color(red: 0.5, green: 0.0, blue: 1.0, opacity: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.18), radius: 30, x: 0, y: 10)
            
            VStack(spacing: 16) {
                // 2. Beautiful Circular Neon Icon and Waves
                ZStack {
                    // Outer neon glowing waves
                    Circle()
                        .stroke(Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.15), lineWidth: 1)
                        .scaleEffect(pulse * 1.3)
                        .opacity(2.0 - pulse)
                    
                    Circle()
                        .stroke(Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulse)
                        .opacity(1.8 - pulse)
                    
                    // Rotating glowing gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.82, blue: 1.0),
                                    Color(red: 0.5, green: 0.0, blue: 1.0),
                                    Color(red: 0.0, green: 0.82, blue: 1.0)
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .rotationEffect(.degrees(rotation))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.6), radius: 8)
                    
                    // Inner Circular App Icon Core
                    Circle()
                        .fill(Color(red: 0.02, green: 0.05, blue: 0.12))
                        .frame(width: 74, height: 74)
                    
                    // Microphone Icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.82, blue: 1.0),
                                    Color(red: 0.6, green: 0.2, blue: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(width: 120, height: 120)
                .onAppear {
                    // Soft, premium organic breathing pulse
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulse = 1.4
                    }
                    
                    // Continuous smooth rotation for the gradient ring
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                
                // 3. Status Text
                VStack(spacing: 4) {
                    Text("MONGOLMIC V4")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.8))
                        .tracking(3)
                    
                    Text("Дууг бичиж байна...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 250, height: 210)
    }
}

// SwiftUI blur effect wrapper for macOS native look
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    RecordingOverlayView()
        .preferredColorScheme(.dark)
}
