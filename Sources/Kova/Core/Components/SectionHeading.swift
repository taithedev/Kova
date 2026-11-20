import SwiftUI
struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment:.leading,spacing:5) {
            Text(title).font(.kovaHeadline)
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(KovaTheme.muted) }
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
}
