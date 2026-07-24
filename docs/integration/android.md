# GiftShop SDK — Android 연동 가이드

> 최종 수정: 2026-07-21
> 대상: GiftShop SDK를 앱에 탑재하는 매체사 Android 개발자

iOS 연동 → [ios.md](./ios.md) | Bridge 프로토콜 → [bridge.md](./bridge.md)

---

## 1. 요구사항

| 항목 | 최솟값 |
|------|--------|
| minSdk | 26 (Android 8.0) |
| compileSdk | 35 |
| Kotlin | 1.9+ |

---

## 2. 설치

**1) AAR 다운로드**

[GitHub Releases](https://github.com/thezooom-kr/GiftShopSDK-public/releases/latest)에서 `GiftShopSDK.aar`를 다운로드합니다.

**2) 프로젝트에 추가**

`GiftShopSDK.aar`를 `app/libs/`에 복사 후 `app/build.gradle.kts`에 추가합니다.

```kotlin
dependencies {
    implementation(files("libs/GiftShopSDK.aar"))
    // SDK 내부 의존성
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")
}
```

---

## 3. 초기화

`Application.onCreate()`에서 1회 호출합니다.

```kotlin
import com.ourcompany.sdk.api.GiftShopSDK
import com.ourcompany.sdk.api.GiftShopSDKConfig
import com.ourcompany.sdk.api.Environment

GiftShopSDK.initialize(
    GiftShopSDKConfig(
        environment    = Environment.PRODUCTION,  // 운영: PRODUCTION / 테스트: STAGING
        timeoutSeconds = 10                       // 네트워크 타임아웃 초 (기본값 10)
    )
)
```

---

## 4. 기프트샵 열기

### 4-1. Activity 방식 — 전체화면

```kotlin
GiftShopSDK.launch(
    context     = context,
    publisherId = "your-publisher-id",
    campaignId  = "1234",
    userId      = "user-unique-id",
    senderPhone = "01012345678"       // 선택 — 발신자 번호 자동 입력
)
```

뒤로가기 동작: WebView 히스토리 이동 → 히스토리 없으면 Activity 종료

### 4-2. Fragment 방식 — 탭/컨테이너 삽입

```kotlin
val fragment = GiftShopSDK.createFragment(
    publisherId = "your-publisher-id",
    campaignId  = "1234",
    userId      = "user-unique-id",
    senderPhone = "01012345678"       // 선택
)

supportFragmentManager.beginTransaction()
    .replace(R.id.container, fragment)
    .commit()
```

뒤로가기 직접 처리:

```kotlin
if (fragment.canGoBack()) fragment.goBack()
else { /* 앱 자체 뒤로가기 */ }
```

### 4-3. 방식 비교

| | Activity (`launch`) | Fragment (`createFragment`) |
|---|---|---|
| UI | 전체화면 새 Activity | 컨테이너 삽입 |
| 뒤로가기 | Activity 종료 | Activity 유지 |
| 탭 내 사용 | 불가 | 가능 |

---

## 5. 파라미터

| 파라미터 | 필수 | 설명 |
|---------|:---:|------|
| `publisherId` | ✅ | 매체사 식별자 (발급 필요) |
| `campaignId` | ✅ | 캠페인 번호 (숫자 문자열) |
| `userId` | ✅ | 매체앱 사용자 고유 식별자 |
| `senderPhone` | | 발신자 전화번호 (미전달 시 사용자 직접 입력) |

> `publisherId`, `campaignId` 발급: yu.dongsu@thezooom.kr

---

## 6. 권한

SDK가 자동 선언하는 권한:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

매체앱이 별도 선언할 권한: **없음**
- 연락처 선택은 시스템 피커(`Intent.ACTION_PICK`) 사용 → `READ_CONTACTS` 불필요

---

## 7. networkSecurityConfig 충돌 대응

매체앱에 `networkSecurityConfig`가 이미 선언된 경우 AndroidManifest.xml에 다음을 추가합니다.

```xml
<manifest xmlns:android="..."
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:networkSecurityConfig="@xml/your_config"
        tools:replace="android:networkSecurityConfig">
```

매체앱 네트워크 보안 설정에 `mysticbox.kr` 도메인을 포함해야 합니다:

```xml
<!-- res/xml/your_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">mysticbox.kr</domain>
    </domain-config>
</network-security-config>
```

---

## 8. Google Play 데이터 보안 선언

GiftShop SDK 탑재 시 Play Console → **앱 콘텐츠 → 데이터 보안**에 선언합니다.

| 데이터 유형 | 수집 | 목적 |
|------------|:---:|------|
| 기기 또는 기타 ID | O | 앱 기능 (사용자 식별) |

> 기기 전화번호는 SDK가 직접 수집하지 않습니다. 발신자 번호는 매체앱이 `senderPhone`으로 전달하거나 사용자가 직접 입력합니다.

---

## 9. 에러 처리

SDK가 내부적으로 처리하므로 매체앱 별도 처리 불필요합니다.

| 상황 | 표시 |
|------|------|
| 네트워크 없음 | 에러 화면 + 재시도 버튼 |
| 인증 실패 | 에러 화면 + 재시도 버튼 |
| 페이지 로드 실패 | 에러 화면 + 재시도 버튼 |

---

## 10. 테스트

```kotlin
// Staging 환경 전환
GiftShopSDK.initialize(GiftShopSDKConfig(environment = Environment.STAGING))
```

테스트 계정:

| userId | 잔액 | 결제 결과 |
|--------|------|---------|
| `success-user` | 120,000P | 정상 |
| `fail-user` | 120,000P | 강제 실패 |
| `low-balance-user` | 3,000P | 잔액 부족 |
