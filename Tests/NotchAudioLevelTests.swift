// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum NotchAudioLevelTests {
    static func run(expect: (Bool, String) -> Void) {
        let bands = NotchAudioLevelSupport.bandRanges(sampleRate: 48_000, size: 1024)
        expect(bands.count == 7 && bands.allSatisfy { !$0.isEmpty && $0.lowerBound >= 1 && $0.upperBound <= 512 }
               && zip(bands, bands.dropFirst()).allSatisfy { $0.upperBound <= $1.lowerBound },
               "seven ordered bands cover the usable spectrum without the DC bin")
        let narrow = NotchAudioLevelSupport.bandRanges(sampleRate: 8_000, size: 64)
        expect(narrow.count == 7 && narrow.allSatisfy { !$0.isEmpty && $0.upperBound <= 32 },
               "a narrow spectrum still gives every band at least one bin")
        var magnitudes = [Float](repeating: 0, count: 512)
        expect(NotchAudioLevelSupport.bandLevels(magnitudes: magnitudes, bands: bands).allSatisfy { $0 == 0 },
               "silence is flat")
        magnitudes[Int(700 / (48_000 / 1024.0))] = 0.5
        let levels = NotchAudioLevelSupport.bandLevels(magnitudes: magnitudes, bands: bands)
        expect(levels.count == 7 && levels[3] > 0 && levels.enumerated().allSatisfy { $0.offset == 3 || $0.element == 0 },
               "a 700 Hz tone lights only the band that holds it")
        var smoother = NotchAudioLevelSupport.Smoother()
        let first = smoother.next([0, 0, 0, 1, 0, 0, 0])
        let second = smoother.next([0, 0, 0, 1, 0, 0, 0])
        expect(first[3] > 0.4 && second[3] > first[3] && second[3] <= 1, "bars rise quickly toward their target")
        let released = smoother.next([0, 0, 0, 0, 0, 0, 0])
        expect(released[3] < second[3] && released[3] > second[3] * 0.7, "bars fall more slowly than they rise")
        var quiet = NotchAudioLevelSupport.Smoother()
        var scaled: [Double] = []
        for _ in 0..<12 { scaled = quiet.next([0.1, 0.2, 0.3, 0.3, 0.2, 0.1, 0.05]) }
        expect(scaled.max().map { $0 > 0.8 } == true, "a quiet source still fills the meter")
        expect(NotchAudioLevelSupport.barIndex(0, of: 3, bands: 7) == 1 && NotchAudioLevelSupport.barIndex(1, of: 3, bands: 7) == 3
               && NotchAudioLevelSupport.barIndex(2, of: 3, bands: 7) == 5 && NotchAudioLevelSupport.barIndex(6, of: 7, bands: 7) == 6,
               "fewer bars sample the bands evenly")
        expect(!NotchAudioLevelSupport.fallsBack(heard: false, elapsed: 1) && !NotchAudioLevelSupport.fallsBack(heard: true, elapsed: 10)
               && NotchAudioLevelSupport.fallsBack(heard: false, elapsed: NotchAudioLevelSupport.silenceGrace),
               "a tap that only ever delivers silence hands the bars back to their synthetic motion")
        expect(!NotchAudioLevelSupport.isEnabled(in: UserDefaults(suiteName: "vorssaint.tests.audio-levels")!),
               "the live equalizer stays off until chosen")
        expect(NotchAudioLevelSupport.silenceGrace >= 5,
               "a tap outlasts a permission prompt being read and a player that buffers before it sounds")
        silenceMemoryContracts(expect: expect)
    }

    /// Giving up on a silent tap must cost one play, never the session.
    private static func silenceMemoryContracts(expect: (Bool, String) -> Void) {
        func playback(_ title: String, pid: pid_t) -> NotchPlayback {
            let track = RadialNowPlayingSnapshot(title: title, artist: "Artist", album: "Album",
                                                 artworkData: nil, appBundleIdentifier: "org.example.player",
                                                 appPID: pid)
            return NotchPlayback(track: track, isPlaying: true, elapsed: 0, duration: 180, rate: 1,
                                 sampledAt: Date(timeIntervalSinceReferenceDate: 0), canSeek: false,
                                 itemIdentifier: title, canSendCommandsDirectly: true)
        }
        let first = NotchMusicIdentity(playback("First", pid: 42))
        let second = NotchMusicIdentity(playback("Second", pid: 42))
        let other = NotchMusicIdentity(playback("First", pid: 43))
        var memory = NotchAudioLevelSupport.SilenceMemory()
        expect(memory.reads(first), "a player is read before anything is known about it")
        memory.giveUp(on: first)
        expect(!memory.reads(first), "the play a tap stayed silent on keeps the synthetic motion")
        expect(memory.reads(second) && memory.reads(other),
               "another track, or another player, is still read")
        memory.giveUp(on: first)
        memory.rearm()
        expect(memory.reads(first), "pressing play again reads the same track once more")
    }
}
