import SwiftUI

struct AppIconDisplay: View {
    let size: CGFloat
    
    var body: some View {
        AppIconView(size: size)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2237))
            .shadow(radius: 4)
    }
}

struct AppIconDisplay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppIconDisplay(size: 120)
            AppIconDisplay(size: 80)
            AppIconDisplay(size: 60)
        }
        .padding()
    }
} 