# GiftShop SDK — Bridge 프로토콜 명세

> 최종 수정: 2026-07-21
> 대상: GiftShop SDK를 탑재하는 웹앱 개발자 및 SDK 내부 구현자

Android 연동 → [android.md](./android.md) | iOS 연동 → [ios.md](./ios.md)

---

## 1. 개요

GiftShop SDK는 WebView와 Native 앱 간 통신에 JavaScript Bridge를 사용합니다.  
웹에서 보이는 API(`GiftShopBridge.*`)는 Android/iOS 동일합니다.

### 플랫폼별 구현 방식

| 플랫폼 | 방식 | 핵심 파일 |
|--------|------|-----------|
| Android | `@JavascriptInterface` + `addJavascriptInterface()` | `GiftShopBridge.kt` |
| iOS | `WKScriptMessageHandler` + JS 폴리필 주입 | `GiftShopBridge.swift` |

> **iOS 동기 값 처리**: `WKWebView`는 동기 반환값을 지원하지 않습니다.  
> `canGoBack()`, `getMyPhoneNumber()`는 폴리필이 `window._giftShopCanGoBack`, `window._giftShopSenderPhone`을 참조해 동기처럼 동작합니다.

---

## 2. Bridge 전체 목록

| # | 방향 | 메서드 / 콜백 | Android | iOS | 비고 |
|---|------|--------------|---------|-----|------|
| 1 | Web → Native | `GiftShopBridge.pickContact()` | ✅ | ✅ | |
| 2 | Web → Native | `GiftShopBridge.goBack()` | ✅ | ✅ | |
| 3 | Web → Native | `GiftShopBridge.canGoBack()` | ✅ | ✅ | iOS: 폴리필 동기값 |
| 4 | Web → Native | `GiftShopBridge.getMyPhoneNumber()` | ✅ | ✅ | iOS: 폴리필 동기값 |
| 5 | Native → Web | `window.onContactPicked(phone)` | ✅ | ✅ | 웹에서 구현 필요 |
| 6 | Native → Web | `window.updateSenderPhone(phone)` | ✅ | ✅ | 웹에서 구현 필요 |

---

## 3. Web → Native

### 3.1 `GiftShopBridge.pickContact()`

시스템 연락처 피커를 열어 전화번호 1건을 선택합니다.

```javascript
GiftShopBridge.pickContact();
```

| 항목 | 내용 |
|------|------|
| 파라미터 | 없음 |
| 반환값 | 없음 (결과는 `window.onContactPicked` 콜백으로 전달) |
| 필요 권한 | 없음 (시스템 피커 사용) |

**플랫폼별 동작**

| 플랫폼 | 구현 |
|--------|------|
| Android | `Intent.ACTION_PICK` + `ContactsContract.CommonDataKinds.Phone.CONTENT_URI` |
| iOS | `CNContactPickerViewController` (displayedPropertyKeys: 전화번호) |

> 사용자가 선택을 취소하면 콜백이 호출되지 않습니다.

---

### 3.2 `GiftShopBridge.goBack()`

WebView 히스토리 뒤로 이동하거나 화면을 닫습니다.

```javascript
GiftShopBridge.goBack();
```

| 항목 | 내용 |
|------|------|
| 파라미터 | 없음 |
| 반환값 | 없음 |

**히스토리 없을 때 동작**

| 실행 방식 | Android | iOS |
|-----------|---------|-----|
| Activity / Present | `finish()` (Activity 종료) | `dismiss()` (모달 닫기) |
| Fragment / Embed | 무동작 | 무동작 |

---

### 3.3 `GiftShopBridge.canGoBack()`

WebView 히스토리 뒤로 이동 가능 여부를 반환합니다.

```javascript
const canGoBack = GiftShopBridge.canGoBack(); // Boolean
```

| 항목 | 내용 |
|------|------|
| 파라미터 | 없음 |
| 반환값 | `Boolean` — `true`: 뒤로 이동 가능 / `false`: 불가 |

> **iOS**: 페이지 로드 완료(`didFinish`) 시점에 `window._giftShopCanGoBack`이 갱신됩니다.  
> 페이지 전환 중간에 호출하면 이전 값을 반환할 수 있습니다.

---

### 3.4 `GiftShopBridge.getMyPhoneNumber()`

매체앱이 SDK에 전달한 발신자 전화번호를 반환합니다.

```javascript
const phone = GiftShopBridge.getMyPhoneNumber(); // String
```

| 항목 | 내용 |
|------|------|
| 파라미터 | 없음 |
| 반환값 | `String` — 전화번호 (예: `"01012345678"`) / 미전달 시 빈 문자열 `""` |

SDK 처리: `launch()` / `createFragment()` 호출 시 넘긴 `senderPhone` 파라미터를 그대로 반환합니다.

> 빈 값이면 사용자가 직접 입력하도록 처리해야 합니다.

**매체앱 연동 예시**

```kotlin
// Android
GiftShopSDK.launch(
    context     = context,
    publisherId = "your-publisher-id",
    campaignId  = "1305",
    userId      = "user-12345",
    senderPhone = "01012345678"
)
```

```swift
// iOS
GiftShopSDK.launch(
    from:        viewController,
    publisherId: "your-publisher-id",
    campaignId:  "1305",
    userId:      "user-12345",
    senderPhone: "01012345678"
)
```

**웹 사용 예시**

```javascript
document.addEventListener('DOMContentLoaded', function() {
    if (typeof GiftShopBridge !== 'undefined') {
        var phone = GiftShopBridge.getMyPhoneNumber();
        if (phone) document.getElementById('inputSender').value = phone;
    }
});
```

---

## 4. Native → Web

### 4.1 `window.onContactPicked(phone)`

`pickContact()` 완료 후 SDK가 자동 호출합니다.

> 웹에서 **전역 함수**로 반드시 구현해야 합니다.

```javascript
window.onContactPicked = function(phone) {
    document.getElementById('receiverPhone').value = phone;
};
```

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `phone` | String | 선택된 전화번호 (예: `"010-1234-5678"`) |

자동 호출 시점
- 시스템 연락처 피커에서 전화번호 선택 완료 시
- 사용자가 선택을 취소하면 호출되지 않음

---

### 4.2 `window.updateSenderPhone(phone)`

페이지 로드 완료 시 SDK가 자동 호출합니다. `senderPhone`이 비어있으면 호출되지 않습니다.

> 웹에서 **전역 함수**로 반드시 구현해야 합니다.

```javascript
window.updateSenderPhone = function(phone) {
    if (phone) document.getElementById('inputSender').value = phone;
};
```

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `phone` | String | 매체앱이 전달한 발신자 전화번호 |

자동 호출 흐름

```
SDK.launch(senderPhone = "01012345678")
  │
  └─ 페이지 로드 완료 (onPageFinished / didFinish)
          │
          ├─ senderPhone 있음 → window.updateSenderPhone("01012345678") 호출
          └─ senderPhone 없음 → 호출 안 함 (사용자 직접 입력)
```

> `window.updateSenderPhone`이 정의되어 있지 않은 경우 SDK가 안전하게 스킵합니다.

---

## 5. iOS 폴리필 상세

iOS는 `WKUserScript`로 문서 로드 시작 시점에 폴리필을 주입합니다.  
웹 코드 입장에서는 Android와 동일한 `GiftShopBridge.*` API를 사용합니다.

```javascript
// 주입되는 폴리필 (GiftShopBridge.swift — makePolyfillScript)
window._giftShopSenderPhone = "<senderPhone>";  // 네이티브 주입값
window._giftShopCanGoBack   = false;            // didFinish마다 갱신

window.GiftShopBridge = {
    pickContact:      function() { window.webkit.messageHandlers.pickContact.postMessage(null); },
    goBack:           function() { window.webkit.messageHandlers.goBack.postMessage(null); },
    canGoBack:        function() { return window._giftShopCanGoBack; },
    getMyPhoneNumber: function() { return window._giftShopSenderPhone; }
};
```

`_giftShopCanGoBack` 갱신 타이밍

```
페이지 로드 완료 (WKNavigationDelegate.didFinish)
  │
  ├─ bridgeHandler.updateCanGoBack()
  │    → window._giftShopCanGoBack = true/false
  │
  └─ bridgeHandler.sendSenderPhoneUpdate(phone:)
       → window.updateSenderPhone(phone) 호출
```

---

## 6. 권한 안내

| 권한 | 필요 Bridge | 선언 주체 |
|------|-------------|----------|
| `INTERNET` (Android) | 네트워크 통신 전체 | SDK 매니페스트 자동 선언 |
| `NSContactsUsageDescription` (iOS) | `pickContact` | 매체앱 Info.plist |

> Android는 시스템 연락처 피커(`ACTION_PICK`) 사용으로 `READ_CONTACTS` 권한 불필요.  
> iOS는 `CNContactPickerViewController` 사용 시 Info.plist에 `NSContactsUsageDescription` 필요.

---

## 7. 보안 설정

| 항목 | Android | iOS |
|------|---------|-----|
| 허용 도메인 | `*.mysticbox.kr` | `*.mysticbox.kr` |
| 외부 URL | 시스템 브라우저 위임 | `UIApplication.open()` |
| HTTP 통신 | `usesCleartextTraffic="false"` | ATS 기본 (HTTPS 전용) |
| JS 문자열 전달 | `JSONObject.quote()` | `String.jsonEscaped` 확장 |
| 원격 디버깅 | DEBUG: `WebContentsDebugging` 활성화 | iOS 16.4+: `isInspectable = true` |

---

## 8. 테스트 환경

### SDK 초기화 및 실행

```kotlin
// Android
GiftShopSDK.initialize(GiftShopSDKConfig(environment = Environment.STAGING))

// Activity로 열기
GiftShopSDK.launch(
    context     = context,
    publisherId = "backend-giftshop-test",
    campaignId  = "1305",
    userId      = "success-user",
    senderPhone = "01012345678"
)

// Fragment로 열기
val fragment = GiftShopSDK.createFragment(
    publisherId = "backend-giftshop-test",
    campaignId  = "1305",
    userId      = "success-user",
    senderPhone = "01012345678"
)
```

```swift
// iOS
GiftShopSDK.initialize(config: GiftShopSDKConfig(environment: .staging))

// Present로 열기
GiftShopSDK.launch(
    from:        viewController,
    publisherId: "backend-giftshop-test",
    campaignId:  "1305",
    userId:      "success-user",
    senderPhone: "01012345678"
)

// Embed로 열기
let vc = GiftShopSDK.createViewController(
    publisherId: "backend-giftshop-test",
    campaignId:  "1305",
    userId:      "success-user",
    senderPhone: "01012345678"
)
```

### 테스트 userId

| userId | 잔액 | 결제 결과 | 테스트 목적 |
|--------|------|----------|------------|
| `success-user` | 120,000P | 정상 차감 | 정상 결제 플로우 |
| `fail-user` | 120,000P | 차감 강제 실패 | 결제 실패 처리 |
| `low-balance-user` | 3,000P | 정상 차감 | 잔액 부족 처리 |
