import SwiftUI

struct KovaProfileHeader: View {
    let profile: KovaUser
    var ownProfile = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                KovaTheme.banner(profile.bannerStyle ?? "ink")
                if let raw = profile.bannerUrl, let url = URL(string: raw), url.scheme == "https" {
                    if profile.bannerAnimated == true && !reduceMotion {
                        KovaAnimatedBanner(url: url)
                            .accessibilityLabel("Animated profile banner")
                    } else {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 215, height: 215)
                    .offset(x: 48, y: -74)
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 340, height: 340)
                    .offset(x: 95, y: -143)
                HStack {
                    KovaMark(size: 36)
                    Spacer()
                    Text("KOVA / PROFILE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(20)
            }
            .frame(height: 170)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                KovaAvatar(name: profile.displayName, size: 98, url: profile.avatarUrl)
                    .offset(x: 23, y: 49)
            }
            HStack {
                Spacer()
                if profile.isPrivate {
                    Label("PRIVATE", systemImage: "lock.fill")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(KovaTheme.muted)
                } else {
                    Label("PUBLIC", systemImage: "globe")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(KovaTheme.muted)
                }
            }
            .padding(.horizontal, 21)
            .padding(.top, 13)
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.system(size: 27, weight: .heavy))
                        .tracking(-0.8)
                        .lineLimit(1)
                    if profile.isVerified == true {
                        KovaVerifiedBadge(size: 21)
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 9) {
                    Text("@" + profile.handle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(KovaTheme.muted)
                    if let pronouns = profile.pronouns, !pronouns.isEmpty {
                        Text("• " + pronouns)
                            .font(.system(size: 12))
                            .foregroundStyle(KovaTheme.muted)
                    }
                }
                KovaRoleBadge(role: profile.role)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else if ownProfile {
                    Text("Add a bio so people can get to know you.")
                        .font(.system(size: 13))
                        .foregroundStyle(KovaTheme.muted)
                }
                HStack(spacing: 23) {
                    count(profile.followersCount ?? 0, label: "Followers")
                    count(profile.followingCount ?? 0, label: "Following")
                    Spacer()
                }
                .padding(.top, 9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 32)
        }
        .background(KovaTheme.background)
    }

    private func count(_ value: Int, label: String) -> some View {
        HStack(spacing: 5) {
            Text(value.formatted(.number.notation(.compactName)))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(KovaTheme.foreground)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(KovaTheme.muted)
        }
    }
}

struct KovaProfileVideoTile: View {
    let caption: String
    var thumbnail: String? = nil
    var index: Int = 0
    var status: String? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(KovaTheme.videoGradients[index % KovaTheme.videoGradients.count][0].gradient)
            if let thumbnail, let url = URL(string: thumbnail), url.scheme == "https" {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() }
                placeholder: { Color.clear }
            }
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                if let status, status != "approved" {
                    Text(status.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(.black.opacity(0.62), in: Capsule())
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                Text(caption.isEmpty ? "Video" : caption)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.white)
            .padding(10)
        }
        .aspectRatio(0.71, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(caption.isEmpty ? "Kova video" : caption)
    }
}
