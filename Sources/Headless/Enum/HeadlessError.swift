//
//  HeadlessError.swift
//  Headless
//
//  Created by Mario Gamal on 31/10/2025.
//

public enum HeadlessError: Error, Sendable {
    case unsupportedDevice
    case badToken
    case licenseAnalyze(String)
    case network(String)
    case reader(String)
    case transaction(String)
}
