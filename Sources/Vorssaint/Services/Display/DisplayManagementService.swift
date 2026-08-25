// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import ColorSync
import CoreGraphics
import Foundation

struct DisplayResolutionMode: Identifiable, Hashable {
    let id: Int32
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double
    let isHiDPI: Bool

    var label: String {
        var parts = ["\(width) x \(height)"]
        if isHiDPI { parts.append("HiDPI") }
        if refreshRate > 1 {
            parts.append("\(Int(refreshRate.rounded())) Hz")
        }
        return parts.joined(separator: " - ")
    }
}

enum DisplayScaleChoice: String, CaseIterable, Identifiable {
    case native, hiDPI
    var id: String { rawValue }
}

struct ManagedDisplay: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let uuid: String
    let name: String
    let isBuiltIn: Bool
    let isMain: Bool
    let vendorID: UInt32
    let productID: UInt32
    let pointWidth: Int
    let pointHeight: Int
    let originX: Int
    let originY: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let currentModeID: Int32?
    let currentModeLabel: String
    let modes: [DisplayResolutionMode]

    var nativeMode: DisplayResolutionMode? {
        modes.filter { !$0.isHiDPI }.max {
            if $0.pixelWidth != $1.pixelWidth { return $0.pixelWidth < $1.pixelWidth }
            return $0.pixelHeight < $1.pixelHeight
        }
    }

    var bestHiDPIMode: DisplayResolutionMode? {
        modes.filter(\.isHiDPI).max {
            if $0.width != $1.width { return $0.width < $1.width }
            if $0.height != $1.height { return $0.height < $1.height }
            return $0.refreshRate < $1.refreshRate
        }
    }

    static func == (lhs: ManagedDisplay, rhs: ManagedDisplay) -> Bool {
        lhs.id == rhs.id
            && lhs.currentModeID == rhs.currentModeID
            && lhs.isMain == rhs.isMain
            && lhs.originX == rhs.originX
            && lhs.originY == rhs.originY
            && lhs.pointWidth == rhs.pointWidth
            && lhs.pointHeight == rhs.pointHeight
            && lhs.modes == rhs.modes
    }
}

struct DisplayImageAdjustment: Codable, Equatable {
    var contrast: Double = 0
    var gamma: Double = 0
    var gain: Double = 0
    var warmth: Double = 0
    var inverted: Bool = false
    var paused: Bool = false

    var isNeutral: Bool {
        contrast == 0 && gamma == 0 && gain == 0 && warmth == 0 && !inverted
    }
}

struct ManagedColorProfile: Identifiable, Equatable {
    let name: String
    let path: URL
    let colorSpace: String

    var id: String { path.path }
}

struct DisplayManagementPreset: Identifiable, Codable, Equatable {
    struct Entry: Codable, Equatable {
        let displayUUID: String
        let modeID: Int32?
        let brightness: Double?
        let colorProfilePath: String?
        let hdrEnabled: Bool?
        let originX: Int?
        let originY: Int?
        let isMain: Bool?
    }

    var id = UUID()
    var name: String
    var createdAt = Date()
    var entries: [Entry]
}

@MainActor
final class DisplayManagementService: ObservableObject {
    static let shared = DisplayManagementService()

    @Published private(set) var displays: [ManagedDisplay] = []
    @Published private(set) var presets: [DisplayManagementPreset] = []
    @Published private(set) var colorProfiles: [ManagedColorProfile] = []
    @Published private(set) var activeProfileByDisplayID: [CGDirectDisplayID: URL] = [:]
    @Published private(set) var nightShiftAvailable = false
    @Published private(set) var trueToneAvailable = false
    @Published private(set) var imageAdjustments: [CGDirectDisplayID: DisplayImageAdjustment] = [:]
    @Published var nightShiftEnabled = false
    @Published var trueToneEnabled = false
    @Published private(set) var lastError: String?

    private let presetsKey = "displayManagementPresets"
    private let queue = DispatchQueue(label: "com.vorssaint.utils.display-management", qos: .userInitiated)
    private var blueLightClient: NSObject?
    private var trueToneClient: NSObject?
    private var screenObserver: NSObjectProtocol?

    private var strings: DisplayManagementStrings {
        FeatureStrings.displayManagement(L10n.shared.language)
    }

    private func failure(_ action: String, display: ManagedDisplay) -> String {
        "\(action): \(display.name)"
    }

    private init() {
        loadPresets()
        configureSystemEffects()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.screenParametersChanged()
            }
        }
    }

    func refresh() {
        refreshDisplays()
        refreshSystemEffects()
        loadColorProfilesIfNeeded()
    }

    func clearError() {
        lastError = nil
    }

    func setMode(_ mode: DisplayResolutionMode, for display: ManagedDisplay) {
        lastError = nil
        queue.async {
            let success = Self.applyModeID(mode.id, to: display.id)
            DispatchQueue.main.async {
                if success {
                    self.refreshDisplays()
                } else {
                    self.lastError = self.failure(self.strings.resolution, display: display)
                }
            }
        }
    }

    func setScale(_ choice: DisplayScaleChoice, for display: ManagedDisplay) {
        let target: DisplayResolutionMode?
        switch choice {
        case .native: target = display.nativeMode
        case .hiDPI: target = display.bestHiDPIMode
        }
        guard let target else {
            let mode = choice == .hiDPI ? "HiDPI" : strings.native
            lastError = failure("\(strings.scale) — \(mode)", display: display)
            return
        }
        setMode(target, for: display)
    }

    func setMainDisplay(_ display: ManagedDisplay) {
        guard !display.isMain else { return }
        let snapshot = displays
        queue.async {
            let success = Self.applyMainDisplay(display.id, among: snapshot)
            DispatchQueue.main.async {
                if success {
                    self.refreshDisplays()
                } else {
                    self.lastError = self.failure(self.strings.makeMain, display: display)
                }
            }
        }
    }

    func setDisplayPosition(_ display: ManagedDisplay, x: Int, y: Int) {
        let snapshot = displays
        queue.async {
            let success = Self.applyPosition(display.id, x: x, y: y, among: snapshot)
            DispatchQueue.main.async {
                if success {
                    self.refreshDisplays()
                } else {
                    self.lastError = self.failure(self.strings.arrangement, display: display)
                }
            }
        }
    }

    func savePreset(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let brightnessByID = Dictionary(uniqueKeysWithValues:
            BrightnessService.shared.displays.map { ($0.id, $0.brightness) })
        let entries = displays.map { display in
            DisplayManagementPreset.Entry(
                displayUUID: display.uuid,
                modeID: display.currentModeID,
                brightness: brightnessByID[display.id],
                colorProfilePath: activeProfileByDisplayID[display.id]?.path,
                hdrEnabled: nil,
                originX: display.originX,
                originY: display.originY,
                isMain: display.isMain
            )
        }
        presets.insert(DisplayManagementPreset(name: trimmed, entries: entries), at: 0)
        savePresets()
    }

    func deletePreset(_ preset: DisplayManagementPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }

    func renamePreset(_ preset: DisplayManagementPreset, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index].name = trimmed
        savePresets()
    }

    func updatePresetFromCurrentDisplays(_ preset: DisplayManagementPreset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        let name = presets[index].name
        let brightnessByID = Dictionary(uniqueKeysWithValues:
            BrightnessService.shared.displays.map { ($0.id, $0.brightness) })
        presets[index].entries = displays.map { display in
            DisplayManagementPreset.Entry(
                displayUUID: display.uuid,
                modeID: display.currentModeID,
                brightness: brightnessByID[display.id],
                colorProfilePath: activeProfileByDisplayID[display.id]?.path,
                hdrEnabled: nil,
                originX: display.originX,
                originY: display.originY,
                isMain: display.isMain
            )
        }
        presets[index].name = name
        savePresets()
    }

    func applyPreset(_ preset: DisplayManagementPreset) {
        lastError = nil
        let displayByUUID = Dictionary(uniqueKeysWithValues: displays.map { ($0.uuid, $0) })
        let arrangementEntries = preset.entries.compactMap { entry -> (displayID: CGDirectDisplayID, x: Int, y: Int)? in
            guard let display = displayByUUID[entry.displayUUID],
                  let x = entry.originX,
                  let y = entry.originY else { return nil }
            return (display.id, x, y)
        }
        for entry in preset.entries {
            guard let display = displayByUUID[entry.displayUUID] else { continue }
            if let modeID = entry.modeID, display.currentModeID != modeID {
                _ = Self.applyModeID(modeID, to: display.id)
            }
            if let profilePath = entry.colorProfilePath,
               let profile = colorProfiles.first(where: { $0.path.path == profilePath }) {
                _ = Self.setColorProfile(profile.path, for: display.id)
            }
            if let brightness = entry.brightness,
               BrightnessService.shared.displays.contains(where: { $0.id == display.id }) {
                BrightnessService.shared.setBrightness(brightness, for: display.id)
            }
        }
        if !arrangementEntries.isEmpty {
            _ = Self.applyOrigins(arrangementEntries)
        }
        refreshDisplays()
        refreshActiveProfiles()
    }

    func setColorProfile(_ profile: ManagedColorProfile, for display: ManagedDisplay) {
        lastError = nil
        let success = Self.setColorProfile(profile.path, for: display.id)
        if success {
            activeProfileByDisplayID[display.id] = profile.path
        } else {
            lastError = failure("\(strings.colorProfile) — \(profile.name)", display: display)
        }
    }

    func resetColorProfile(for display: ManagedDisplay) {
        lastError = nil
        let success = Self.clearColorProfile(for: display.id)
        if success {
            activeProfileByDisplayID.removeValue(forKey: display.id)
            refreshActiveProfiles()
        } else {
            lastError = failure("\(strings.colorProfile) — \(strings.systemDefault)",
                                display: display)
        }
    }

    func setNightShift(_ enabled: Bool) {
        guard let blueLightClient else { return }
        Self.callSetter(blueLightClient, selectorName: "setEnabled:", value: enabled)
        nightShiftEnabled = enabled
    }

    func setTrueTone(_ enabled: Bool) {
        guard let trueToneClient else { return }
        Self.callSetter(trueToneClient, selectorName: "setEnabled:", value: enabled)
        trueToneEnabled = enabled
    }

    func setImageAdjustment(_ adjustment: DisplayImageAdjustment, for display: ManagedDisplay) {
        imageAdjustments[display.id] = adjustment
        BrightnessService.shared.setImageAdjustment(adjustment.paused ? nil : adjustment,
                                                   for: display.id)
    }

    func resetImageAdjustment(for display: ManagedDisplay) {
        imageAdjustments.removeValue(forKey: display.id)
        BrightnessService.shared.setImageAdjustment(nil, for: display.id)
    }

    private func refreshDisplays() {
        let newDisplays = Self.onlineDisplays()
        displays = newDisplays
        imageAdjustments = imageAdjustments.filter { id, _ in
            newDisplays.contains { $0.id == id }
        }
        refreshActiveProfiles()
    }

    private func screenParametersChanged() {
        refresh()
    }

    nonisolated private static func onlineDisplays() -> [ManagedDisplay] {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else { return [] }

        return ids.prefix(Int(count)).compactMap { id in
            guard CGDisplayIsActive(id) != 0 else { return nil }
            let current = CGDisplayCopyDisplayMode(id)
            let modes = displayModes(for: id)
            let currentMode = current.flatMap { mode in
                modes.first { $0.id == mode.ioDisplayModeID }
            }
            let name = NSScreen.screens.first {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id
            }?.localizedName ?? "Display \(id)"
            let bounds = CGDisplayBounds(id)
            return ManagedDisplay(
                id: id,
                uuid: displayUUID(id),
                name: name,
                isBuiltIn: CGDisplayIsBuiltin(id) != 0,
                isMain: CGDisplayIsMain(id) != 0,
                vendorID: CGDisplayVendorNumber(id),
                productID: CGDisplayModelNumber(id),
                pointWidth: Int(bounds.width.rounded()),
                pointHeight: Int(bounds.height.rounded()),
                originX: Int(bounds.origin.x.rounded()),
                originY: Int(bounds.origin.y.rounded()),
                pixelWidth: CGDisplayPixelsWide(id),
                pixelHeight: CGDisplayPixelsHigh(id),
                currentModeID: current?.ioDisplayModeID,
                currentModeLabel: currentMode?.label ?? "\(CGDisplayPixelsWide(id)) x \(CGDisplayPixelsHigh(id))",
                modes: modes
            )
        }
    }

    nonisolated private static func displayModes(for displayID: CGDirectDisplayID) -> [DisplayResolutionMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
        guard let rawModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return []
        }
        var seen = Set<String>()
        return rawModes.compactMap { mode in
            guard mode.width >= 640, mode.height >= 480 else { return nil }
            let refresh = mode.refreshRate
            let hiDPI = mode.pixelWidth > mode.width || mode.pixelHeight > mode.height
            let key = "\(mode.width)x\(mode.height):\(mode.pixelWidth)x\(mode.pixelHeight):\(Int(refresh.rounded())):\(hiDPI)"
            guard seen.insert(key).inserted else { return nil }
            return DisplayResolutionMode(
                id: mode.ioDisplayModeID,
                width: mode.width,
                height: mode.height,
                pixelWidth: mode.pixelWidth,
                pixelHeight: mode.pixelHeight,
                refreshRate: refresh,
                isHiDPI: hiDPI
            )
        }
        .sorted {
            if $0.pixelWidth != $1.pixelWidth { return $0.pixelWidth > $1.pixelWidth }
            if $0.pixelHeight != $1.pixelHeight { return $0.pixelHeight > $1.pixelHeight }
            return $0.refreshRate > $1.refreshRate
        }
    }

    nonisolated private static func applyModeID(_ modeID: Int32, to displayID: CGDirectDisplayID) -> Bool {
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
        guard let rawModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode],
              let mode = rawModes.first(where: { $0.ioDisplayModeID == modeID }) else {
            return false
        }
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
        guard CGConfigureDisplayWithDisplayMode(config, displayID, mode, nil) == .success else {
            CGCancelDisplayConfiguration(config)
            return false
        }
        return CGCompleteDisplayConfiguration(config, .forSession) == .success
    }

    nonisolated private static func applyOrigins(_ origins: [(displayID: CGDirectDisplayID, x: Int, y: Int)]) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
        for origin in origins {
            CGConfigureDisplayOrigin(config, origin.displayID, Int32(origin.x), Int32(origin.y))
        }
        let complete = CGCompleteDisplayConfiguration(config, .forSession)
        if complete != .success {
            CGCancelDisplayConfiguration(config)
            return false
        }
        return true
    }

    nonisolated private static func applyMainDisplay(_ displayID: CGDirectDisplayID,
                                                     among displays: [ManagedDisplay]) -> Bool {
        guard let target = displays.first(where: { $0.id == displayID }) else { return false }
        let dx = target.originX
        let dy = target.originY
        let shifted = displays.map { display in
            (display.id, display.originX - dx, display.originY - dy)
        }
        return applyOrigins(shifted)
    }

    nonisolated private static func applyPosition(_ displayID: CGDirectDisplayID,
                                                  x: Int,
                                                  y: Int,
                                                  among displays: [ManagedDisplay]) -> Bool {
        var origins = displays.map { display in
            (display.id, display.id == displayID ? x : display.originX,
             display.id == displayID ? y : display.originY)
        }
        if let main = displays.first(where: \.isMain),
           let proposedMain = origins.first(where: { $0.0 == main.id }),
           proposedMain.1 != 0 || proposedMain.2 != 0 {
            let dx = proposedMain.1
            let dy = proposedMain.2
            origins = origins.map { ($0.0, $0.1 - dx, $0.2 - dy) }
        }
        return applyOrigins(origins.map { ($0.0, $0.1, $0.2) })
    }


    private func loadColorProfilesIfNeeded() {
        guard colorProfiles.isEmpty else {
            refreshActiveProfiles()
            return
        }
        queue.async {
            let profiles = Self.enumerateColorProfiles()
            DispatchQueue.main.async {
                self.colorProfiles = profiles
                self.refreshActiveProfiles()
            }
        }
    }

    nonisolated private static func enumerateColorProfiles() -> [ManagedColorProfile] {
        let roots = [
            URL(fileURLWithPath: "/Library/ColorSync/Profiles", isDirectory: true),
            URL(fileURLWithPath: "/System/Library/ColorSync/Profiles", isDirectory: true),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/ColorSync/Profiles", isDirectory: true),
        ]
        var seen = Set<String>()
        var result: [ManagedColorProfile] = []
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                let ext = url.pathExtension.lowercased()
                guard ext == "icc" || ext == "icm", seen.insert(url.path).inserted else { continue }
                result.append(profile(from: url))
            }
        }
        return result.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    nonisolated private static func profile(from url: URL) -> ManagedColorProfile {
        var name = url.deletingPathExtension().lastPathComponent
        var colorSpace = "RGB"
        if let rawProfile = ColorSyncProfileCreateWithURL(url as CFURL, nil) {
            let profile = rawProfile.takeRetainedValue()
            if let rawDescription = ColorSyncProfileCopyDescriptionString(profile) {
                name = rawDescription.takeRetainedValue() as String
            }
            if let header = ColorSyncProfileCopyHeader(profile)?.takeRetainedValue() as Data?,
               header.count >= 20,
               let tag = String(bytes: header[16..<20], encoding: .ascii) {
                colorSpace = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ManagedColorProfile(name: name, path: url, colorSpace: colorSpace.isEmpty ? "RGB" : colorSpace)
    }

    private func refreshActiveProfiles() {
        var active: [CGDirectDisplayID: URL] = [:]
        for display in displays {
            if let url = Self.activeProfileURL(for: display.id) {
                active[display.id] = url
            }
        }
        activeProfileByDisplayID = active
    }

    nonisolated private static func activeProfileURL(for displayID: CGDirectDisplayID) -> URL? {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue(),
              let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let profileKey = kColorSyncDeviceDefaultProfileID?.takeUnretainedValue(),
              let rawInfo = ColorSyncDeviceCopyDeviceInfo(deviceClass, uuid) else {
            return nil
        }
        let info = rawInfo.takeRetainedValue() as NSDictionary
        guard let factory = info["FactoryProfiles"] as? NSDictionary,
              let activeMode = factory[profileKey] else { return nil }
        if let custom = info["CustomProfiles"] as? NSDictionary,
           let value = custom[activeMode],
           let url = urlValue(value) {
            return url
        }
        if let mode = factory[activeMode] as? NSDictionary,
           let value = mode["DeviceProfileURL"],
           let url = urlValue(value) {
            return url
        }
        return nil
    }

    nonisolated private static func setColorProfile(_ url: URL, for displayID: CGDirectDisplayID) -> Bool {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue(),
              let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let profileKey = kColorSyncDeviceDefaultProfileID?.takeUnretainedValue() else {
            return false
        }
        let info: NSDictionary = [profileKey: url as NSURL]
        return ColorSyncDeviceSetCustomProfiles(deviceClass, uuid, info as CFDictionary)
    }

    nonisolated private static func clearColorProfile(for displayID: CGDirectDisplayID) -> Bool {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue(),
              let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let profileKey = kColorSyncDeviceDefaultProfileID?.takeUnretainedValue() else {
            return false
        }
        let info: NSDictionary = [profileKey: NSNull()]
        return ColorSyncDeviceSetCustomProfiles(deviceClass, uuid, info as CFDictionary)
    }

    nonisolated private static func urlValue(_ value: Any) -> URL? {
        if let url = value as? URL { return url }
        if let url = value as? NSURL { return url as URL }
        if let string = value as? String { return URL(string: string) ?? URL(fileURLWithPath: string) }
        return nil
    }

    private func configureSystemEffects() {
        guard dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY) != nil else {
            return
        }
        if let type = NSClassFromString("CBBlueLightClient") as? NSObject.Type {
            blueLightClient = type.init()
            nightShiftAvailable = blueLightClient != nil
        }
        if let type = NSClassFromString("CBTrueToneClient") as? NSObject.Type {
            trueToneClient = type.init()
            trueToneAvailable = trueToneClient.map {
                Self.callBool($0, selectorName: "supported") && Self.callBool($0, selectorName: "available")
            } ?? false
        }
        refreshSystemEffects()
    }

    private func refreshSystemEffects() {
        if let blueLightClient {
            var bytes = [UInt8](repeating: 0, count: 64)
            let selector = NSSelectorFromString("getBlueLightStatus:")
            if blueLightClient.responds(to: selector) {
                typealias Fn = @convention(c) (NSObject, Selector, UnsafeMutableRawPointer) -> Bool
                let ok = bytes.withUnsafeMutableBytes {
                    unsafeBitCast(blueLightClient.method(for: selector), to: Fn.self)(
                        blueLightClient, selector, $0.baseAddress!)
                }
                if ok { nightShiftEnabled = bytes[1] != 0 }
            }
        }
        if let trueToneClient, trueToneAvailable {
            trueToneEnabled = Self.callBool(trueToneClient, selectorName: "enabled")
        }
    }

    private static func callBool(_ object: NSObject, selectorName: String) -> Bool {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return false }
        typealias Fn = @convention(c) (NSObject, Selector) -> Bool
        return unsafeBitCast(object.method(for: selector), to: Fn.self)(object, selector)
    }

    private static func callSetter(_ object: NSObject, selectorName: String, value: Bool) {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return }
        typealias Fn = @convention(c) (NSObject, Selector, Bool) -> Void
        unsafeBitCast(object.method(for: selector), to: Fn.self)(object, selector, value)
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: presetsKey),
              let decoded = try? JSONDecoder().decode([DisplayManagementPreset].self, from: data) else {
            presets = []
            return
        }
        presets = decoded
    }

    private func savePresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: presetsKey)
    }

    nonisolated private static func displayUUID(_ displayID: CGDirectDisplayID) -> String {
        if let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue(),
           let string = CFUUIDCreateString(nil, uuid) {
            return string as String
        }
        return "\(CGDisplayVendorNumber(displayID)):\(CGDisplayModelNumber(displayID)):\(CGDisplaySerialNumber(displayID))"
    }

}
