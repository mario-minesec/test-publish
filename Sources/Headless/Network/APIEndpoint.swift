//
//  ApiEndpoint.swift
//  Headless
//
//  Created by Mario Gamal on 28/10/2025.
//

import Foundation

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

public enum APIEndpoint: Sendable {
    case fetchToken
    case createTransaction(TransactionRequest)
    case performActionVoid(tranId: String)
    case performActionLinkedRefund(tranId: String, amount: Amount? = nil)
    case performQueryAction(tranId: String? = nil, posReference: String? = nil, requestId: String? = nil)
}

extension APIEndpoint {
    var baseURL: URL {
        switch self {
        case .fetchToken:
            return URL(string: "https://apple-uat.mspayhub.com")!
        case .createTransaction, .performActionVoid, .performActionLinkedRefund, .performQueryAction:
            return URL(string: "https://glue-stage.mspayhub.com")!
        }
    }

    var path: String {
        switch self {
        case .fetchToken:
            return "/token"
        case .createTransaction:
            return "/api/v1/enabler/transactions"
        case .performActionVoid(let tranId):
            return "/api/v1/enabler/transactions/\(tranId)/actions"
        case .performActionLinkedRefund(let tranId, _):
            return "/api/v1/enabler/transactions/\(tranId)/actions"
        case .performQueryAction(let tranId, let posReference, let requestId):
            if let tranId = tranId {
                return "/api/v1/enabler/transactions/\(tranId)"
            } else if let posReference = posReference {
                return "/api/v1/enabler/transactions/posReference/\(posReference)"
            } else if let requestId = requestId {
                return "/api/v1/enabler/transactions/requestId/\(requestId)"
            } else {
                fatalError("queryAction requires at least one identifier")
            }
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchToken, .performQueryAction:
            return .GET
        case .createTransaction, .performActionVoid, .performActionLinkedRefund:
            return .POST
        }
    }

    var body: Encodable? {
        switch self {
        case .fetchToken, .performQueryAction:
            return nil
        case .createTransaction(let request):
            return request
        case .performActionVoid(let tranId):
            return ActionVoidRequest(type: "VOID", tranId: tranId)
        case .performActionLinkedRefund(let tranId, let amount):
            return ActionLinkedRefundRequest(type: "LINK_REFUND", tranId: tranId, amount: amount)
        }
    }

    var defaultHeaders: [String: String] {
        var headers: [String: String] = [
            "Accept": "application/json"
        ]
        if body != nil {
            headers["Content-Type"] = "application/json"
        }
        return headers
    }
}

public struct ActionVoidRequest: Encodable {
    let type: String
    let tranId: String
}

public struct ActionLinkedRefundRequest: Encodable {
    let type: String
    let tranId: String
    let amount: Amount?
    
    public init(type: String, tranId: String, amount: Amount? = nil) {
            self.type = type
            self.tranId = tranId
            self.amount = amount
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(tranId, forKey: .tranId)
            if let amount = amount {
                try container.encode(amount, forKey: .amount)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case tranId
            case amount
        }
}
