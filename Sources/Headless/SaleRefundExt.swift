//
//  HeadlessServiceSale.swift
//  Headless
//
//  Created by Mario Gamal on 31/10/2025.
//

import Foundation
import ProximityReader

// MARK: - Dummy should be changed
public struct LaunchRequestSuccess: Sendable {
    public let outcome: HeadlessReadOutcome
}

public enum HeadlessReadOutcome: String, Codable, Sendable {
    case success
    case cardDeclined
    case failure
}

@inline(__always)
public func mapOutcome(from result: PaymentCardReadResult) -> HeadlessReadOutcome {
        switch result.outcome {
        case .success:      return .success
        case .cardDeclined: return .cardDeclined
        case .failure:      return .failure
        @unknown default:
            return .failure
        }
}


// MARK: - map TranType to Apple's type
@inline(__always)
private func mapToTransactionType(_ tranType: TranType) -> PaymentCardTransactionRequest.TransactionType {
    switch tranType {
    case .sale:
        return .purchase
    case .refund:
        return .refund
    }
}

public extension HeadlessService {
    
    func launchRequest(_ poiRequest: PoiRequest) async -> Result<TransactionResponse, HeadlessError> {
        
        do {
            try await ensurePreparedSession()
        } catch {
            return .failure(.reader("Unable to prepare reader: \(error)"))
        }
        

        if poiRequest.tranType == .refund, poiRequest.linkedTranId == nil {
            return .failure(.reader("linkedTranId is required for REFUND transactions."))
        }

        guard let decimalAmount = Decimal(string: poiRequest.amount.value) else {
            return .failure(.reader("Invalid amount value '\(poiRequest.amount.value)'."))
        }
        let currencyCode = poiRequest.amount.currency

        let tranType = mapToTransactionType(poiRequest.tranType)
        let request = PaymentCardTransactionRequest(
            amount: decimalAmount,
            currencyCode: currencyCode,
            for: tranType
        )

        do {
            let readResult = try await session!.readPaymentCard(request)
            let transactionResponse = try await processReadResult(readResult: readResult, poiRequest: poiRequest)
            return .success(transactionResponse)
        } catch let readError as PaymentCardReaderSession.ReadError {
            return .failure(.reader("Read failed: \(readError)"))
        } catch let headlessError as HeadlessError {
            return .failure(headlessError)
        } catch {
            return .failure(.reader("Read failed: \(error)"))
        }
    }
    
    /**
     * Asynchronously processes the card read result by building
     * both EMV and AppleTTP data.
     */
    private func processReadResult(readResult: PaymentCardReadResult, poiRequest: PoiRequest) async throws -> TransactionResponse {
        
        //Here we will build the glue request
        
        let emvData = getEmvData(from: readResult)

        let appleTTP = await self.getAppleTTP(from: readResult)
        
        let readerInfo = self.getDumpReader()
        
        let cardRead = self.buildCardRead(
            from: readResult,
            emv: emvData,
            ttp: appleTTP,
            reader: readerInfo
        )

        let client = getDumpClient()
        
        let request = TransactionRequest(
            poiRequest: poiRequest,
            client: client,
            cardRead: cardRead,
            sdkId: ""
        )
        
        let customHeaders = buildCommonHeaders()

        let apiEndpoint = APIEndpoint.createTransaction(request)
        
        do {
            let response: TransactionResponse = try await network.send(
                apiEndpoint,
                extraHeaders: customHeaders
            )
            
            print("Successfully received response!")
            print("Transaction ID:", response.tranId)
            print("Status:", response.tranStatus)
            
            return response
        } catch let netError as NetError {
            switch netError {
            case .badStatus(let code, let errorBody):
                let errorMsg: String
                // Here's the new part:
                if let body = errorBody, let errorString = String(data: body, encoding: .utf8) {
                    errorMsg = "HTTP \(code): \(errorString)"
                } else {
                    print("Error Body: (Could not parse error body)")
                    errorMsg = "HTTP \(code): Unknown error"
                }
                print("Network Error: \(errorMsg)")
                throw HeadlessError.network(errorMsg)
            case .decodingFailed:
                print("Network Error: Failed to decode successful response")
                throw HeadlessError.network("Network failure:Failed to decode response")
            default:
                print("Network Error: \(netError)")
                throw HeadlessError.network("Network failure: \(netError)")
            }
        } catch {
            throw HeadlessError.transaction("Unexpected error: \(error.localizedDescription)")
        }
        
    }

    
    
    /**
     * Creates the EMV data dictionary from the card read result.
     * Assumes 'buildEmvData(fromBase64:)' is another function available in this class.
     */
    func getEmvData(from readResult: PaymentCardReadResult) -> [String: String] {
        var emvData: [String: String]
        
        if let generalData = readResult.generalCardData {
            emvData = buildEmvData(fromBase64: generalData)
        } else {
            emvData = [:]
        }
        emvData["9F33"] = "0068C8" //TODO
        emvData.removeValue(forKey: "57")
        return emvData
    }
    
    /**
     * Asynchronously builds the AppleTTP object.
     * Assumes 'lastToken' and 'reader' are properties of this class.
     * Assumes 'AppleTTP' is a struct or class you have defined.
     */
    private func getAppleTTP(from readResult: PaymentCardReadResult) async -> AppleTTP {
        
        let readerToken = lastToken?.rawValue ?? ""

        let readerId: String = await {
            guard let reader = reader else { return "" }
            do {
                return try await reader.readerIdentifier
            } catch {
                print("Fetch readerIdentifier failed: \(error)")
                return ""
            }
        }()
        
        let iosTrxId: String = readResult.id
        let protectedPaymentData: String = readResult.paymentCardData ?? ""

        // Create and return the AppleTTP object
        return AppleTTP(
            readerToken: readerToken,
            readerId: readerId,
            iosTrxId: iosTrxId,
            protectedPaymentData: protectedPaymentData
        )
    }
    

    func getDumpReader() -> ReaderInfo {
        return ReaderInfo(
            model: "MineHades",
            brand: "MineSec",
            sdkId: "xxxxxx",
            hardwareSN: "xxxxxxx",
            sdkVersion: "xxxxx",
            firmwareVersion: nil,
            emvKernelVersion: nil
        )
    }
    
    
    func getDumpClient() -> Client {
        return Client(
            app: "com.minesecsoftpos.msa",
            version: "2.10.001.30:1333",
            callEntry: Client.CallEntry.launch,
            ip: "209.191.11.222",
            hostDeviceModel: "Pixel 8",
            hostDeviceBrand: "xxxx"
        )
    }
    
    /**
     * Builds the final CardRead object using component parts
     */
    private func buildCardRead(
        from readResult: PaymentCardReadResult, // Parameter is here for being used later if needed
        emv: [String: String],
        ttp: AppleTTP,
        reader: ReaderInfo
    ) -> CardRead {
        
        // --- Using hardcoded default values ---
        
        let paymentMethod: PaymentMethod = .visa
        let entryMode: EntryMode = .nfc
        let maskedPan: String = "4111********1111"
        let needOnline: Bool = true
        let cardKsn: String = "FF0BFF010015030100000001"
        let cvmPerformed: CVMPerformed = .noCvm
        let pinKsn: String? = nil
        let panToken: String = "PAN_TOKEN"

        return CardRead(
            paymentMethod: paymentMethod,
            entryMode: entryMode,
            maskedPan: maskedPan,
            needOnline: needOnline,
            cardKsn: cardKsn,
            cvmPerformed: cvmPerformed,
            pinKsn: pinKsn,
            panToken: panToken,
            reader: reader,
            appleTTP: ttp,
            emvData: emv
        )
    }
    
}
