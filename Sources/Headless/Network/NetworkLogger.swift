//
//  NetworkLogger.swift
//  Headless
//
import Foundation

public struct NetworkLogger {
    
    public init() {}
    
    /**
     * Prints the details of an outgoing URLRequest.
     */
    public func log(request: URLRequest) {
        print("--- ⬆️ Sending Request ---")
        
        if let url = request.url?.absoluteString, let method = request.httpMethod {
            print("URL: \(method) \(url)")
        }
        
        print("Headers: [")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            for (key, value) in headers {
                let redactedValue = (key.lowercased() == "authorization" || key.lowercased() == "x-api-key") ? "******" : value
                print("  \(key): \(redactedValue)")
            }
        } else {
            print("  (No Headers)")
        }
        print("]")

        print("Body: {")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print(bodyString)
        } else {
            print("  (No Body)")
        }
        print("}")
        print("---------------------------")
    }
    
    /**
     * Prints the details of an incoming HTTPURLResponse and its data.
     */
    public func log(response: HTTPURLResponse, data: Data?) {
        print("--- ⬇️ Received Response ---")
        
        print("Status Code: \(response.statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))")
        
        if let url = response.url?.absoluteString {
            print("URL: \(url)")
        }
        
        print("Body: {")
        if let bodyData = data, let bodyString = String(data: bodyData, encoding: .utf8) {
            print(bodyString)
        } else {
            print("  (No Body)")
        }
        print("}")
        print("-----------------------------")
    }
    
    /**
     * Prints the details of an error.
     */
    public func log(error: Error) {
        print("--- ❌ Network Error ---")
        
        if let netError = error as? NetError {
            // We can give a more detailed log for our custom error
            switch netError {
            case .invalidURL:
                print("Error: Invalid URL")
            case .badStatus(let code, let data):
                print("Error: Bad Status \(code)")
                if let bodyData = data, let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("Error Body: \(bodyString)")
                }
            case .noData:
                print("Error: No data in response")
            case .decodingFailed:
                print("Error: Failed to decode successful response.")
                // Note: The specific data that failed is logged in the `send` func
            }
        } else {
            // Log any other generic error
            print("Error: \(error.localizedDescription)")
        }
        print("--------------------------")
    }
}
