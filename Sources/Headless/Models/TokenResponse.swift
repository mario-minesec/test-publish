//
//  TokenResponse.swift
//  Headless
//
//  Created by Mario Gamal on 28/10/2025.
//

import Foundation

public struct TokenResponse: Codable, Sendable {
    public let code: Int
    public let msg: String
    public let data: TokenData
}

public struct TokenData: Codable, Sendable {
    public let token: String
}
