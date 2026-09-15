// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Compact playback stays beside the camera and never grows a second row.
struct NotchMusicStrip: View {
    @ObservedObject var service: NotchService
    @ObservedObject private var music = NotchMusicService.shared
    @ObservedObject private var l10n = L10n.shared

    private var geometry: NotchGeometry { service.compactActivityGeometry }

    private var artworkSide: CGFloat {
        max(0, min(26, geometry.menuBarHeight - 6, geometry.compactActivityWingWidth - 20))
    }

    private var title: String { music.playback?.track.title ?? FeatureStrings.radialMenu(l10n.language).mediaNowPlaying }
    private var artist: String? {
        guard let artist = music.playback?.track.artist?.trimmingCharacters(in: .whitespaces), !artist.isEmpty else { return nil }
        return artist
    }
    /// A screen without a camera keeps the same middle spacer so the island's
    /// width and click zones do not depend on the display, but nothing physical
    /// sits there. Naming the track fills that space instead of leaving a hole
    /// between the artwork and the bars.
    private var fillsCameraGap: Bool { !geometry.isNotched && geometry.compactActivityCameraGap >= 56 }
    /// Without measured menu space the wings stay hidden to protect menus, so
    /// on a screen without a camera the whole strip is the middle spacer.
    /// Everything moves inside it rather than leaving only the name.
    private var hasWings: Bool { geometry.compactActivityWingWidth >= 44 }
    private var showsArtist: Bool { geometry.compactActivityContentHeight >= 28 }
    private var barHeight: CGFloat { min(16, max(8, geometry.compactActivityContentHeight - 12)) }
    private var tint: Color { music.artworkTint?.color ?? .white }

    var body: some View {
        Button { service.open(.music) } label: {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    if hasWings { artwork(side: artworkSide) }
                }
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .frame(width: geometry.compactActivityWingWidth, alignment: .trailing)
                .clipped()
                Group {
                    if fillsCameraGap, hasWings { trackLabel }
                    else if fillsCameraGap { compactCluster }
                    else { Color.clear }
                }
                .frame(width: geometry.compactActivityCameraGap, height: geometry.compactActivityContentHeight)
                .clipped()
                HStack {
                    if hasWings {
                        NotchEqualizerBars(isPlaying: music.playback?.isPlaying == true,
                                           bars: 7, barWidth: 1.8,
                                           height: barHeight,
                                           tint: tint)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(width: geometry.compactActivityWingWidth, alignment: .leading)
            }
            .frame(height: geometry.compactActivityContentHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel([title, music.playback?.track.artist].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(FeatureStrings.notch(l10n.language).open)
        .help(title)
    }

    private func artwork(side: CGFloat) -> some View {
        Group {
            if let image = music.artwork {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Color.black.overlay { Image(systemName: "music.note").foregroundStyle(.secondary) }
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 0.28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
        }
    }

    /// Artwork, name and bars packed into the spacer alone.
    private var compactCluster: some View {
        let side = max(0, min(22, geometry.compactActivityContentHeight - 8))
        return HStack(spacing: 6) {
            artwork(side: side)
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if showsArtist, let artist {
                    Text(artist)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity)
            NotchEqualizerBars(isPlaying: music.playback?.isPlaying == true,
                               bars: 5, barWidth: 1.6,
                               height: min(14, barHeight),
                               tint: tint)
        }
        .padding(.horizontal, 7)
        .accessibilityHidden(true)
    }

    private var trackLabel: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            if showsArtist, let artist {
                Text(artist)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
