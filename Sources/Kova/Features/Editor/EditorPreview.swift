import SwiftUI
// Video trimming/effects require an export pipeline. This is an honest staging UI, not a fake editor.
struct EditorPreview:View {
    var body:some View {EmptyState(icon:"slider.horizontal.3",title:"Editor coming next",detail:"Planned: trim, captions, licensed sound library, filters and draft exports.")}
}
