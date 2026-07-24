# GiftShop SDK

기프트샵 서비스를 매체앱에 WebView 방식으로 임베드하는 SDK입니다.  
Android(Kotlin)와 iOS(Swift) 두 플랫폼을 지원합니다.

---

## 프로젝트 구조

```
giftshop/
├── aos/
│   ├── sdk/        Android SDK (AAR 라이브러리)
│   └── sample/     Android 샘플앱
├── ios/
│   ├── sdk/        iOS SDK (Swift Package)
│   ├── sample/     iOS 샘플앱
│   └── Package.swift
└── docs/           설계·분석 문서
```

---

## 요구사항

| | Android | iOS |
|---|---|---|
| 최소 버전 | API 26 (Android 8.0) | iOS 14.0 |
| 언어 | Kotlin 1.9+ | Swift 5.9+ |
| 빌드 도구 | Gradle 8+ | Xcode 15+ |

---

## Android

### 설치

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://repo.mysticbox.kr/android") }
    }
}

// app/build.gradle.kts
dependencies {
    implementation("com.ourcompany:giftshop-sdk:1.0.0")
}
```

### 초기화

`Application.onCreate()`에서 1회 호출합니다.

```kotlin
GiftShopSDK.initialize(
    GiftShopSDKConfig(
        environment    = Environment.PRODUCTION,
        timeoutSeconds = 10
    )
)
```

### 사용법

**전체화면 방식 (Activity)**
```kotlin
GiftShopSDK.launch(
    context     = context,
    publisherId = "your_publisher_id",
    campaignId  = "1234",
    userId      = "user_001",
    senderPhone = "01012345678"  // 선택
)
```

**탭/컨테이너 임베드 방식 (Fragment)**
```kotlin
val fragment = GiftShopSDK.createFragment(
    publisherId = "your_publisher_id",
    campaignId  = "1234",
    userId      = "user_001",
    senderPhone = "01012345678"  // 선택
)
supportFragmentManager.beginTransaction()
    .replace(R.id.container, fragment)
    .commit()
```

뒤로가기 처리:
```kotlin
override fun onBackPressed() {
    if (fragment.canGoBack()) fragment.goBack()
    else super.onBackPressed()
}
```

### 권한

SDK가 자동으로 선언하는 권한:
- `android.permission.INTERNET`

매체앱이 직접 선언해야 하는 권한: 없음 (연락처 선택은 시스템 UI 사용)

---

## iOS

### 설치

**Swift Package Manager (Xcode)**
1. `File` → `Add Package Dependencies`
2. URL 입력: `https://github.com/thezooom-kr/GiftShopSDK-public`
3. `GiftShopSDK` 타겟 추가

**Swift Package Manager (Package.swift)**
```swift
dependencies: [
    .package(url: "https://github.com/thezooom-kr/GiftShopSDK-public", from: "1.0.0")
]
```

### Info.plist 필수 설정

SDK가 연락처 UI를 사용하므로 매체앱의 `Info.plist`에 반드시 추가해야 합니다.  
미추가 시 **런타임 크래시** 발생합니다.

```xml
<key>NSContactsUsageDescription</key>
<string>선물 받을 연락처를 선택하기 위해 사용합니다</string>
```

### 초기화

`AppDelegate.application(_:didFinishLaunchingWithOptions:)`에서 1회 호출합니다.

```swift
GiftShopSDK.initialize(
    config: GiftShopSDKConfig(
        environment:    .production,
        timeoutSeconds: 10
    )
)
```

### 사용법

**전체화면 방식 (present)**
```swift
GiftShopSDK.launch(
    from:        self,
    publisherId: "your_publisher_id",
    campaignId:  "1234",
    userId:      "user_001",
    senderPhone: "01012345678"  // 선택
)
```

**탭/컨테이너 임베드 방식 (addChild)**
```swift
let sdkVC = GiftShopSDK.createViewController(
    publisherId: "your_publisher_id",
    campaignId:  "1234",
    userId:      "user_001",
    senderPhone: "01012345678"  // 선택
)

addChild(sdkVC)
view.addSubview(sdkVC.view)
sdkVC.view.frame = view.bounds
sdkVC.didMove(toParent: self)
```

뒤로가기 처리:
```swift
// 네비게이션 바 Back 버튼 또는 스와이프 제스처 처리
if sdkVC.canGoBack {
    sdkVC.goBack()
}
```

---

## 파라미터 설명

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|:---:|------|
| `publisherId` | String | ✅ | 매체사 식별자 (발급 필요) |
| `campaignId` | String | ✅ | 캠페인 식별자 (숫자 문자열) |
| `userId` | String | ✅ | 매체앱 사용자 식별자 |
| `senderPhone` | String | | 발신자 전화번호 (자동 입력용) |

> `publisherId`, `campaignId` 발급은 담당자에게 문의하세요.  
> 문의: yu.dongsu@thezooom.kr

---

## 환경 설정

| 값 | Android | iOS | 설명 |
|---|---|---|---|
| Production | `Environment.PRODUCTION` | `.production` | 운영 서버 |
| Staging | `Environment.STAGING` | `.staging` | 개발/테스트 서버 |

---

## 에러 처리

SDK는 내부적으로 에러를 처리하며, 화면에 에러 UI와 재시도 버튼을 자동으로 표시합니다.

| 상황 | 표시 메시지 |
|------|-----------|
| 잘못된 파라미터 | 인증 오류가 발생했습니다 |
| 네트워크 오류 | 네트워크 연결을 확인해주세요 |
| 페이지 로드 실패 | 페이지를 불러올 수 없습니다 |

---

## 샘플앱 실행

**Android**
```bash
# Android Studio에서 aos/sample 모듈 실행
# 또는
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
./gradlew :app:installDebug
```

**iOS**
```bash
cd ios/sample
xcodegen generate
open GiftShopSampleApp.xcodeproj
```

---

## Web ↔ Native 브릿지

웹앱과 네이티브 앱 간 통신 프로토콜입니다.

| 방향 | 함수 | 설명 |
|------|------|------|
| Web → Native | `GiftShopBridge.pickContact()` | 연락처 선택 UI 열기 |
| Web → Native | `GiftShopBridge.goBack()` | 뒤로가기 |
| Web → Native | `GiftShopBridge.canGoBack()` | 뒤로가기 가능 여부 (Boolean) |
| Web → Native | `GiftShopBridge.getMyPhoneNumber()` | 발신자 번호 반환 |
| Native → Web | `window.onContactPicked(phone)` | 선택된 연락처 번호 전달 |
| Native → Web | `window.updateSenderPhone(phone)` | 발신자 번호 업데이트 |

---

## 보안

- JWT 토큰은 SDK 내부에서 자동 발급·갱신 (55분 TTL)
- HTTPS 전용 통신 (HTTP 차단)
- 허용 도메인 외부 URL은 시스템 브라우저(Safari/Chrome)로 위임
- 디버그 빌드에서만 WebView 원격 디버깅 활성화
