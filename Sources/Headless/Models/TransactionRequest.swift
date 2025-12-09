//
//  PurchaseRequest.swift
//  Headless
//
//  Created by Mario Gamal on 31/10/2025.
//

import Foundation

// MARK: - Top-level
public struct TransactionRequest: Codable, Sendable {
    public let poiRequest: PoiRequest
    public let client: Client
    public let cardRead: CardRead
    public let sdkId: String

    public init(poiRequest: PoiRequest, client: Client, cardRead: CardRead, sdkId: String) {
        self.poiRequest = poiRequest
        self.client = client
        self.cardRead = cardRead
        self.sdkId = sdkId
    }
}

// MARK: - poiRequest
public struct PoiRequest: Codable, Sendable {
    public let tranType: TranType
    public let amount: Amount
    public let profileId: String
    public let acptId: String?
    public let primaryTid: String?
    public let description: String?
    public let posReference: String
    public let preferredAcceptanceTag: String?
    public let cvmSignatureMode: CVMSignatureMode
    public let forcePaymentMethod: String?
    public let forceFetchProfile: Bool
    public let tapToOwnDevice: Bool
    public let installmentPlan: Int?
    public let linkedTranId: String?
    public let extra: [String: String]?

    public init(
        tranType: TranType,
        amount: Amount,
        profileId: String,
        acptId: String? = nil,
        primaryTid: String? = nil,
        description: String? = nil,
        posReference: String,
        preferredAcceptanceTag: String? = nil,
        cvmSignatureMode: CVMSignatureMode,
        forcePaymentMethod: String? = nil,
        forceFetchProfile: Bool = false,
        tapToOwnDevice: Bool = false,
        installmentPlan: Int? = nil,
        linkedTranId: String? = nil,
        extra: [String: String]? = nil
    ) {
        self.tranType = tranType
        self.amount = amount
        self.profileId = profileId
        self.acptId = acptId
        self.primaryTid = primaryTid
        self.description = description
        self.posReference = posReference
        self.preferredAcceptanceTag = preferredAcceptanceTag
        self.cvmSignatureMode = cvmSignatureMode
        self.forcePaymentMethod = forcePaymentMethod
        self.forceFetchProfile = forceFetchProfile
        self.tapToOwnDevice = tapToOwnDevice
        self.installmentPlan = installmentPlan
        self.linkedTranId = linkedTranId
        self.extra = extra
    }
}

public struct Amount: Codable, Sendable  {
    public let value: String
    public let currency: String
    
    public init(value: String, currency: String) {
        self.value = value
        self.currency = currency
    }
}

public enum TranType: String, Codable, Sendable  {
    case sale = "SALE"
    case refund = "REFUND"

}

public enum CVMSignatureMode: String, Codable, Sendable  {
    case signOnPaper = "SIGN_ON_PAPER"
}

// MARK: - client
public struct Client: Codable, Sendable  {
    public let app: String
    public let version: String
    public let callEntry: CallEntry
    public let ip: String
    public let hostDeviceModel: String
    public let hostDeviceBrand: String

    public enum CallEntry: String, Codable, Sendable  {
        case launch = "LAUNCH"
        case app2app = "APP2APP"
        case payserver = "PAYSERVER"
    }
}

// MARK: - cardRead
public struct CardRead: Codable, Sendable  {
    public let paymentMethod: PaymentMethod
    public let entryMode: EntryMode
    public let maskedPan: String
    public let needOnline: Bool
    public let cardKsn: String
    public let cvmPerformed: CVMPerformed
    public let pinKsn: String?
    public let panToken: String
    public let reader: ReaderInfo
    public let appleTTP: AppleTTP
    public let emvData: [String: String]

    enum CodingKeys: String, CodingKey {
        case paymentMethod, entryMode, maskedPan, needOnline, cardKsn, cvmPerformed, pinKsn, panToken, reader, emvData
        case appleTTP = "appleTTP"
    }
}

public enum PaymentMethod: String, Codable, Sendable  {
    case visa = "VISA"
    case mastercard = "MASTERCARD"
    case amex = "AMEX"
    case unknown = "UNKNOWN"
}

public enum EntryMode: String, Codable, Sendable  {
    case nfc = "NFC"
    case contact = "CONTACT"
    case contactlessMag = "CONTACTLESS"
    case magstripe = "MAGSTRIPE"
}

public enum CVMPerformed: String, Codable, Sendable  {
    case noCvm = "NO_CVM"
    case onlinePin = "ONLINE_PIN"
    case signature = "SIGNATURE"
    case consumerDeviceCvm = "CDCVM"
}

// MARK: - Reader + Apple TTP
public struct ReaderInfo: Codable, Sendable  {
    public let model: String
    public let brand: String
    public let sdkId: String
    public let hardwareSN: String
    public let sdkVersion: String
    public let firmwareVersion: String?
    public let emvKernelVersion: String?
}

public struct AppleTTP: Codable, Sendable  {
    public let readerToken: String
    public let readerId: String
    public let iosTrxId: String
    public let protectedPaymentData: String
}
