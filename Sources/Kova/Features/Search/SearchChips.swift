import SwiftUI
struct SearchChips:View {
    let terms:[String]
    let selected:(String)->Void
    var body:some View {
        ScrollView(.horizontal,showsIndicators:false) {HStack(spacing:9){ForEach(terms,id:\.self){term in Button(term){selected(term)}.font(.footnote).bold().padding(.horizontal,14).padding(.vertical,9).background(KovaTheme.panel,in:Capsule())}}}
    }
}
