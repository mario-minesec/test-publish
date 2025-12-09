//
//  NetworkClient.swift
//  Headless
//
import Foundation

public enum NetError: Error {
    case invalidURL
    case badStatus(statusCode: Int, errorBody: Data?)
    case noData
    case decodingFailed
}

public actor NetworkClient {
    private let session: URLSession
    private let logger: NetworkLogger

    public init(session: URLSession = .shared, logger: NetworkLogger = NetworkLogger()) {
        self.session = session
        self.logger = logger
    }

    public func send<T: Decodable>(
        _ endpoint: APIEndpoint,
        extraHeaders: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        
        guard let url = URL(string: endpoint.path, relativeTo: endpoint.baseURL) else {
            throw NetError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue

        let allHeaders = endpoint.defaultHeaders.merging(extraHeaders) { _, new in new }
        for (k, v) in allHeaders { req.setValue(v, forHTTPHeaderField: k) }

        if let body = endpoint.body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            req.httpBody = try encoder.encode(AnyEncodable(body))
            
            if req.value(forHTTPHeaderField: "Content-Type") == nil {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        // --- Log Request ---
        logger.log(request: req)
        
        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            let error = NetError.badStatus(statusCode: -1, errorBody: nil)
            logger.log(error: error) // Log the non-http response error
            throw error
        }
        
        // --- Log Response ---
        logger.log(response: http, data: data)

        // --- Handle Response ---
        guard (200...299).contains(http.statusCode) else {
            let error = NetError.badStatus(statusCode: http.statusCode, errorBody: data)
            throw error
        }
        
        guard !data.isEmpty else {
            let error = NetError.noData
            logger.log(error: error)
            throw error
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let decodeError = NetError.decodingFailed
            logger.log(error: decodeError)
            print("Failed to decode data from URL: \(http.url?.absoluteString ?? "")")
            throw decodeError
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self.encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
