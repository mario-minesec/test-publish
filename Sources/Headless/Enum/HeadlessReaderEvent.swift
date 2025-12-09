//
//  HeadlessReaderEvent.swift
//  Headless
//
//  Created by Mario Gamal on 31/10/2025.
//

import ProximityReader

public enum HeadlessReaderEvent: Sendable {
    case readyForTap
    case cardDetected
    case pinEntryRequested
    case pinEntryCompleted
    case removeCard
    case readCompleted
    case readCancelled
    case readNotCompleted
    case readRetry
    case notReady
    case progress(Int)
    case uiDismissed
    case unknown(name: String)
}


@inline(__always)
public func mapEvent(_ event: PaymentCardReader.Event) -> HeadlessReaderEvent {
    switch event {
    case .readyForTap: return .readyForTap
    case .cardDetected: return .cardDetected
    case .pinEntryRequested: return .pinEntryRequested
    case .pinEntryCompleted: return .pinEntryCompleted
    case .removeCard: return .removeCard
    case .readCompleted: return .readCompleted
    case .readCancelled: return .readCancelled
    case .readNotCompleted: return .readNotCompleted
    case .readRetry: return .readRetry
    case .notReady: return .notReady
    case .updateProgress(let v): return .progress(v)
    case .userInterfaceDismissed: return .uiDismissed
    @unknown default: return .unknown(name: event.name)
    }
}
