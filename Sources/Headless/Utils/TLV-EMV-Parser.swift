//
//  TLV-EMV-Parser.swift
//  Headless
//
//  Created by Mario Gamal on 01/11/2025.
//

import Foundation

public func buildEmvData(fromBase64 tlvBase64: String?) -> [String: String] {
    guard
        let base64 = tlvBase64,
        let data = Data(base64Encoded: base64)
    else { return [:] }

    // Only these tags will be translated to ASCII (e.g., labels).
    let textTags: Set<String> = ["50", "9F12"]

    var result: [String: String] = [:]
    var index = data.startIndex

    func readTag() -> String? {
        guard index < data.endIndex else { return nil }
        var bytes: [UInt8] = [data[index]]
        index = data.index(after: index)

        // Multi-byte tag handling (BER-TLV)
        if (bytes[0] & 0x1F) == 0x1F {
            while index < data.endIndex {
                let b = data[index]
                bytes.append(b)
                index = data.index(after: index)
                if (b & 0x80) == 0 { break }
            }
        }
        return bytes.map { String(format: "%02X", $0) }.joined()
    }

    func readLength() -> Int? {
        guard index < data.endIndex else { return nil }
        let first = data[index]
        index = data.index(after: index)

        if (first & 0x80) == 0 {
            // Short form
            return Int(first)
        } else {
            // Long form
            let count = Int(first & 0x7F)
            guard count > 0,
                  data.distance(from: index, to: data.endIndex) >= count else { return nil }

            let lenBytes = data[index ..< data.index(index, offsetBy: count)]
            index = data.index(index, offsetBy: count)
            return lenBytes.reduce(0) { ($0 << 8) | Int($1) }
        }
    }

    func toHexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    func asciiIfPrintable(_ bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        let allowed = 0x20 ... 0x7E
        let printableCount = bytes.filter { allowed.contains(Int($0)) }.count
        guard printableCount == bytes.count,
              let str = String(bytes: bytes, encoding: .ascii) else {
            return nil
        }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    while index < data.endIndex {
        guard let rawTag = readTag(),
              let length = readLength(),
              data.distance(from: index, to: data.endIndex) >= length else { break }

        let valueData = data[index ..< data.index(index, offsetBy: length)]
        index = data.index(index, offsetBy: length)

        let tag = rawTag.uppercased()
        let bytes = [UInt8](valueData)
        let hexValue = toHexString(bytes)

        if textTags.contains(tag) {
            // Only translate these whitelisted tags to ASCII
            if let ascii = asciiIfPrintable(bytes) {
                result[tag] = ascii
            } else {
                result[tag] = hexValue
            }
        } else {
            // Always keep hex for all other tags
            result[tag] = hexValue
        }
    }

    return result
}
