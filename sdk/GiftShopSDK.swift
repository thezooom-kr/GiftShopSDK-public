import UIKit

public final class GiftShopSDK {

    private static var config = GiftShopSDKConfig()

    private init() {}

    public static func initialize(config: GiftShopSDKConfig) {
        self.config = config
    }

    /// Activity 방식 — 전체 화면으로 present
    public static func launch(
        from viewController: UIViewController,
        publisherId: String,
        campaignId: String,
        userId: String,
        senderPhone: String = ""
    ) {
        let vc = GiftShopWebViewController.create(
            publisherId: publisherId,
            campaignId: campaignId,
            userId: userId,
            senderPhone: senderPhone,
            config: config
        )
        vc.modalPresentationStyle = .fullScreen
        viewController.present(vc, animated: true)
    }

    /// Fragment 방식 — 반환된 VC를 addChild()로 임베드
    public static func createViewController(
        publisherId: String,
        campaignId: String,
        userId: String,
        senderPhone: String = ""
    ) -> GiftShopWebViewController {
        GiftShopWebViewController.create(
            publisherId: publisherId,
            campaignId: campaignId,
            userId: userId,
            senderPhone: senderPhone,
            config: config
        )
    }
}
