//
//  VoidRefundExt.swift
//  Headless
//
//  Created by Mario Gamal on 01/11/2025.
//

public extension HeadlessService {
    
    func actionVoid(tranId: String) async -> Result<TransactionResponse, HeadlessError> {
        let apiEndpoint = APIEndpoint.performActionVoid(tranId: tranId)
        let customHeaders = buildCommonHeaders()
        do {
            let response: TransactionResponse = try await network.send(
                apiEndpoint,
                extraHeaders: customHeaders
            )
            print("✅ VOID Action success")
            print("Transaction ID:", response.tranId)
            print("Status:", response.tranStatus)
            
            return .success(response)
        } catch {
            print("❌ VOID Action failed:", error.localizedDescription)
            return .failure(.transaction("void failed: \(error.localizedDescription)"))
        }
    }
    
    func actionLinkedRefund(tranId: String,amount: Amount? = nil) async -> Result<TransactionResponse, HeadlessError> {
        let apiEndpoint = APIEndpoint.performActionLinkedRefund(tranId: tranId, amount: amount)
        let customHeaders = buildCommonHeaders()
        do {
            let response: TransactionResponse = try await network.send(
                apiEndpoint,
                extraHeaders: customHeaders
            )
            print("✅ Linked Refund Action success")
            print("Transaction ID:", response.tranId)
            print("Status:", response.tranStatus)
            
            return .success(response)
        } catch {
            print("❌ Linked Refund Action failed:", error.localizedDescription)
            return .failure(.transaction("Linked Refund failed: \(error.localizedDescription)"))
        }
    }
}
