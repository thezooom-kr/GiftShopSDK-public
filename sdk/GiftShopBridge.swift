import UIKit
import WebKit

class GiftShopBridgeHandler: NSObject, WKScriptMessageHandler {

    weak var webView: WKWebView?
    var senderPhone: String
    var onPickContact: (() -> Void)?
    var onGoBackNoHistory: (() -> Void)?

    private let handlerNames = ["pickContact", "goBack", "canGoBack", "getMyPhoneNumber"]

    init(senderPhone: String) {
        self.senderPhone = senderPhone
    }

    func register(to configuration: WKWebViewConfiguration) {
        handlerNames.forEach {
            configuration.userContentController.add(self, name: $0)
        }
        let script = GiftShopBridgeHandler.makePolyfillScript(senderPhone: senderPhone)
        configuration.userContentController.addUserScript(script)
    }

    func unregister(from userContentController: WKUserContentController) {
        handlerNames.forEach { userContentController.removeScriptMessageHandler(forName: $0) }
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let webView = self.webView else { return }
            switch message.name {
            case "pickContact":
                self.onPickContact?()
            case "goBack":
                if webView.canGoBack {
                    webView.goBack()
                } else {
                    self.onGoBackNoHistory?()
                }
            case "canGoBack":
                // 동기 반환값은 폴리필의 _giftShopCanGoBack으로 처리 — 여기서는 무시
                break
            case "getMyPhoneNumber":
                // 동기 반환값은 폴리필의 _giftShopSenderPhone으로 처리 — 여기서는 무시
                break
            default:
                break
            }
        }
    }

    func updateCanGoBack() {
        guard let webView else { return }
        let js = "window._giftShopCanGoBack = \(webView.canGoBack ? "true" : "false");"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func sendContactPicked(phone: String) {
        let escaped = phone.jsonEscaped
        webView?.evaluateJavaScript("window.onContactPicked(\(escaped));", completionHandler: nil)
    }

    func sendSenderPhoneUpdate(phone: String) {
        guard !phone.isEmpty else { return }
        let escaped = phone.jsonEscaped
        webView?.evaluateJavaScript(
            "typeof window.updateSenderPhone === 'function' && window.updateSenderPhone(\(escaped));",
            completionHandler: nil
        )
    }

    static func makePolyfillScript(senderPhone: String) -> WKUserScript {
        let escaped = senderPhone.jsonEscaped
        let source = """
        window._giftShopSenderPhone = \(escaped);
        window._giftShopCanGoBack = false;
        window.GiftShopBridge = {
            pickContact: function() {
                window.webkit.messageHandlers.pickContact.postMessage(null);
            },
            goBack: function() {
                window.webkit.messageHandlers.goBack.postMessage(null);
            },
            canGoBack: function() {
                return window._giftShopCanGoBack;
            },
            getMyPhoneNumber: function() {
                return window._giftShopSenderPhone;
            }
        };
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

private extension String {
    var jsonEscaped: String {
        var result = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(result)\""
    }
}
