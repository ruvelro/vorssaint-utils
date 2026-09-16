// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Accelerate
import AppKit
import Combine
import CoreAudio
import Foundation

/// Reads the current player's audio output and turns it into seven levels
/// for the island's bars. Off unless chosen, and running only while that
/// player is playing: the tap follows the player's process, listens to
/// nothing else, keeps a fraction of a second of samples in memory and never
/// stores or sends audio.
final class NotchAudioLevelService: ObservableObject {
    static let shared = NotchAudioLevelService()

    /// Band levels from 0 to 1 while a player is being read, nil otherwise.
    @Published private(set) var levels: [Double]?

    private var enabled = false
    private var subscription: AnyCancellable?
    private var reader: NotchAudioLevelReader?
    private var readerPID: pid_t = 0
    /// A player whose tap stayed silent, most likely because the permission
    /// was declined. Its bars keep the synthetic motion until the option is
    /// switched off and on again.
    private var silentPID: pid_t = 0
    private var stopWork: DispatchWorkItem?

    private init() {}

    func syncWithPreferences() {
        enabled = NotchSupport.isEnabled() && NotchAudioLevelSupport.isSupported && NotchAudioLevelSupport.isEnabled()
        if enabled {
            if subscription == nil {
                silentPID = 0
                subscription = NotchMusicService.shared.$playback
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] playback in self?.playbackChanged(playback) }
            }
        } else {
            subscription = nil
            stop()
        }
    }

    func stop() {
        stopWork?.cancel(); stopWork = nil
        reader?.stop()
        reader = nil
        readerPID = 0
        if levels != nil { levels = nil }
    }

    private func playbackChanged(_ playback: NotchPlayback?) {
        guard enabled, let playback, playback.isPlaying,
              let pid = playback.track.appPID, pid > 0 else {
            scheduleStop()
            return
        }
        stopWork?.cancel(); stopWork = nil
        if reader != nil, readerPID == pid { return }
        guard pid != silentPID else { return }
        reader?.stop()
        reader = nil
        readerPID = pid
        let created = NotchAudioLevelReader(pid: pid, onLevels: { [weak self] next in
            DispatchQueue.main.async { self?.receive(next, from: pid) }
        }, onSilence: { [weak self] in
            DispatchQueue.main.async { self?.fallBack(from: pid) }
        })
        guard let created, created.start() else { readerPID = 0; return }
        reader = created
    }

    private func fallBack(from pid: pid_t) {
        guard readerPID == pid else { return }
        silentPID = pid
        stop()
    }

    /// A pause keeps the bars for a moment, so a skipped track does not
    /// blink the meter off and on; a real stop then releases the tap.
    private func scheduleStop() {
        guard reader != nil || levels != nil, stopWork == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.stopWork = nil
            self?.stop()
        }
        stopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func receive(_ next: [Double], from pid: pid_t) {
        guard reader != nil, readerPID == pid else { return }
        levels = next
    }
}

/// One process tap read through a private aggregate device on the default
/// output, the same shape the recorder uses, feeding a ring of mono samples
/// that a timer analyses off the audio thread.
private final class NotchAudioLevelReader {
    private let queue = DispatchQueue(label: "com.vorssaint.notch-audio-levels", qos: .utility)
    private static let teardownQueue = DispatchQueue(label: "com.vorssaint.notch-audio-levels.teardown", qos: .utility)
    private let onLevels: ([Double]) -> Void
    private let onSilence: () -> Void
    private let ring = NotchAudioRing(capacity: 8192)
    private var startedAt: TimeInterval = 0
    private var tapID = AudioObjectID(0)
    private var tapUID = ""
    private var tapChannels = 2
    private var aggregateID = AudioObjectID(0)
    private var ioProc: AudioDeviceIOProcID?
    private var timer: DispatchSourceTimer?
    private var analyzer: NotchAudioAnalyzer?
    private var smoother = NotchAudioLevelSupport.Smoother()
    private var samples: [Float] = []
    private var stopped = false

    init?(pid: pid_t, onLevels: @escaping ([Double]) -> Void, onSilence: @escaping () -> Void) {
        guard #available(macOS 14.4, *), let object = Self.processObject(for: pid) else { return nil }
        self.onLevels = onLevels
        self.onSilence = onSilence
        let description = CATapDescription(stereoMixdownOfProcesses: [object])
        description.name = "Vorssaint Island Levels"
        description.isPrivate = true
        description.muteBehavior = .unmuted
        var tapID = AudioObjectID(0)
        guard AudioHardwareCreateProcessTap(description, &tapID) == noErr, tapID != 0 else { return nil }
        self.tapID = tapID
        tapUID = description.uuid.uuidString
        var format = AudioStreamBasicDescription()
        if Self.read(tapID, kAudioTapPropertyFormat, &format), format.mChannelsPerFrame > 0 {
            tapChannels = Int(format.mChannelsPerFrame)
        }
    }

    deinit {
        Self.destroy(aggregateID: aggregateID, ioProc: ioProc, tapID: tapID)
    }

    func start() -> Bool {
        guard aggregateID == 0, let hostUID = Self.hostDeviceUID() else { return false }
        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Vorssaint Island Levels",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceMainSubDeviceKey: hostUID,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: hostUID]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapUIDKey: tapUID,
                kAudioSubTapDriftCompensationKey: true,
            ]],
            kAudioAggregateDeviceTapAutoStartKey: true,
        ]
        var aggregateID = AudioObjectID(0)
        guard AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggregateID) == noErr,
              aggregateID != 0 else { return false }
        let sampleRate = Self.nominalSampleRate(of: aggregateID)
        guard let analyzer = NotchAudioAnalyzer(sampleRate: sampleRate) else {
            Self.destroy(aggregateID: aggregateID, ioProc: nil, tapID: 0)
            return false
        }
        // The audio thread touches only these captured values, never this
        // object, matching the mixer's realtime discipline.
        let ring = self.ring
        let channels = tapChannels
        var ioProc: AudioDeviceIOProcID?
        let created = AudioDeviceCreateIOProcIDWithBlock(&ioProc, aggregateID, nil) { _, input, _, output, _ in
            // The device beneath the aggregate would otherwise play whatever
            // this memory last held.
            MixerRender.silence(UnsafeMutableAudioBufferListPointer(output))
            let inputBuffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
            guard let index = MixerRender.tapBufferIndex(in: inputBuffers, tapChannels: channels) else { return }
            ring.write(inputBuffers[index])
        }
        guard created == noErr, let ioProc, AudioDeviceStart(aggregateID, ioProc) == noErr else {
            Self.destroy(aggregateID: aggregateID, ioProc: ioProc, tapID: 0)
            return false
        }
        self.aggregateID = aggregateID
        self.ioProc = ioProc
        self.analyzer = analyzer
        samples = [Float](repeating: 0, count: analyzer.size)
        startedAt = ProcessInfo.processInfo.systemUptime
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 0.1, repeating: 1 / NotchAudioLevelSupport.updatesPerSecond, leeway: .milliseconds(5))
        timer.setEventHandler { [weak self] in self?.analyse() }
        self.timer = timer
        timer.resume()
        return true
    }

    func stop() {
        stopped = true
        timer?.cancel()
        timer = nil
        let aggregateID = self.aggregateID
        let ioProc = self.ioProc
        let tapID = self.tapID
        self.aggregateID = 0
        self.ioProc = nil
        self.tapID = 0
        if aggregateID != 0, let ioProc { AudioDeviceStop(aggregateID, ioProc) }
        Self.destroy(aggregateID: aggregateID, ioProc: ioProc, tapID: tapID)
    }

    private func analyse() {
        guard !stopped, let analyzer else { return }
        // Levels are reported only once sound has arrived, so the bars keep
        // their usual motion while the tap warms up, and give it up for good
        // when the tap only ever delivers silence.
        guard ring.hasHeard else {
            if NotchAudioLevelSupport.fallsBack(heard: false, elapsed: ProcessInfo.processInfo.systemUptime - startedAt) {
                stopped = true
                onSilence()
            }
            return
        }
        guard ring.latest(into: &samples) else { return }
        let magnitudes = analyzer.magnitudes(of: samples)
        let raw = NotchAudioLevelSupport.bandLevels(magnitudes: magnitudes, bands: analyzer.bands)
        onLevels(smoother.next(raw))
    }

    // MARK: - Core Audio

    private static func destroy(aggregateID: AudioObjectID, ioProc: AudioDeviceIOProcID?, tapID: AudioObjectID) {
        guard aggregateID != 0 || tapID != 0 else { return }
        teardownQueue.async {
            if aggregateID != 0 {
                if let ioProc { AudioDeviceDestroyIOProcID(aggregateID, ioProc) }
                AudioHardwareDestroyAggregateDevice(aggregateID)
            }
            if tapID != 0, #available(macOS 14.4, *) {
                AudioHardwareDestroyProcessTap(tapID)
            }
        }
    }

    private static func address(_ selector: AudioObjectPropertySelector,
                                scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private static func read<T>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ value: inout T) -> Bool {
        var address = address(selector)
        var size = UInt32(MemoryLayout<T>.size)
        return withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(object, &address, 0, nil, &size, UnsafeMutableRawPointer(pointer)) == noErr
        }
    }

    private static func processObject(for pid: pid_t) -> AudioObjectID? {
        var pid = pid
        var object = AudioObjectID(0)
        var address = address(kAudioHardwarePropertyTranslatePIDToProcessObject)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = withUnsafePointer(to: &pid) { pidPointer in
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                       UInt32(MemoryLayout<pid_t>.size), pidPointer, &size, &object)
        }
        guard status == noErr, object != 0 else { return nil }
        return object
    }

    private static func nominalSampleRate(of deviceID: AudioObjectID) -> Double {
        var sampleRate: Float64 = 0
        guard read(deviceID, kAudioDevicePropertyNominalSampleRate, &sampleRate), sampleRate > 0 else { return 48_000 }
        return sampleRate
    }

    private static func hostDeviceUID() -> String? {
        var defaultDevice = AudioObjectID(0)
        guard read(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, &defaultDevice),
              defaultDevice != 0 else { return nil }
        var uid: CFString = "" as CFString
        guard read(defaultDevice, kAudioDevicePropertyDeviceUID, &uid) else { return nil }
        return uid as String
    }
}

/// Mono samples from the audio thread, most recent last. The audio thread
/// skips a buffer rather than wait when the analysis thread is reading.
private final class NotchAudioRing {
    private let lock = NSLock()
    private var samples: [Float]
    private var head = 0
    private var filled = 0
    private var heard = false
    private let capacity: Int

    /// Whether any sample so far carried sound rather than digital silence.
    var hasHeard: Bool {
        lock.lock()
        defer { lock.unlock() }
        return heard
    }

    init(capacity: Int) {
        self.capacity = capacity
        samples = [Float](repeating: 0, count: capacity)
    }

    func write(_ buffer: AudioBuffer) {
        guard lock.try() else { return }
        defer { lock.unlock() }
        let channels = Int(buffer.mNumberChannels)
        guard channels > 0, let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { return }
        let frames = MixerRender.frames(bytes: buffer.mDataByteSize, channels: buffer.mNumberChannels)
        let scale = 1 / Float(channels)
        var loudest: Float = 0
        for frame in 0..<frames {
            var sum: Float = 0
            for channel in 0..<channels { sum += data[frame * channels + channel] }
            let mono = sum * scale
            samples[head] = mono
            head = (head + 1) % capacity
            loudest = max(loudest, abs(mono))
        }
        filled = min(capacity, filled + frames)
        if loudest > 0.001 { heard = true }
    }

    /// The most recent `output.count` samples, oldest first. False until
    /// that many have arrived.
    func latest(into output: inout [Float]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let count = output.count
        guard count > 0, count <= capacity, filled >= count else { return false }
        var index = (head - count + capacity) % capacity
        for position in 0..<count {
            output[position] = samples[index]
            index = (index + 1) % capacity
        }
        return true
    }
}

/// A windowed discrete Fourier transform of one block of samples.
private final class NotchAudioAnalyzer {
    let size = 1024
    let bands: [Range<Int>]
    private let setup: vDSP_DFT_Setup
    private var window: [Float]
    private var windowed: [Float]
    private var imaginary: [Float]
    private var outReal: [Float]
    private var outImaginary: [Float]
    private var magnitudes: [Float]

    init?(sampleRate: Double) {
        guard let setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(size), .FORWARD) else { return nil }
        self.setup = setup
        window = [Float](repeating: 0, count: size)
        vDSP_hann_window(&window, vDSP_Length(size), Int32(vDSP_HANN_NORM))
        windowed = [Float](repeating: 0, count: size)
        imaginary = [Float](repeating: 0, count: size)
        outReal = [Float](repeating: 0, count: size)
        outImaginary = [Float](repeating: 0, count: size)
        magnitudes = [Float](repeating: 0, count: size / 2)
        bands = NotchAudioLevelSupport.bandRanges(sampleRate: sampleRate, size: size)
    }

    deinit { vDSP_DFT_DestroySetup(setup) }

    /// Magnitudes of the first `size / 2` bins relative to full scale.
    /// Every vDSP call takes explicit buffer pointers: the implicit array
    /// conversions read fine on the newest compiler and not on Swift 6.0.
    func magnitudes(of samples: [Float]) -> [Float] {
        guard samples.count == size else { return magnitudes }
        let length = vDSP_Length(size)
        let half = vDSP_Length(size / 2)
        samples.withUnsafeBufferPointer { input in
            window.withUnsafeBufferPointer { taper in
                windowed.withUnsafeMutableBufferPointer { output in
                    vDSP_vmul(input.baseAddress!, 1, taper.baseAddress!, 1, output.baseAddress!, 1, length)
                }
            }
        }
        windowed.withUnsafeBufferPointer { real in
            imaginary.withUnsafeBufferPointer { imaginaryInput in
                outReal.withUnsafeMutableBufferPointer { realOutput in
                    outImaginary.withUnsafeMutableBufferPointer { imaginaryOutput in
                        vDSP_DFT_Execute(setup, real.baseAddress!, imaginaryInput.baseAddress!,
                                         realOutput.baseAddress!, imaginaryOutput.baseAddress!)
                    }
                }
            }
        }
        var scale = 1 / Float(size)
        outReal.withUnsafeMutableBufferPointer { real in
            outImaginary.withUnsafeMutableBufferPointer { imaginaryOutput in
                magnitudes.withUnsafeMutableBufferPointer { output in
                    var split = DSPSplitComplex(realp: real.baseAddress!, imagp: imaginaryOutput.baseAddress!)
                    vDSP_zvabs(&split, 1, output.baseAddress!, 1, half)
                    vDSP_vsmul(output.baseAddress!, 1, &scale, output.baseAddress!, 1, half)
                }
            }
        }
        return magnitudes
    }
}
