import UIKit
import WebKit
import Contacts
import ContactsUI

public class GiftShopWebViewController: UIViewController {

    private var webView: WKWebView!
    private var loadingView: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private var errorView: UIView!
    private var errorLabel: UILabel!
    private var retryButton: UIButton!

    private var bridgeHandler: GiftShopBridgeHandler!
    private var tokenManager: TokenManager!
    private var contactPickerDelegate: ContactPickerDelegateImpl!

    private var publisherId: String = ""
    private var campaignId: String  = ""
    private var userId: String      = ""
    private var senderPhone: String = ""
    private var config: GiftShopSDKConfig = GiftShopSDKConfig()
    private var giftShopBaseUrl: String   = ""

    public var canGoBack: Bool { webView?.canGoBack ?? false }
    public func goBack() { webView?.goBack() }

    static func create(
        publisherId: String,
        campaignId: String,
        userId: String,
        senderPhone: String,
        config: GiftShopSDKConfig
    ) -> GiftShopWebViewController {
        let vc = GiftShopWebViewController()
        vc.publisherId   = publisherId
        vc.campaignId    = campaignId
        vc.userId        = userId
        vc.senderPhone   = senderPhone
        vc.config        = config
        vc.giftShopBaseUrl = InternalConfig.giftShopBaseUrl(env: config.environment)
        return vc
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupWebView()
        fetchJwtAndLoad()
    }

    deinit {
        bridgeHandler?.unregister(from: webView.configuration.userContentController)
    }

    // MARK: - 뷰 구성

    private func setupViews() {
        // WebView 설정은 setupWebView()에서
        loadingView = UIView()
        loadingView.backgroundColor = .white
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        loadingView.addSubview(activityIndicator)

        errorView = UIView()
        errorView.backgroundColor = .white
        errorView.isHidden = true
        errorView.translatesAutoresizingMaskIntoConstraints = false

        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textColor = .gray
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        retryButton = UIButton(type: .system)
        retryButton.setTitle("다시 시도", for: .normal)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)

        view.addSubview(loadingView)
        view.addSubview(errorView)

        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),

            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -20),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor)
        ])
    }

    private func setupWebView() {
        bridgeHandler = GiftShopBridgeHandler(senderPhone: senderPhone)
        bridgeHandler.onGoBackNoHistory = { [weak self] in
            guard let self else { return }
            // launch() 방식(fullScreen present)이면 dismiss, addChild() 방식이면 no-op
            if self.presentingViewController != nil {
                self.dismiss(animated: true)
            }
        }
        bridgeHandler.onPickContact = { [weak self] in
            self?.openContactPicker()
        }

        let configuration = WKWebViewConfiguration()
        bridgeHandler.register(to: configuration)

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isHidden = true

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        view.insertSubview(webView, at: 0)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        bridgeHandler.webView = webView

        tokenManager = TokenManager(
            network: NetworkClient(timeoutSeconds: config.timeoutSeconds),
            publisherJwtUrl: InternalConfig.publisherJwtUrl(env: config.environment)
        )

        contactPickerDelegate = ContactPickerDelegateImpl { [weak self] phone in
            self?.bridgeHandler.sendContactPicked(phone: phone)
        }
    }

    // MARK: - 토큰 / 로드

    private func fetchJwtAndLoad() {
        showLoading()
        tokenManager.getToken(
            publisherId: publisherId,
            campaignId: campaignId,
            userId: userId
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let jwt):
                    let encoded = jwt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? jwt
                    let urlString = "\(self.giftShopBaseUrl)?token=\(encoded)"
                    if let url = URL(string: urlString) {
                        self.webView.load(URLRequest(url: url))
                    }
                case .failure(let error):
                    switch error {
                    case .invalidCampaignId, .parseFailed:
                        self.showError("인증 오류가 발생했습니다")
                    case .fetchFailed:
                        self.showError("네트워크 연결을 확인해주세요")
                    }
                }
            }
        }
    }

    @objc private func retryTapped() {
        tokenManager.clearCache()
        fetchJwtAndLoad()
    }

    // MARK: - 연락처

    private func openContactPicker() {
        let picker = CNContactPickerViewController()
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.delegate = contactPickerDelegate
        present(picker, animated: true)
    }

    // MARK: - 화면 상태

    private func showLoading() {
        loadingView.isHidden = false
        errorView.isHidden   = true
        webView.isHidden     = true
    }

    private func showWebView() {
        loadingView.isHidden = true
        errorView.isHidden   = true
        webView.isHidden     = false
    }

    private func showError(_ message: String) {
        loadingView.isHidden  = true
        errorView.isHidden    = false
        webView.isHidden      = true
        errorLabel.text       = message
    }
}

// MARK: - WKNavigationDelegate

extension GiftShopWebViewController: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let host = navigationAction.request.url?.host else {
            decisionHandler(.cancel)
            return
        }
        if InternalConfig.isAllowedHost(host) {
            decisionHandler(.allow)
        } else {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWebView()
        bridgeHandler.updateCanGoBack()
        bridgeHandler.sendSenderPhoneUpdate(phone: senderPhone)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError("네트워크 연결을 확인해주세요")
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showError("페이지를 불러올 수 없습니다")
    }
}

// MARK: - 연락처 피커 델리게이트

private class ContactPickerDelegateImpl: NSObject, CNContactPickerDelegate {
    private let onPicked: (String) -> Void

    init(onPicked: @escaping (String) -> Void) {
        self.onPicked = onPicked
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        if let phone = contactProperty.value as? CNPhoneNumber {
            onPicked(phone.stringValue)
        }
    }
}
