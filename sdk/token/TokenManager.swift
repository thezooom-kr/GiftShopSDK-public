import Foundation

enum TokenError: Error {
    case invalidCampaignId
    case fetchFailed
    case parseFailed
}

class TokenManager {
    private let network: NetworkClient
    private let publisherJwtUrl: String
    private var cachedToken: CachedToken?
    private let lock = NSLock()

    init(network: NetworkClient, publisherJwtUrl: String) {
        self.network = network
        self.publisherJwtUrl = publisherJwtUrl
    }

    func getToken(
        publisherId: String,
        campaignId: String,
        userId: String,
        completion: @escaping (Result<String, TokenError>) -> Void
    ) {
        lock.lock()
        if let cached = cachedToken, !cached.isExpired {
            let jwt = cached.publisherJwt
            lock.unlock()
            completion(.success(jwt))
            return
        }
        lock.unlock()

        guard let campaignIdInt = Int(campaignId) else {
            completion(.failure(.invalidCampaignId))
            return
        }

        let body: [String: Any] = [
            "publisherId": publisherId,
            "campaignId": campaignIdInt,
            "userId": userId
        ]

        network.post(url: publisherJwtUrl, jsonBody: body) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                completion(.failure(.fetchFailed))
            case .success(let data):
                guard
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let jwt = json["publisherJwt"] as? String
                else {
                    completion(.failure(.parseFailed))
                    return
                }
                self.lock.lock()
                self.cachedToken = CachedToken(publisherJwt: jwt)
                self.lock.unlock()
                completion(.success(jwt))
            }
        }
    }

    func clearCache() {
        lock.lock()
        cachedToken = nil
        lock.unlock()
    }

    private struct CachedToken {
        let publisherJwt: String
        let issuedAt = Date()
        var isExpired: Bool { Date().timeIntervalSince(issuedAt) > 55 * 60 }
    }
}
