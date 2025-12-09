//
//  HeadlessViewModel.swift
//  Headless
//
//  Created by Mario Gamal on 28/10/2025.
//


import Foundation
import os
import Combine
import ProximityReader


public class HeadlessViewModel: ObservableObject, @unchecked Sendable {
    
    private var currentPaymentData: PaymentCardReadResult?
    private var currentReadError: PaymentCardReaderSession.ReadError?
    private var reader: PaymentCardReader?
    private var session: PaymentCardReaderSession?

    private var lastPspTokenUsed = PaymentCardReader.Token(rawValue: "")

    @MainActor @Published public var outputMessage: String = "Not Ready"

    public init() {
        reader = PaymentCardReader()
    }

    public func prepareReader() {
        Task {
            do {
                let token = try await TokenProvider.shared.fetchToken()
                session = try await reader?.prepare(using: token)
                let readerID = try await reader?.readerIdentifier ?? ""
                Task { @MainActor in
                    self.outputMessage = "Reader ready with ID: \(readerID.prefix(8))..."
                }
            } catch {
                await handlePaymentCardReaderError(error)
            }
        }
    }
    
    
    public func pay(amount: Decimal, currency: String) {
        Task {
            guard let session = session else {
                Task { @MainActor in
                    self.outputMessage = "No active session. Call prepareReader() first."
                }
                return
            }

            do {
                let request = PaymentCardTransactionRequest(amount: amount, currencyCode: currency, for: .purchase)
                let result: PaymentCardReadResult?
                result = try await session.readPaymentCard(request)

                if let payment = result {
                    self.currentPaymentData = payment
                    Task { @MainActor in
                        self.outputMessage = "Payment Approved, trxId: \(payment.id)"
                    }
                } else {
                    Task { @MainActor in
                        self.outputMessage = "Unknown result"
                    }
                }

            } catch {
                if let err = error as? PaymentCardReaderSession.ReadError {
                    self.currentReadError = err
                    Task { @MainActor in
                        self.outputMessage = "\(err.errorDescription)"
                    }
                } else {
                    Task { @MainActor in
                        self.outputMessage = "Unexpected error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    @MainActor private func handlePaymentCardReaderError(_ error: Error) {
        guard let err = error as? PaymentCardReaderError else {
            outputMessage = "Unexpected error: \(String(describing: error))"
            return
        }
        switch err {
        case .accountNotLinked:
            outputMessage = "Account not linked. Call linkAccount()."
        case .tokenExpired:
            outputMessage = "Reader token expired. Fetch a new token."
        default:
            outputMessage = "Error: \(err.errorName)"
        }
    }
    
}
