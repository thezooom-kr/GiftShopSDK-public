import Foundation

public enum Environment {
    case production
    case staging
}

public struct GiftShopSDKConfig {
    public let environment: Environment
    public let timeoutSeconds: TimeInterval

    public init(
        environment: Environment = .production,
        timeoutSeconds: TimeInterval = 10
    ) {
        self.environment = environment
        self.timeoutSeconds = timeoutSeconds
    }
}
