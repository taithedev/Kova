import SwiftUI
import WebKit

/// Displays an uploaded GIF using WebKit's native image animation.
struct KovaAnimatedBanner: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isUserInteractionEnabled = false
        view.loadHTMLString(document, baseURL: nil)
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
    private var document: String {
        // The URL comes from a Neon presigned GET, not user-submitted HTML.
        let src = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head>
        <body style="padding:0;margin:0;background:transparent;overflow:hidden">
        <img src="\(src)" style="height:100vh;width:100vw;object-fit:cover"></body></html>
        """
    }
}
