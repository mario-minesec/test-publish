// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import ProximityReader

actor TokenProvider {
    static let shared = TokenProvider()

    private init() {}

    func fetchToken() async throws -> PaymentCardReader.Token {
        let response: TokenResponse = try await NetworkClient().send(.fetchToken)
        let tokenString = response.data.token
        print(tokenString)
        return PaymentCardReader.Token(rawValue: tokenString)
    }
}
