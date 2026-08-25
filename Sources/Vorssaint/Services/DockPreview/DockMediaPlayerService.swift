// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

enum DockMediaPlaybackState: String, Equatable {
    case playing
    case paused
    case stopped
}

struct DockMediaPlayer: Equatable {
    let bundleID: String
    let appName: String
    let title: String
    let artist: String?
    let album: String?
    let state: DockMediaPlaybackState
    let position: TimeInterval?
    let duration: TimeInterval?
    /// Stable artwork identity used for equality; comparing `NSImage` by
    /// encoding both sides to TIFF put image conversion on SwiftUI's hot path.
    let artworkData: Data?
    let artwork: NSImage?
    let appIcon: NSImage?

    var isPlaying: Bool { state == .playing }

    var progress: Double? {
        guard let position, let duration, duration > 0 else { return nil }
        return min(max(position / duration, 0), 1)
    }

    var hasTrack: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && state != .stopped
    }

    static func == (lhs: DockMediaPlayer, rhs: DockMediaPlayer) -> Bool {
        lhs.bundleID == rhs.bundleID
            && lhs.appName == rhs.appName
            && lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.state == rhs.state
            && lhs.position == rhs.position
            && lhs.duration == rhs.duration
            && lhs.artworkData == rhs.artworkData
    }
}

enum DockMediaCommand {
    case previous
    case playPause
    case next
}

struct DockMediaPlayerSource: Equatable {
    let bundleID: String
    let pid: pid_t
    let appName: String
    let appIcon: NSImage?

    init?(app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return nil }
        self.bundleID = bundleID
        self.pid = app.processIdentifier
        self.appName = app.localizedName ?? app.bundleURL?.deletingPathExtension().lastPathComponent ?? bundleID
        self.appIcon = app.icon
    }
}

final class DockMediaPlayerService {
    static let shared = DockMediaPlayerService()

    private let bridge = MediaRemoteNowPlayingBridge.shared

    private init() {}

    func snapshot(for source: DockMediaPlayerSource, completion: @escaping (DockMediaPlayer?) -> Void) {
        bridge.fetch(includePaused: true) { snapshot in
            DispatchQueue.main.async {
                guard let snapshot,
                      snapshot.appBundleIdentifier == source.bundleID
                        || snapshot.appPID == source.pid
                else {
                    completion(nil)
                    return
                }
                let title = snapshot.title ?? source.appName
                let artwork = snapshot.artworkData.flatMap(NSImage.init(data:))
                completion(DockMediaPlayer(bundleID: source.bundleID,
                                           appName: source.appName,
                                           title: title,
                                           artist: snapshot.artist,
                                           album: snapshot.album,
                                           state: snapshot.isPlaying ? .playing : .paused,
                                           position: nil,
                                           duration: nil,
                                           artworkData: snapshot.artworkData,
                                           artwork: artwork,
                                           appIcon: source.appIcon))
            }
        }
    }

    func observeChanges(_ handler: @escaping () -> Void) -> [NSObjectProtocol] {
        bridge.observeChanges(handler)
    }

    func perform(_ command: DockMediaCommand) {
        let key: RadialMenuMediaKey
        switch command {
        case .previous: key = .previousTrack
        case .playPause: key = .playPause
        case .next: key = .nextTrack
        }
        RadialMenuService.postMediaKey(key)
    }
}
