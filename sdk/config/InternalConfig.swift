import Foundation

enum InternalConfig {
    private static let publisherJwtUrlProd    = "https://giftshop-publisher.mysticbox.kr/publisher/auth/publisher-jwt"
    private static let publisherJwtUrlStaging = "https://test-giftshop-publisher.mysticbox.kr/test-publisher/auth/publisher-jwt"
    private static let giftShopBaseUrlProd    = "https://giftshop.mysticbox.kr/"
    private static let giftShopBaseUrlStaging = "https://test-giftshop.mysticbox.kr/"

    static func publisherJwtUrl(env: Environment) -> String {
        env == .production ? publisherJwtUrlProd : publisherJwtUrlStaging
    }

    static func giftShopBaseUrl(env: Environment) -> String {
        env == .production ? giftShopBaseUrlProd : giftShopBaseUrlStaging
    }

    static func isAllowedHost(_ host: String) -> Bool {
        host.hasSuffix("mysticbox.kr")
    }
}
