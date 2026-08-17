// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreServices
import Foundation

/// Finds files by name in the folders the person named, through the index
/// macOS already keeps.
///
/// Nothing is indexed, watched or remembered here: an empty field does no
/// work, a query is asked of Spotlight once and its answer is thrown away when
/// the bar closes. No permission is asked for either, because what comes back
/// is filtered down to what the person can already see in Finder.
///
/// `MDQuery` rather than `NSMetadataQuery` for one reason: it can be told to
/// stop at a thousand names. A broad word has hundreds of thousands of answers
/// on a full disk, and the newer class has no way to say no to them.
///
/// Not part of the pure-function test harness (`./build.sh --test`): the rules
/// live in `CommandBarFileSearchSupport` and are tested there; what is left is
/// a timer and a call into Spotlight.
final class CommandBarFileSearch {
    /// How long the field has to sit still before Spotlight is asked. Typing
    /// is faster than this, which is the point: a query per keystroke would
    /// ask for eight searches to answer one.
    static let debounce: TimeInterval = 0.12

    /// Called on the main thread when results for some query become ready.
    var onResult: (() -> Void)?

    private var cache: [String: [String]] = [:]
    private var inFlight: Set<String> = []
    private var pendingWorkItem: DispatchWorkItem?
    private var generation = 0

    /// One opening of the bar owns its results. Clearing the session also
    /// stops a search started before it closed from publishing into the next.
    func reset() {
        generation &+= 1
        cancelPending()
        cache.removeAll()
        inFlight.removeAll()
    }

    func cancelPending() {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

    /// The paths already found for exactly this query, or nil while nothing
    /// has been asked for it yet.
    func cachedPaths(for query: String) -> [String]? {
        cache[query]
    }

    /// Asks for this query once the field stops moving. A query already
    /// answered, or already being answered, is left alone.
    func schedule(query: String, scopes: [String], patterns: [String]) {
        guard !scopes.isEmpty,
              CommandBarFileSearchSupport.expression(for: query) != nil,
              cache[query] == nil, !inFlight.contains(query)
        else { return }
        // The newest query is the only one worth waiting for: a search whose
        // text the person has already typed past must never land.
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.execute(query: query, scopes: scopes, patterns: patterns)
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.debounce, execute: workItem)
    }

    private func execute(query: String, scopes: [String], patterns: [String]) {
        guard let expression = CommandBarFileSearchSupport.expression(for: query) else { return }
        let runGeneration = generation
        inFlight.insert(query)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let found = Self.search(expression: expression, scopes: scopes)
            let paths = CommandBarFileSearchSupport.offerable(paths: found, patterns: patterns)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.generation == runGeneration else { return }
                self.inFlight.remove(query)
                self.cache[query] = paths
                // Even an empty answer is an answer: the row that said
                // "looking" has to stop saying it.
                self.onResult?()
            }
        }
    }

    /// The Spotlight call itself, kept inside one synchronous function so the
    /// query object never outlives it.
    private static func search(expression: String, scopes: [String]) -> [String] {
        guard let query = MDQueryCreate(kCFAllocatorDefault, expression as CFString, nil, nil)
        else { return [] }
        MDQuerySetMaxCount(query, CFIndex(CommandBarFileSearchSupport.candidateLimit))
        MDQuerySetSearchScope(query, scopes as CFArray, 0)
        guard MDQueryExecute(query, CFOptionFlags(kMDQuerySynchronous.rawValue)) else { return [] }
        let count = MDQueryGetResultCount(query)
        var paths: [String] = []
        paths.reserveCapacity(min(count, CommandBarFileSearchSupport.candidateLimit))
        for index in 0..<count {
            guard let raw = MDQueryGetResultAtIndex(query, index) else { continue }
            let item = unsafeBitCast(raw, to: MDItem.self)
            guard let path = MDItemCopyAttribute(item, kMDItemPath) as? String else { continue }
            paths.append(path)
        }
        // A name a person recognizes first, then the path, so two Macs with
        // the same files answer in the same order.
        return paths.sorted {
            let left = ($0 as NSString).lastPathComponent
            let right = ($1 as NSString).lastPathComponent
            let byName = left.localizedCaseInsensitiveCompare(right)
            return byName == .orderedSame ? $0 < $1 : byName == .orderedAscending
        }
    }
}
