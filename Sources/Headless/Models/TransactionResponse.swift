//
//  TransactionREsponse.swift
//  Headless
//
//  Created by Mario Gamal on 03/11/2025.
//

import Foundation

// MARK: - Main Response Model
public struct TransactionResponse: Codable, Sendable {
    public let tranId: String
    public let tranType: String
    public let tranStatus: String
    public let amount: AmountInfo
    public let paymentMethod: String
    public let entryMode: String
    public let accountMasked: String
    public let accountBin: String
    public let accountLast4: String
    public let issCountryCode: String?
    public let cvmPerformed: String
    public let cvmSignatureUrl: String?
    public let cvmSignatureBase64: String?
    public let aid: String
    public let appName: String
    public let tc: String
    public let tvr: String
    public let tsi: String
    public let atc: String
    public let profileId: String
    public let acceptanceId: String
    public let acptId: String
    public let sdkId: String
    public let posReference: String?
    public let trace: String
    public let tranDescription: String? // Renamed from "description"
    public let callbackUrl: String?
    public let installmentPlan: String?
    public let merchantName: String
    public let merchantAddr: String
    public let mcc: String
    public let primaryMid: String
    public let primaryTid: String
    public let subMid: String?
    public let subTid: String?
    public let hostMessageFormat: String
    public let providerReference: String
    public let providerMchId: String
    public let linkedTranId: String?
    public let linkedSrsTranId: String?
    public let preferredAcceptanceTag: String?
    public let extraData: String // This is a String containing JSON, not a JSON object
    public let rrn: String
    public let approvalCode: String
    public let batchId: String
    public let batchNo: String
    public let actions: [ActionInfo]
    public let srsTranId: String
    public let consumerPaymentDevice: String?
    public let createdAt: String
    public let updatedAt: String?

    // We must use CodingKeys to map "description" to a safe name
    enum CodingKeys: String, CodingKey {
        case tranId, tranType, tranStatus, amount, paymentMethod, entryMode
        case accountMasked, accountBin, accountLast4, issCountryCode
        case cvmPerformed, cvmSignatureUrl, cvmSignatureBase64
        case aid, appName, tc, tvr, tsi, atc, profileId, acceptanceId
        case acptId, sdkId, posReference, trace
        case tranDescription = "description" // Map "description" to "tranDescription"
        case callbackUrl, installmentPlan, merchantName, merchantAddr
        case mcc, primaryMid, primaryTid, subMid, subTid
        case hostMessageFormat, providerReference, providerMchId
        case linkedTranId, linkedSrsTranId, preferredAcceptanceTag
        case extraData, rrn, approvalCode, batchId, batchNo, actions
        case srsTranId, consumerPaymentDevice, createdAt, updatedAt
    }
}

// MARK: - ActionInfo
public struct ActionInfo: Codable, Sendable {
    public let actionId: String
    public let trace: String
    public let actionType: String
    public let actionStatus: String
    public let requestId: String
    public let amount: AmountInfo
    public let tranId: String
    public let reason: String
    public let hostRespCode: String
    public let hostRespMessage: String?
    public let posReference: String?
    public let extraData: String? // This is a String containing JSON
    public let hostRespExtra: HostRespExtra?
    public let createdAt: String
    public let updatedAt: String?
}

// MARK: - AmountInfo
public struct AmountInfo: Codable, Sendable {
    public let value: String
    public let currency: String
}

// MARK: - HostRespExtra
// Represents the empty object "{}"
public struct HostRespExtra: Codable, Sendable {
    // This struct is intentionally empty
}
