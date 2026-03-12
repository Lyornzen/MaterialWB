# MaterialWeibo

轻量级微博第三方 Android 客户端，采用 Flutter + Material Design 3 构建。

A lightweight third-party Weibo client for Android, built with Flutter and Material Design 3.

---

## 目录 / Table of Contents

- [项目简介 / Overview](#项目简介--overview)
- [环境要求 / Prerequisites](#环境要求--prerequisites)
- [快速开始 / Quick Start](#快速开始--quick-start)
- [微博开发者注册与配置 / Weibo Developer Setup](#微博开发者注册与配置--weibo-developer-setup)
- [测试 / Testing](#测试--testing)
- [打包 / Building](#打包--building)
- [项目结构 / Project Structure](#项目结构--project-structure)
- [常见问题 / FAQ](#常见问题--faq)

---

## 项目简介 / Overview

**中文**

MaterialWeibo 是一款使用 Flutter 开发的微博第三方客户端，面向 Android 平台。主要特性：

- Material Design 3 / Material You 动态取色
- 微博 OAuth 2.0 登录
- 首页时间线、微博详情、评论
- 热搜与搜索
- 收藏管理
- 浏览历史
- 用户个人资料
- 深色模式 / 浅色模式 / 跟随系统
- 双通道 API（官方开放平台 + m.weibo.cn 网页端）

**English**

MaterialWeibo is a third-party Weibo client built with Flutter, targeting Android. Key features:

- Material Design 3 / Material You with dynamic color
- Weibo OAuth 2.0 authentication
- Home timeline, post detail, comments
- Hot search and keyword search
- Favorites management
- Browsing history
- User profiles
- Dark / Light / System theme modes
- Dual-channel API (Official Open Platform + m.weibo.cn web endpoints)

---

## 环境要求 / Prerequisites

| 工具 / Tool | 最低版本 / Min Version | 说明 / Notes |
|---|---|---|
| Flutter | 3.41+ | `flutter --version` 检查 |
| Dart | 3.11+ | 随 Flutter 附带 |
| Android SDK | API 26+ (Android 8.0) | 需安装 `build-tools`, `platform-tools`, `platforms;android-34`+ |
| Java / JDK | 17+ | Flutter 3.41 要求 JDK 17 |
| Gradle | 随项目自带 | 无需单独安装 |

### 中文

1. **安装 Flutter**：参照 [Flutter 官方文档](https://docs.flutter.dev/get-started/install)
2. **安装 Android SDK**：推荐通过 Android Studio 安装，或使用 `sdkmanager` 命令行工具
3. **配置环境变量**：
   ```bash
   export ANDROID_HOME=/path/to/android-sdk
   export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
   ```
4. **验证环境**：
   ```bash
   flutter doctor
   ```
   确保 Flutter 和 Android toolchain 均显示 `[✓]`。

### English

1. **Install Flutter**: Follow the [official Flutter docs](https://docs.flutter.dev/get-started/install)
2. **Install Android SDK**: Recommended via Android Studio, or via `sdkmanager` CLI
3. **Set environment variables**:
   ```bash
   export ANDROID_HOME=/path/to/android-sdk
   export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
   ```
4. **Verify setup**:
   ```bash
   flutter doctor
   ```
   Ensure both Flutter and Android toolchain show `[✓]`.

---

## 快速开始 / Quick Start

```bash
# 克隆项目 / Clone the project
git clone <your-repo-url>
cd MaterialWeibo/material_weibo

# 安装依赖 / Install dependencies
flutter pub get

# 静态分析 / Static analysis
flutter analyze

# 运行（需连接 Android 设备或启动模拟器）
# Run (requires a connected Android device or emulator)
flutter run
```

---

## 微博开发者注册与配置 / Weibo Developer Setup

本应用使用微博开放平台 OAuth 2.0 进行用户认证。你必须注册一个微博开发者应用才能使用完整功能。

This app uses Weibo Open Platform OAuth 2.0 for authentication. You must register a Weibo developer app to use full functionality.

### 第一步：注册微博开发者账号 / Step 1: Register a Weibo Developer Account

**中文**

1. 访问 [微博开放平台](https://open.weibo.com/)
2. 使用你的微博账号登录
3. 点击顶部导航「微连接 → 移动应用」或直接进入「我的应用」
4. 如果是首次使用，需要完成开发者身份认证（个人认证需要手持身份证照片，企业认证需要营业执照）
5. 等待审核通过（通常 1-3 个工作日）

**English**

1. Visit [Weibo Open Platform](https://open.weibo.com/)
2. Log in with your Weibo account
3. Navigate to "My Apps" via the top navigation
4. Complete developer identity verification if it's your first time (personal verification requires ID photo; enterprise requires business license)
5. Wait for approval (typically 1-3 business days)

### 第二步：创建应用 / Step 2: Create an Application

**中文**

1. 在「我的应用」页面点击「创建应用」
2. 选择应用类型：**移动应用 → Android**
3. 填写应用信息：
   - **应用名称**：自定义（如 `MaterialWeibo`）
   - **应用简介**：简要描述
   - **应用包名**：`com.materialweibo.material_weibo`
   - **签名信息**：APK 签名的 MD5 值（见下文「获取签名 MD5」）
4. 提交审核

**English**

1. Click "Create App" on the "My Apps" page
2. Select type: **Mobile App → Android**
3. Fill in app info:
   - **App Name**: Choose any name (e.g., `MaterialWeibo`)
   - **Description**: Brief description
   - **Package Name**: `com.materialweibo.material_weibo`
   - **Signature**: MD5 of your APK signing key (see "Get Signing MD5" below)
4. Submit for review

### 获取签名 MD5 / Get Signing MD5

```bash
# debug 签名（开发用）/ Debug signing key (for development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android

# 在输出中找到 MD5 指纹，去掉冒号后填入开放平台
# Find the MD5 fingerprint in the output, remove colons, then enter it on the platform
# 例如 / Example: 5E:8F:16:06:2E:A3:CD:2C:... → 5E8F16062EA3CD2C...
```

### 第三步：获取 App Key 和 App Secret / Step 3: Get App Key and App Secret

**中文**

1. 应用审核通过后，进入应用详情页
2. 在「应用信息 → 基本信息」中找到：
   - **App Key**（即 client_id）
   - **App Secret**（即 client_secret）
3. 在「应用信息 → 高级信息」中设置：
   - **OAuth 2.0 授权回调页**：`https://api.weibo.com/oauth2/default.html`
   - **取消授权回调页**：`https://api.weibo.com/oauth2/default.html`

**English**

1. After app approval, go to app details page
2. Find in "App Info → Basic Info":
   - **App Key** (client_id)
   - **App Secret** (client_secret)
3. Set in "App Info → Advanced Info":
   - **OAuth 2.0 Redirect URI**: `https://api.weibo.com/oauth2/default.html`
   - **Cancel Auth Redirect URI**: `https://api.weibo.com/oauth2/default.html`

### 第四步：配置到项目中 / Step 4: Configure the Project

编辑 `lib/core/constants/api_constants.dart`，将占位符替换为你的真实值：

Edit `lib/core/constants/api_constants.dart` and replace the placeholders with your actual values:

```dart
// 替换以下两行 / Replace these two lines:
static const String appKey = 'YOUR_APP_KEY';       // ← 填入你的 App Key
static const String appSecret = 'YOUR_APP_SECRET'; // ← 填入你的 App Secret
```

> **安全提示 / Security Note**:
> 不要将包含真实 App Key/Secret 的文件提交到公开仓库。建议使用 `--dart-define` 在编译时注入，或使用 `.env` 文件配合 `flutter_dotenv`。
>
> Do not commit files containing real App Key/Secret to public repositories. Consider using `--dart-define` at build time or `.env` files with `flutter_dotenv`.

#### 使用 `--dart-define` 注入（推荐）/ Using `--dart-define` (Recommended)

```bash
flutter run \
  --dart-define=WEIBO_APP_KEY=your_key_here \
  --dart-define=WEIBO_APP_SECRET=your_secret_here
```

如果选择此方式，可以在代码中这样读取：

If using this approach, read the values in code like this:

```dart
static const String appKey = String.fromEnvironment('WEIBO_APP_KEY', defaultValue: 'YOUR_APP_KEY');
static const String appSecret = String.fromEnvironment('WEIBO_APP_SECRET', defaultValue: 'YOUR_APP_SECRET');
```

### 关于测试账号 / About Test Accounts

**中文**

- 微博开放平台在应用审核通过前只允许**开发者本人**的账号使用 OAuth 登录
- 审核通过后可在「应用信息 → 测试信息」中添加最多 15 个测试账号
- 未通过审核的应用，API 调用频率有限制（通常 150 次/小时）

**English**

- Before app approval, only the **developer's own account** can use OAuth login
- After approval, you can add up to 15 test accounts in "App Info → Test Info"
- Unapproved apps have API rate limits (typically 150 requests/hour)

---

## 测试 / Testing

### 静态分析 / Static Analysis

```bash
cd material_weibo
flutter analyze
```

确保输出 `No issues found!`。

Ensure the output shows `No issues found!`.

### 单元测试 / Unit Tests

```bash
flutter test
```

测试文件位于 `test/` 目录。项目使用以下测试工具：

Test files are in the `test/` directory. The project uses these testing tools:

| 包 / Package | 用途 / Purpose |
|---|---|
| `flutter_test` | Flutter 内置测试框架 / Built-in test framework |
| `bloc_test` | Bloc/Cubit 专用测试工具 / Bloc/Cubit testing utilities |
| `mocktail` | Mock 库 / Mocking library |

#### 编写 Bloc 测试示例 / Example Bloc Test

```dart
// test/presentation/blocs/auth/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when not logged in',
      setUp: () {
        when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthCheckStatus()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );
  });
}
```

### 在设备上测试 / On-Device Testing

**中文**

1. **使用真机**（推荐）：
   ```bash
   # 确认设备已连接
   adb devices

   # 运行应用
   flutter run
   ```

2. **使用 Android 模拟器**：
   ```bash
   # 列出可用模拟器
   flutter emulators

   # 启动模拟器
   flutter emulators --launch <emulator_name>

   # 运行应用
   flutter run
   ```

3. **WSL2 用户注意事项**：
   - WSL2 中无法直接使用 Android 模拟器（需要 KVM，WSL2 不支持嵌套虚拟化）
   - 推荐方案 A：在 Windows 侧运行模拟器，WSL2 中通过 `adb connect` 连接：
     ```bash
     # 在 Windows 侧启动模拟器后，在 WSL2 中执行：
     adb connect <windows_ip>:5555
     flutter run
     ```
   - 推荐方案 B：使用 USB 连接真机，在 Windows 侧启动 adb server，WSL2 连接：
     ```bash
     # Windows 侧（PowerShell）
     adb -a -P 5037 nodaemon server

     # WSL2 侧
     export ADB_SERVER_SOCKET=tcp:<windows_ip>:5037
     adb devices
     flutter run
     ```
   - 推荐方案 C：直接在 Windows 侧安装 Flutter，避免 WSL2 的设备访问问题

**English**

1. **Physical device** (recommended):
   ```bash
   # Verify device is connected
   adb devices

   # Run the app
   flutter run
   ```

2. **Android emulator**:
   ```bash
   # List available emulators
   flutter emulators

   # Launch an emulator
   flutter emulators --launch <emulator_name>

   # Run the app
   flutter run
   ```

3. **WSL2 users note**:
   - Android emulators cannot run directly in WSL2 (requires KVM, not available in WSL2)
   - Option A: Run the emulator on Windows, connect from WSL2 via `adb connect`:
     ```bash
     # After starting emulator on Windows side:
     adb connect <windows_ip>:5555
     flutter run
     ```
   - Option B: Connect a physical device via USB, start adb server on Windows:
     ```bash
     # Windows side (PowerShell)
     adb -a -P 5037 nodaemon server

     # WSL2 side
     export ADB_SERVER_SOCKET=tcp:<windows_ip>:5037
     adb devices
     flutter run
     ```
   - Option C: Install Flutter directly on Windows to avoid WSL2 device access issues

---

## 打包 / Building

### Debug APK

```bash
flutter build apk --debug
# 输出 / Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK

**中文**

1. **创建签名密钥**（仅首次）：
   ```bash
   keytool -genkey -v -keystore ~/my-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias my-key-alias
   ```

2. **创建 `android/key.properties`**（不要提交到 Git）：
   ```properties
   storePassword=你的密钥库密码
   keyPassword=你的密钥密码
   keyAlias=my-key-alias
   storeFile=/absolute/path/to/my-release-key.jks
   ```

3. **修改 `android/app/build.gradle.kts`**，在 `android {` 块中添加签名配置：
   ```kotlin
   val keystoreProperties = java.util.Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
   }

   android {
       // ... 已有配置 ...

       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String?
               keyPassword = keystoreProperties["keyPassword"] as String?
               storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
               storePassword = keystoreProperties["storePassword"] as String?
           }
       }

       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. **构建 Release APK**：
   ```bash
   flutter build apk --release
   # 输出: build/app/outputs/flutter-apk/app-release.apk
   ```

5. **构建 App Bundle**（用于 Google Play 上架）：
   ```bash
   flutter build appbundle --release
   # 输出: build/app/outputs/bundle/release/app-release.aab
   ```

**English**

1. **Create a signing key** (first time only):
   ```bash
   keytool -genkey -v -keystore ~/my-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias my-key-alias
   ```

2. **Create `android/key.properties`** (do NOT commit to Git):
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=my-key-alias
   storeFile=/absolute/path/to/my-release-key.jks
   ```

3. **Edit `android/app/build.gradle.kts`** to add signing config in the `android {}` block:
   ```kotlin
   val keystoreProperties = java.util.Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
   }

   android {
       // ... existing config ...

       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String?
               keyPassword = keystoreProperties["keyPassword"] as String?
               storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
               storePassword = keystoreProperties["storePassword"] as String?
           }
       }

       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. **Build Release APK**:
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk
   ```

5. **Build App Bundle** (for Google Play):
   ```bash
   flutter build appbundle --release
   # Output: build/app/outputs/bundle/release/app-release.aab
   ```

### 使用 `--dart-define` 构建 / Build with `--dart-define`

```bash
flutter build apk --release \
  --dart-define=WEIBO_APP_KEY=your_key \
  --dart-define=WEIBO_APP_SECRET=your_secret
```

---

## 项目结构 / Project Structure

```
material_weibo/
├── android/                          # Android 平台配置
├── assets/
│   ├── icons/                        # 应用图标
│   └── images/                       # 图片资源
├── lib/
│   ├── main.dart                     # 入口：DI 初始化、系统 UI、启动 App
│   ├── app.dart                      # MaterialApp：主题、路由、BlocProvider
│   ├── core/
│   │   ├── constants/                # API 和应用常量
│   │   ├── di/                       # GetIt 依赖注入
│   │   ├── errors/                   # 自定义异常与 Failure
│   │   ├── network/                  # Dio 客户端、拦截器、网络状态
│   │   ├── router/                   # GoRouter 路由配置
│   │   ├── theme/                    # Material 3 主题、配色、字体
│   │   └── utils/                    # 日期、HTML 解析、图片 URL 工具
│   ├── domain/
│   │   ├── entities/                 # 领域实体（User, WeiboPost, Comment, Favorite）
│   │   └── repositories/            # 仓库接口
│   ├── data/
│   │   ├── models/                   # 数据模型（含 JSON 序列化）
│   │   ├── datasources/
│   │   │   ├── remote/               # 远程数据源（官方 API + 网页 API）
│   │   │   └── local/                # 本地数据源（SharedPreferences + JSON）
│   │   └── repositories/            # 仓库接口实现
│   └── presentation/
│       ├── blocs/                    # Bloc/Cubit 状态管理
│       ├── pages/                    # 页面（Splash, Login, Home, ...）
│       └── widgets/                  # 共享组件（WeiboCard, ImageGrid, ...）
├── test/                             # 测试文件
└── pubspec.yaml                      # 依赖配置
```

---

## 常见问题 / FAQ

### Q: `flutter doctor` 显示 `[✗] Android toolchain`，怎么办？

**中文**：确保 `ANDROID_HOME` 环境变量指向 Android SDK 目录，并运行：
```bash
flutter doctor --android-licenses
```
接受所有许可协议。

**English**: Ensure `ANDROID_HOME` points to your Android SDK directory, then run:
```bash
flutter doctor --android-licenses
```
Accept all licenses.

### Q: WSL2 中 `flutter build apk` 找不到 Android SDK？

设置环境变量：
```bash
export ANDROID_HOME=/opt/android-sdk    # 或你的实际路径
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```
建议将其写入 `~/.bashrc` 或 `~/.zshrc`。

### Q: 微博开放平台审核需要多久？/ How long does Weibo platform review take?

通常 1-3 个工作日。审核期间可以使用开发者自己的账号进行测试。

Typically 1-3 business days. During review, you can test with the developer's own account.

### Q: 没有微博开发者审核，能否使用？/ Can I use the app without Weibo developer approval?

部分功能可以通过网页端 API (m.weibo.cn) 使用，但 OAuth 登录和官方 API 功能（时间线、收藏、评论）需要有效的 App Key。

Some features work via the web API (m.weibo.cn), but OAuth login and official API features (timeline, favorites, comments) require a valid App Key.

### Q: 首次构建很慢？/ First build is very slow?

首次构建需要下载 Gradle 和 Android 依赖，可能需要 5-15 分钟。后续构建会使用缓存，速度会快得多。如果你在中国大陆，建议配置 Gradle 镜像：

The first build downloads Gradle and Android dependencies, which may take 5-15 minutes. Subsequent builds use cache and are much faster. If in mainland China, configure a Gradle mirror:

编辑 `android/gradle/wrapper/gradle-wrapper.properties`，将 `distributionUrl` 替换为国内镜像，或在 `android/build.gradle.kts` 中添加阿里云 Maven 镜像：

```kotlin
allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        google()
        mavenCentral()
    }
}
```

---

## 许可证 / License

MIT
