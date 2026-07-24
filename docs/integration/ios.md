# GiftShop SDK — iOS 연동 가이드

> 최종 수정: 2026-07-21
> 대상: GiftShop SDK를 앱에 탑재하는 매체사 iOS 개발자

Android 연동 → [android.md](./android.md) | Bridge 프로토콜 → [bridge.md](./bridge.md)

---

## 1. 요구사항

| 항목 | 최솟값 |
|------|--------|
| iOS | 14.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |
| 배포 방식 | Swift Package Manager (SPM) |

---

## 2. 설치 (SPM)

**Xcode에서 추가**

`File` → `Add Package Dependencies` → URL 입력:
```
https://github.com/thezooom-kr/GiftShopSDK-public
```

**Package.swift에서 추가**

```swift
dependencies: [
    .package(url: "https://github.com/thezooom-kr/GiftShopSDK-public", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["GiftShopSDK"])
]
```

---

## 3. Info.plist 필수 설정

> ⚠️ **미설정 시 런타임 크래시 발생**

SDK가 연락처 UI(`CNContactPickerViewController`)를 사용하므로 매체앱의 `Info.plist`에 반드시 추가해야 합니다.

```xml
<key>NSContactsUsageDescription</key>
<string>선물 받을 연락처를 선택하기 위해 사용합니다</string>
```

> `CNContactPickerViewController`는 앱 권한 팝업 없이 동작하지만, 이 키가 없으면 Apple이 앱 실행을 거부합니다.

---

## 4. 초기화

`AppDelegate.application(_:didFinishLaunchingWithOptions:)`에서 1회 호출합니다.

```swift
import GiftShopSDK

GiftShopSDK.initialize(
    config: GiftShopSDKConfig(
        environment:    .production,  // 운영: .production / 테스트: .staging
        timeoutSeconds: 10            // 네트워크 타임아웃 초 (기본값 10)
    )
)
```

---

## 5. 기프트샵 열기

### 5-1. Present 방식 — 전체화면

```swift
GiftShopSDK.launch(
    from:        self,                  // UIViewController
    publisherId: "your-publisher-id",
    campaignId:  "1234",
    userId:      "user-unique-id",
    senderPhone: "01012345678"          // 선택 — 발신자 번호 자동 입력
)
```

뒤로가기 동작: WebView 히스토리 이동 → 히스토리 없으면 화면 dismiss

### 5-2. Embed 방식 — 탭/컨테이너 삽입

```swift
let giftVC = GiftShopSDK.createViewController(
    publisherId: "your-publisher-id",
    campaignId:  "1234",
    userId:      "user-unique-id",
    senderPhone: "01012345678"          // 선택
)

addChild(giftVC)
containerView.addSubview(giftVC.view)
giftVC.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    giftVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
    giftVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
    giftVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
    giftVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
])
giftVC.didMove(toParent: self)
```

뒤로가기 직접 처리:

```swift
if giftVC.canGoBack { giftVC.goBack() }
else { /* 앱 자체 뒤로가기 */ }
```

### 5-3. 방식 비교

| | Present (`launch`) | Embed (`createViewController`) |
|---|---|---|
| UI | 전체화면 모달 | 컨테이너 삽입 |
| 뒤로가기 | dismiss | 상위 VC 제어 |
| 탭 내 사용 | 불가 | 가능 |

---

## 6. 파라미터

| 파라미터 | 필수 | 설명 |
|---------|:---:|------|
| `publisherId` | ✅ | 매체사 식별자 (발급 필요) |
| `campaignId` | ✅ | 캠페인 번호 (숫자 문자열) |
| `userId` | ✅ | 매체앱 사용자 고유 식별자 |
| `senderPhone` | | 발신자 전화번호 (미전달 시 사용자 직접 입력) |

> `publisherId`, `campaignId` 발급: yu.dongsu@thezooom.kr

---

## 7. 권한 요약

| 항목 | 필요 여부 | 비고 |
|------|:--------:|------|
| `NSContactsUsageDescription` (Info.plist) | ✅ 필수 | 미설정 시 크래시 |
| 런타임 연락처 권한 팝업 | 불필요 | 시스템 피커 사용 |
| 추가 Capability | 불필요 | |

---

## 8. App Store Privacy Manifest

> ⚠️ **iOS 17.2+ SDK 배포 시 Apple 필수 요구사항**

GiftShop SDK를 탑재한 앱을 App Store에 제출할 때, App Store Connect → **개인 정보 보호 관행**에 선언합니다.

| 데이터 유형 | 수집 | 목적 |
|------------|:---:|------|
| 기기 또는 기타 ID | O | 앱 기능 (사용자 식별) |

> 기기 전화번호는 SDK가 직접 수집하지 않습니다. 발신자 번호는 매체앱이 `senderPhone`으로 전달하거나 사용자가 직접 입력합니다.

---

## 9. 원격 디버깅

iOS 16.4+ 기기에서 Safari 개발자 도구로 WKWebView 내부를 디버깅할 수 있습니다.

`Safari` → `개발` → `[기기명]` → `[앱명]`

디버그 빌드에서만 자동 활성화됩니다 (`isInspectable = true`).

---

## 10. 에러 처리

SDK가 내부적으로 처리하므로 매체앱 별도 처리 불필요합니다.

| 상황 | 표시 |
|------|------|
| 네트워크 없음 | 에러 화면 + 재시도 버튼 |
| 인증 실패 | 에러 화면 + 재시도 버튼 |
| 페이지 로드 실패 | 에러 화면 + 재시도 버튼 |

---

## 11. 테스트

```swift
// Staging 환경 전환
GiftShopSDK.initialize(config: GiftShopSDKConfig(environment: .staging))
```

테스트 계정:

| userId | 잔액 | 결제 결과 |
|--------|------|---------|
| `success-user` | 120,000P | 정상 |
| `fail-user` | 120,000P | 강제 실패 |
| `low-balance-user` | 3,000P | 잔액 부족 |
