//
//  LicenseLoader.swift
//  Headless
//
//  Created by ERIC on 2025/11/3.
//

import Foundation
import CryptoKit
import CommonCrypto
import Security

public struct LicenseModelV3: Codable {
    public let licenseId: String
    public let licenseVersion: Int
    public let customerId: String
    public let customerName: String?
    public let description: String
    public let emvFlags: String
    public let amsTrustRootX509: String
    public let secServerUrl: String
    public let secServerPeerCertPinners: String
    public let dbgServerUrl: String
    public let dbgServerPeerCertPinners: String
    public let appSigningFingerprint: String
}

struct RawLicenseData {
    var magic = Data(count: 4)
    var cyWallLicense = Data()
    var mhdLicense = Data()
    var licenseSignedData = Data()
    var licenseSignature = Data()
}


public enum LicenseError: Error {
    case fileNotFound(String)
    case invalidFormat(String)
    case signatureInvalid
    case decryptionFailed
    case parseFailed(String)
}

public final class LicenseCrypto {
    
    private static let secKey = #"MineHades20190901$$123$$KEYDATA"#

    private static let pemString: String = """
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtqpA9rXvvEpYmi5ed5Bx
    2WvCJHV87QUYBm5s36ApPjflVqs6x9/U3Slso++W0Eu3vfz5vsFRgB5yRjI52tLm
    1Hu9ouY2vdt+WcEmBmmg//J75ZykGnU91Suuc+mucoQxdZH7TCqkKQQoHkvD3cit
    YU0jDvrvfhmmOKXRgURwb9kUBIqx6BAaagWgSwmuZdsSn0Y9uL7YHGgAgxBxKah7
    Yz48zxsZoSoE0htCa7vRXhgk6k39Cu/F+fg0QVUvwAvmHzCIc3L2HQhAxVM9nPi1
    2vaVusrCR/WreSvxYDSpv5tS4bHm48BAfUbAb24sLXUTcu/GvglQktj9N01kd8CB
    SQIDAQAB
    -----END PUBLIC KEY-----
    """
    
    public static func doSha256(_ data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
    
    public static func verifySignature(signedData: Data, signature: Data) -> Bool {
        guard let key = try? convertPEMToPublicKey(pem: pemString) else { return false }
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        var error: Unmanaged<CFError>?
        return SecKeyVerifySignature(key, algorithm, signedData as CFData, signature as CFData, &error)
    }
    
    public static func decryptLicense(_ data: Data) -> Data? {
        // AES/CBC/PKCS7Padding 
        let key = doSha256(secKey.data(using: .utf8)!)
        let iv = Data(repeating: 0x30, count: 16)
        
        let decryptedLength = data.count + kCCBlockSizeAES128
        var decrypted = Data(count: decryptedLength)
        var numBytesDecrypted: size_t = 0
        
        let status = decrypted.withUnsafeMutableBytes { decryptedBytes in
            data.withUnsafeBytes { encryptedBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES256,
                            ivBytes.baseAddress,
                            encryptedBytes.baseAddress, data.count,
                            decryptedBytes.baseAddress, decryptedLength,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        if status == kCCSuccess {
            return decrypted.prefix(numBytesDecrypted)
        } else {
            return nil
        }
    }

    
    public static func convertPEMToPublicKey(pem: String) throws -> SecKey {
        let keyString = pem
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = Data(base64Encoded: keyString) else {
            throw LicenseError.invalidFormat("Invalid PEM base64")
        }
        
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 2048
        ]
        
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil) else {
            throw LicenseError.invalidFormat("Failed to create SecKey")
        }
        return key
    }
}


public final class LicenseLoader {
    
    public static func loadLicense(from fileName: String) throws -> LicenseModelV3 {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            throw LicenseError.fileNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        return try loadLicense(data: data)
    }
    
    public static func loadLicense(data: Data) throws -> LicenseModelV3 {
        let raw = try parseRawLicense(data: data)
        
        guard LicenseCrypto.verifySignature(signedData: raw.licenseSignedData, signature: raw.licenseSignature) else {
            throw LicenseError.signatureInvalid
        }
        
        guard let decrypted = LicenseCrypto.decryptLicense(raw.mhdLicense) else {
            throw LicenseError.decryptionFailed
        }
        
        do {
            return try JSONDecoder().decode(LicenseModelV3.self, from: decrypted)
        } catch {
            throw LicenseError.parseFailed(error.localizedDescription)
        }
    }
    
    
    private static func parseRawLicense(data: Data) throws -> RawLicenseData {
        var cursor = 0

        func readInt32LE() -> Int32 {
            let value = data[cursor..<cursor+4].withUnsafeBytes { $0.load(as: Int32.self) }
            cursor += 4
            return Int32(littleEndian: value)
        }

        func readData(_ size: Int) -> Data {
            let sub = data[cursor..<cursor+size]
            cursor += size
            return Data(sub)
        }

        guard data.count > 20 else {
            throw LicenseError.invalidFormat("Data too short")
        }

        var raw = RawLicenseData()

        // magic[4]
        raw.magic = readData(4)

        // offsets (little endian)
        let cyWallOffset = Int(readInt32LE())
        let cyWallSize   = Int(readInt32LE())
        let mhdOffset    = Int(readInt32LE())
        let mhdSize      = Int(readInt32LE())

        // cyWallLicense
        if cyWallSize > 0 {
            cursor = cyWallOffset
            raw.cyWallLicense = readData(cyWallSize)
        }

        // mhdLicense
        if mhdSize > 0 {
            cursor = mhdOffset
            raw.mhdLicense = readData(mhdSize)
        }

        // signature
        if cursor < data.count {
            raw.licenseSignature = data[cursor..<data.count]
        }

        let signedDataSize = 20 + cyWallSize + mhdSize
        raw.licenseSignedData = data.prefix(signedDataSize)

        return raw
    }
}
