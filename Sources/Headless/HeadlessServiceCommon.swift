//
//  HeadlessServiceCommon.swift
//  Headless
//
//  Created by SONGYAO on 2025/11/5.
//

import Foundation

public extension HeadlessService {
    
    func getRequestId() -> String {
        let ulid = ULID()
        return "req_\(ulid.ulidString)"
    }

    func buildCommonHeaders() -> [String: String] {
        return [
            "x-minesec-request-id": self.getRequestId(),
            "x-minesec-customer-id": self.license?.customerId ?? "",
            "x-minesec-license-id": self.license?.licenseId ?? "",
            "x-minesec-sdk-id": Self.headlessId   
        ]
    }
}
