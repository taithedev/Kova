import SwiftUI
struct WelcomeView: View {
    @EnvironmentObject private var session:SessionStore
    @State private var showAuth=false
    var body:some View {
        ZStack {
            KovaTheme.background.ignoresSafeArea()
            GeometryReader { geo in
                Circle().fill(KovaTheme.lavender.opacity(0.28)).frame(width:330,height:330).blur(radius:90).position(x:geo.size.width*0.8,y:geo.size.height*0.15)
                Circle().fill(KovaTheme.aqua.opacity(0.12)).frame(width:300,height:300).blur(radius:100).position(x:geo.size.width*0.1,y:geo.size.height*0.7)
            }.ignoresSafeArea()
            VStack(spacing:0) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius:31).fill(KovaTheme.purpleGradient).frame(width:112,height:112).rotationEffect(.degrees(-8))
                    Image(systemName:"play.rectangle.on.rectangle.fill").font(.system(size:50,weight:.light)).foregroundStyle(.white)
                }.shadow(color:KovaTheme.lavender.opacity(0.3),radius:35)
                Text("KOVA").font(.system(size:67,weight:.black,design:.rounded)).tracking(-4).padding(.top,38)
                Text("Your next favorite place.").font(.system(size:19,weight:.semibold)).foregroundStyle(KovaTheme.muted).padding(.top,4)
                Spacer()
                VStack(spacing:16) {
                    GradientButton("Get started",icon:"arrow.right") {showAuth=true}
                    Button("Explore preview") {session.preview()}.font(.system(size:16,weight:.semibold)).foregroundStyle(.white)
                    Text("Kova social accounts are 13+. Under-13 access is not enabled.").font(.system(size:11)).foregroundStyle(KovaTheme.muted).multilineTextAlignment(.center).padding(.top,10)
                }.padding(.horizontal,32)
                Spacer().frame(height:42)
            }
        }
        .sheet(isPresented:$showAuth){ AuthView().presentationDragIndicator(.visible) }
    }
}
