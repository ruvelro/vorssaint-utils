// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Resolution, arrangement, color profile, preset and image-adjustment
/// controls. Kept out of the already broad Energy settings view so display
/// work does not collide with every other energy feature.
struct DisplayManagementSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = DisplayManagementService.shared
    @State private var newPresetName = ""
    @State private var expandedDisplayIDs = Set<CGDirectDisplayID>()

    private var strings: DisplayManagementStrings {
        FeatureStrings.displayManagement(l10n.language)
    }

    var body: some View {
        Group {
            Section(strings.section) {
                if service.displays.isEmpty {
                    SettingsCaptionText(strings.empty)
                } else {
                    ForEach(service.displays) { display in
                        displayRow(display)
                    }
                }
                if let error = service.lastError {
                    SettingsCaptionText(error)
                        .foregroundStyle(.red)
                }
            }

            if service.displays.count > 1 {
                Section(strings.arrangement) {
                    DisplayArrangementCanvas(displays: service.displays) { display, x, y in
                        service.setDisplayPosition(display, x: x, y: y)
                    }
                }
            }

            Section(strings.presets) {
                HStack {
                    TextField(strings.presetName, text: $newPresetName)
                    Button {
                        service.savePreset(named: newPresetName)
                        newPresetName = ""
                    } label: {
                        Label(strings.save, systemImage: "plus")
                    }
                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if service.presets.isEmpty {
                    SettingsCaptionText(strings.emptyPresets)
                } else {
                    ForEach(service.presets) { preset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                TextField(strings.presetName, text: Binding(
                                    get: { preset.name },
                                    set: { service.renamePreset(preset, to: $0) }))
                                Text(displayCountLabel(preset.entries.count))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                service.applyPreset(preset)
                            } label: {
                                Label(strings.apply, systemImage: "play.fill")
                            }
                            Button {
                                service.updatePresetFromCurrentDisplays(preset)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.plain)
                            .help(strings.updatePreset)
                            Button {
                                service.deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .help(strings.deletePreset)
                        }
                    }
                }
            }

            if service.nightShiftAvailable || service.trueToneAvailable {
                Section(strings.effects) {
                    if service.nightShiftAvailable {
                        Toggle("Night Shift", isOn: Binding(
                            get: { service.nightShiftEnabled },
                            set: { service.setNightShift($0) }))
                    }
                    if service.trueToneAvailable {
                        Toggle("True Tone", isOn: Binding(
                            get: { service.trueToneEnabled },
                            set: { service.setTrueTone($0) }))
                    }
                    SettingsCaptionText(strings.effectsCaption)
                }
            }
        }
        .onAppear { service.refresh() }
    }

    @ViewBuilder
    private func displayRow(_ display: ManagedDisplay) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expandedDisplayIDs.contains(display.id) },
            set: { expanded in
                if expanded {
                    expandedDisplayIDs.insert(display.id)
                } else {
                    expandedDisplayIDs.remove(display.id)
                }
            })) {
            VStack(alignment: .leading, spacing: 10) {
                Picker(strings.resolution, selection: Binding(
                    get: { display.currentModeID ?? 0 },
                    set: { modeID in
                        guard let mode = display.modes.first(where: { $0.id == modeID }) else { return }
                        service.setMode(mode, for: display)
                    })) {
                    ForEach(display.modes) { mode in
                        Text(mode.label).tag(mode.id)
                    }
                }
                .disabled(display.modes.isEmpty)

                HStack {
                    Text(strings.scale)
                    Spacer()
                    Button(strings.native) { service.setScale(.native, for: display) }
                        .disabled(display.nativeMode == nil)
                    Button("HiDPI") { service.setScale(.hiDPI, for: display) }
                        .disabled(display.bestHiDPIMode == nil)
                }

                Picker(strings.colorProfile, selection: Binding(
                    get: { service.activeProfileByDisplayID[display.id]?.path ?? "" },
                    set: { path in
                        if path.isEmpty {
                            service.resetColorProfile(for: display)
                        } else if let profile = service.colorProfiles.first(where: { $0.path.path == path }) {
                            service.setColorProfile(profile, for: display)
                        }
                    })) {
                    Text(strings.systemDefault).tag("")
                    ForEach(service.colorProfiles) { profile in
                        Text(profile.name).tag(profile.path.path)
                    }
                }
                .disabled(service.colorProfiles.isEmpty)

                if !display.isMain {
                    Button {
                        service.setMainDisplay(display)
                    } label: {
                        Label(strings.makeMain, systemImage: "menubar.rectangle")
                    }
                }

                imageAdjustmentControls(for: display)
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(display.name)
                    Text(display.currentModeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if display.isMain {
                    Text(strings.main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func displayCountLabel(_ count: Int) -> String {
        count == 1 ? strings.displayCountSingular
            : String(format: strings.displayCountPlural, count)
    }

    private func imageAdjustmentControls(for display: ManagedDisplay) -> some View {
        let adjustment = service.imageAdjustments[display.id] ?? DisplayImageAdjustment()
        return DisclosureGroup(strings.imageAdjustments) {
            VStack(alignment: .leading, spacing: 8) {
                imageSlider(strings.contrast, value: adjustment.contrast, display: display) {
                    var next = adjustment; next.contrast = $0; return next
                }
                imageSlider(strings.gamma, value: adjustment.gamma, display: display) {
                    var next = adjustment; next.gamma = $0; return next
                }
                imageSlider(strings.gain, value: adjustment.gain, display: display) {
                    var next = adjustment; next.gain = $0; return next
                }
                imageSlider(strings.warmth, value: adjustment.warmth, display: display) {
                    var next = adjustment; next.warmth = $0; return next
                }
                Toggle(strings.invertColors, isOn: Binding(
                    get: { adjustment.inverted },
                    set: {
                        var next = adjustment
                        next.inverted = $0
                        service.setImageAdjustment(next, for: display)
                    }))
                Toggle(strings.pauseAdjustments, isOn: Binding(
                    get: { adjustment.paused },
                    set: {
                        var next = adjustment
                        next.paused = $0
                        service.setImageAdjustment(next, for: display)
                    }))
                Button(strings.reset) { service.resetImageAdjustment(for: display) }
            }
            .padding(.top, 4)
        }
    }

    private func imageSlider(_ title: String,
                             value: Double,
                             display: ManagedDisplay,
                             update: @escaping (Double) -> DisplayImageAdjustment) -> some View {
        HStack {
            Text(title)
            Slider(value: Binding(
                get: { value },
                set: { service.setImageAdjustment(update($0), for: display) }),
                   in: -100...100,
                   step: 1)
            Text("\(Int(value.rounded()))")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private struct DisplayArrangementCanvas: View {
    let displays: [ManagedDisplay]
    let onMove: (ManagedDisplay, Int, Int) -> Void
    @State private var activeDrag: (displayID: CGDirectDisplayID, offset: CGSize)?

    var body: some View {
        GeometryReader { geometry in
            let layout = arrangementLayout(in: geometry.size)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18))
                ForEach(displays) { display in
                    if let frame = layout.frames[display.id] {
                        displayTile(display, frame: frame, scale: layout.scale)
                    }
                }
            }
        }
        .frame(minHeight: 180)
    }

    private func displayTile(_ display: ManagedDisplay, frame: CGRect, scale: CGFloat) -> some View {
        let dragOffset = activeDrag?.displayID == display.id ? activeDrag?.offset ?? .zero : .zero
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(display.isMain ? Color.accentColor.opacity(0.24) : Color.secondary.opacity(0.13))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(display.isMain ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    Text(display.name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("\(display.pixelWidth)x\(display.pixelHeight)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            )
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX + dragOffset.width, y: frame.midY + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in activeDrag = (display.id, value.translation) }
                    .onEnded { value in
                        activeDrag = nil
                        let nextX = display.originX + Int((value.translation.width / scale).rounded())
                        let nextY = display.originY + Int((value.translation.height / scale).rounded())
                        onMove(display, nextX, nextY)
                    }
            )
    }

    private func arrangementLayout(in size: CGSize) -> (frames: [CGDirectDisplayID: CGRect],
                                                         scale: CGFloat) {
        guard !displays.isEmpty else { return ([:], 1) }
        let minX = displays.map(\.originX).min() ?? 0
        let minY = displays.map(\.originY).min() ?? 0
        let maxX = displays.map { $0.originX + $0.pointWidth }.max() ?? 1
        let maxY = displays.map { $0.originY + $0.pointHeight }.max() ?? 1
        let inset: CGFloat = 16
        let contentWidth = max(CGFloat(maxX - minX), 1)
        let contentHeight = max(CGFloat(maxY - minY), 1)
        let availableWidth = max(size.width - inset * 2, 1)
        let availableHeight = max(size.height - inset * 2, 1)
        let scale = min(availableWidth / contentWidth, availableHeight / contentHeight)
        let xOffset = (size.width - contentWidth * scale) / 2
        let yOffset = (size.height - contentHeight * scale) / 2
        let frames = Dictionary(uniqueKeysWithValues: displays.map { display in
            let x = CGFloat(display.originX - minX) * scale + xOffset
            let y = CGFloat(display.originY - minY) * scale + yOffset
            let width = max(CGFloat(display.pointWidth) * scale, 72)
            let height = max(CGFloat(display.pointHeight) * scale, 44)
            return (display.id, CGRect(x: x, y: y, width: width, height: height))
        })
        return (frames, max(scale, 0.0001))
    }
}
