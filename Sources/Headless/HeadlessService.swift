//
//  HeadlessController.swift
//  Headless
//
//  Created by Mario Gamal on 30/10/2025.
//

import Foundation
import ProximityReader

// MARK: - Headless Service
public actor HeadlessService {
    public static let headlessId = "abcdefg"
    public static let headlessVersion = "1.2.01"

    let network = NetworkClient()
    var reader: PaymentCardReader?
    var session: PaymentCardReaderSession?
    var lastToken: PaymentCardReader.Token?
    
    private(set) var license: LicenseModelV3?
    
    public let events: AsyncStream<HeadlessReaderEvent>
    private var eventsCont: AsyncStream<HeadlessReaderEvent>.Continuation?

    public init() {
        var cont: AsyncStream<HeadlessReaderEvent>.Continuation?
        self.events = AsyncStream { cont = $0 }
        self.eventsCont = cont
    }

    private func emit(_ event: HeadlessReaderEvent) {
        _ = eventsCont?.yield(event)
    }

    public func initSoftPOS(profileId: String, licenseFile: String) async -> Result<HeadlessInitSuccess, HeadlessError> {
        guard PaymentCardReader.isSupported else { return .failure(.unsupportedDevice) }

        do {
            //reading license
            let license = try LicenseLoader.loadLicense(from: licenseFile)
            print("License verified: \(license.licenseId), v\(license.customerId), v\(license.licenseVersion)")
            self.license = license
            //fetch token
            let resp: TokenResponse = try await network.send(.fetchToken)
            let token = PaymentCardReader.Token(rawValue: resp.data.token)
            self.lastToken = token
            
            let reader = PaymentCardReader()
            self.reader = reader

            if try await !reader.isAccountLinked(using: token) {
                try await reader.linkAccount(using: token)
            }

            Task {
                for await event in reader.events {
                    self.emit(mapEvent(event))
                }
            }

            self.session = try await reader.prepare(using: token)

            return .success(.init(
                headlessId: Self.headlessId,
                headlessVersion: Self.headlessVersion,
                licenseId: license.licenseId,
                customerId: license.customerId
            ))

        } catch let error as PaymentCardReaderError {
            return .failure(.reader(String(describing: error)))
        } catch let error as LicenseError {
            return .failure(.licenseAnalyze("License verification failed: \(error)"))
        } catch {
            return .failure(.network(error.localizedDescription))
        }
    }
    
    func ensurePreparedSession() async throws {
        guard let reader = self.reader else { throw HeadlessError.reader("Reader not initialized.") }
        guard let token = self.lastToken else { throw HeadlessError.reader("Missing token to prepare reader.") }

        // If session is nil (e.g., app backgrounded), prepare again.
        if self.session == nil {
            self.session = try await reader.prepare(using: token)
        }
    }
}


// ===========================================================
// MARK: - External Components (move to separate files later)
// ===========================================================

public struct HeadlessInitSuccess: Sendable {
    public let headlessId: String
    public let headlessVersion: String
    public let licenseId: String
    public let customerId: String
}




