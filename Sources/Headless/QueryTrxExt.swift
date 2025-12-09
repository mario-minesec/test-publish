//
//  QueryTrxExt.swift
//  Headless
//
//  Created by Mario Gamal on 01/11/2025.
//

public extension HeadlessService {
    
    func actionQuery(
         tranId: String? = nil,
         posReference: String? = nil,
         requestId: String? = nil
     ) async -> Result<TransactionResponse, HeadlessError> {
         
         if tranId == nil && posReference == nil && requestId == nil {
             return .failure(.transaction("At least one identifier (tranId, posReference, or requestId) must be provided."))
         }
         
         let apiEndpoint = APIEndpoint.performQueryAction(
             tranId: tranId,
             posReference: posReference,
             requestId: requestId
         )
         let customHeaders = buildCommonHeaders()
         
         do {
             let response: TransactionResponse = try await network.send(
                 apiEndpoint,
                 extraHeaders: customHeaders
             )
             print("✅ Query Action success")
             print("Transaction ID:", response.tranId)
             print("Status:", response.tranStatus)
             
             return .success(response)
         } catch {
             print("❌ Query Action failed:", error.localizedDescription)
             return .failure(.transaction("Query failed: \(error.localizedDescription)"))
         }
     }
    
}
