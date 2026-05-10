# DayLog App 部署运行方案

> 面向中国大陆网络环境 · Windows CMD 终端 · Android 真机

---

## 1. 环境准备

### 1.1 前置依赖

| 依赖 | 版本要求 | 检查命令 |
|------|----------|----------|
| Flutter SDK | ≥ 3.27.0 | `flutter --version` |
| Java JDK | 17+ (推荐 Temurin 17) | `java --version` |
| Android SDK | API 34+ | `flutter doctor` |
| Git | 任意 | `git --version` |

### 1.2 Flutter SDK

项目指定 SDK 位置：`E:\flutter_windows_3.27.0-stable`

确保以下路径已添加到系统环境变量 `PATH`：
- `E:\flutter_windows_3.27.0-stable\bin`
- `%USERPROFILE%\AppData\Local\Pub\Cache\bin`（pub global）

在 **CMD** 中验证：
```cmd
echo %PATH% | findstr flutter
flutter --version
```

如果 `flutter` 命令未识别，打开 **系统属性 → 环境变量 → 编辑 PATH** 添加上述路径，重新打开 CMD。

### 1.3 Java JDK

推荐 **Eclipse Temurin JDK 17 LTS**：
- 下载：[https://adoptium.net/zh-CN/temurin/releases/?version=17](https://adoptium.net/zh-CN/temurin/releases/?version=17)
- 安装后添加 `JAVA_HOME` 环境变量指向安装目录（如 `C:\Program Files\Eclipse Adoptium\jdk-17.0.xx-hotspot`）
- 将 `%JAVA_HOME%\bin` 加入 PATH

### 1.4 Android 环境

#### Git 安装
从 [https://git-scm.com/downloads/win](https://git-scm.com/downloads/win) 下载安装。安装时选择 **Git from the command line and also from 3rd-party software**，确保 CMD 能识别 `git`。

---

## 2. 国内镜像配置（关键步骤）

> 不配置镜像直接 `flutter pub get` / Gradle 构建极大概率因网络超时失败。

### 2.1 Flutter 镜像（Pub）

推荐 **腾讯云 Flutter 镜像**，稳定且少坑：

**方案一：全局环境变量**
在系统环境变量中添加：
| 变量名 | 变量值 |
|--------|--------|
| `PUB_HOSTED_URL` | `https://mirrors.tencent.com/pub/flutter/` |
| `FLUTTER_STORAGE_BASE_URL` | `https://mirrors.tencent.com/storage/flutter_infra_release/` |

CMD 中临时设置（推荐，避免影响其他项目）：
```cmd
set PUB_HOSTED_URL=https://mirrors.tencent.com/pub/flutter/
set FLUTTER_STORAGE_BASE_URL=https://mirrors.tencent.com/storage/flutter_infra_release/
```

**方案二：阿里云镜像**（备选）
```cmd
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 2.2 Gradle 镜像

编辑 `android\build.gradle`（项目级），在 `repositories` 中添加：

```groovy
buildscript {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/google' }
        google()
        mavenCentral()
    }
}
```

### 2.3 Gradle 下载加速

编辑 `android\gradle\wrapper\gradle-wrapper.properties`，**建议使用 Gradle 8.4+**：

```properties
distributionUrl=https\://mirrors.aliyun.com/gradle/gradle-8.4-all.zip
```

备选腾讯云 Gradle 镜像：
```
distributionUrl=https\://mirrors.tencent.com/gradle/gradle-8.4-all.zip
```

---

## 3. 首次运行流程

### 3.1 克隆代码

```cmd
cd C:\Users\%USERNAME%\Projects
mkdir daylog
cd daylog
git clone https://github.com/1124326120-rgb/daylog.git .
```

### 3.2 确认 Android 平台目录

检查项目根目录是否有 `android\` 文件夹：

```cmd
dir android
```

**如果不存在**（新手项目常见，因 `.gitignore` 阻挡了 `android/`），执行：

```cmd
cd C:\Users\%USERNAME%\Projects\daylog
flutter create --platforms=android .
```

⚠️ **注意**：这会重新生成 `android/` 目录，同时覆盖 `lib/` 和 `pubspec.yaml`。**安全做法**：
1. 先备份 `lib\` 和 `pubspec.yaml`
2. 执行 `flutter create --platforms=android .`
3. 恢复 `lib\` 和 `pubspec.yaml`

如果只是 `android/` 目录缺失且 `lib/` 正常，更安全的做法是从另一个 Flutter 项目拷贝 `android/` 目录并修改 `package name`。

### 3.3 安装依赖

```cmd
cd C:\Users\%USERNAME%\Projects\daylog
flutter pub get
```

**预期输出**：
```
Resolving dependencies...
  http 1.2.2 (1.3.0 available)
  intl 0.19.0 (0.20.2 available)
  path 1.9.0 (1.9.1 available)
  shared_preferences 2.3.4 (2.5.3 available)
  ...
Got dependencies.
```

输出末尾不会出现红色错误信息。出现 `Got dependencies.` 即成功。

### 3.4 连接手机

```cmd
adb devices
```

**预期输出**：
```
List of devices attached
XXXXXX1234    device
```

- 如果显示 `unauthorized`：手机弹窗提示"允许 USB 调试吗？"→ 勾选"一律允许"→ 确定
- 如果 `adb` 命令未识别：将 `E:\flutter_windows_3.27.0-stable\bin` 加入 PATH 或使用完整路径 `E:\flutter_windows_3.27.0-stable\bin\adb devices`
- 如果没有设备：检查 USB 线是否支持数据传输，手机是否已开启「开发者选项」和「USB 调试」

### 3.5 运行 App

```cmd
cd C:\Users\%USERNAME%\Projects\daylog
flutter run
```

**首次构建说明**：
- 第一次执行 `flutter run` 会下载 Gradle wrapper 和 Android SDK 组件，耗时 5–15 分钟
- 后续热重载增量构建只需几秒
- 如果卡在某一步很久，参考下面第 6 节「常见错误预案」

**成功标志**：
```
Launching lib\main.dart on XXXXXX in debug mode...
✓  Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
✓  Successfully installed to device.
Syncing files to device XXXXXX...
✓  Installation successful
Starting: Intent { ... }
Flutter run key commands.
```

**常用按键**：
| 按键 | 功能 |
|------|------|
| `r` | 热重载（保留状态） |
| `R` | 热重启（重置状态） |
| `q` | 退出 |

---

## 4. LeanCloud 漂流瓶后端配置（可选）

### 4.1 注册与选择

| 版本 | 推荐 | 说明 |
|------|------|------|
| **国际版** (us.leancloud.app) | ✅ **推荐白嫖** | 免费额度足够开发测试，无需备案 |
| 国内版 (leancloud.cn) | ❌ | 需要实名认证 + 域名备案，且免费额度少 |

### 4.2 创建 Class

登录 LeanCloud 控制台 → 创建新应用 → 创建 Class：

**Class 名：`Bottle`**（严格大小写）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `content` | String | 漂流瓶内容 |
| `moodEmoji` | String | 心情 emoji，如 😊😢🔥 |
| `likesCount` | Number | 点赞数，默认 0 |
| `createdAt` | Date | 自动生成，无需手动添加 |

不需要创建 `objectId`（LeanCloud 自动生成）和 `updatedAt`（自动生成）。

> **国际版支持创建表时不填 Class name，直接命名为 `Bottle` 即可。如果提示需要关联 ACL，选择默认（仅数据创建者可读写）即可，开发阶段暂不改动。**

### 4.3 配置 App ID / App Key

编辑 `lib\services\leancloud_service.dart`：

```dart
class LeanCloudService {
  static const String _appId = '你的AppID';
  static const String _appKey = '你的AppKey';
  static const String _baseUrl = 'https://你的应用域名/api/1.1';
  // ...
}
```

参数获取：
- LeanCloud 控制台 → 设置 → 应用 Keys
- **App ID**：以 `akPDYc` 之类的随机字符串开头
- **App Key**：对应的密钥
- **URL**：国际版为 `https://xxx.api.lncldglobal.com`，国内版为 `https://xxx.leancloud.cn`

### 4.4 安全建议

| 阶段 | 权限设置 |
|------|----------|
| 开发测试 | Class 权限设为「无限制」（方便调试） |
| 上线前 | 必须设置权限 → add_fields/create/find 等仅限 authenticated user 或自定义 |

**不要**在 `leancloud_service.dart` 中硬编码 `_appKey` 后提交到公开仓库。开发阶段可用 `.env` 文件或编译时注入。

---

## 5. 交付检查清单

通过以下检查项确认部署成功：

### 5.1 基础验证

- [ ] `flutter pub get` 无错误
- [ ] `flutter run` 成功安装到手机
- [ ] App 启动后显示主界面（日历视图 + 写日记按钮），无白屏/闪退

### 5.2 日记功能

- [ ] 点击"写日记" → 输入内容 → 保存 → 页面关闭回到日历
- [ ] 保存后日历上对应日期显示标记（圆点/颜色）
- [ ] 点击有标记的日期 → 显示日记列表
- [ ] 点击日记条目 → 查看完整内容
- [ ] 编辑日记 → 保存 → 内容更新
- [ ] 删除日记 → 确认 → 日历标记消失
- [ ] 下拉刷新或切换月份 → 数据正常加载

### 5.3 周报/月报（Phase 2）

- [ ] 进入周报页 → 显示本周日记汇总 → 可滚动查看完整内容
- [ ] 进入月报页 → 显示本月日记数据和统计 → 无空状态崩溃
- [ ] 分享功能 → 生成分享卡片/文本 → 系统分享弹窗正常

### 5.4 漂流瓶（Phase 3，可选）

如果已连接 LeanCloud：
- [ ] 投放漂流瓶 → 成功提示 → LeanCloud 控制台出现新记录
- [ ] 捞取漂流瓶 → 显示随机一条瓶子内容 → 点赞功能正常

### 5.5 稳定性

- [ ] 页面切换（日历→周报→漂流瓶→我的）不卡顿/不崩溃
- [ ] 热重载 `r` 正常工作
- [ ] 强制关闭 App 后重新打开 → 数据持久化（日记不丢失）

---

## 6. 常见错误预案

### 6.1 Gradle 下载慢

**症状**：`flutter run` 卡在 `Running Gradle task 'assembleDebug'...` 超过 10 分钟

**解决**：
1. 确认已配置 2.2 节的阿里云 Gradle 镜像
2. 如果 `gradle-wrapper.properties` 中的 Gradle 版本在阿里云上没有，改用 `distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip`（原生下载 + 科学上网）
3. 删除 `android\.gradle\` 缓存目录后重试：
   ```cmd
   rmdir /s /q android\.gradle
   ```

### 6.2 Android licenses 未接受

**症状**：
```
Android licenses not accepted. To resolve this, run: flutter doctor --android-licenses
```

**解决**：
```cmd
flutter doctor --android-licenses
```
连续输入 `y` 接受所有许可。

### 6.3 android/ 目录缺失

**症状**：
```
Project does not support Android. Use `flutter create --platforms=android .` to add it.
```

**解决**：见第 3.2 节。⚠️ 注意备份 `lib/` 和 `pubspec.yaml`。

### 6.4 依赖版本冲突

**症状**：
```
Because every version of flutter_lints from path depends on ... and ...
```

**解决**：
```cmd
flutter pub upgrade --major-versions
```
如果依然报错，检查 `pubspec.yaml` 中的依赖版本范围是否过窄，放宽版本号（如 `^1.0.0` → `^2.0.0`）。

### 6.5 adb 无法识别设备

**诊断**：
```cmd
adb devices
```
如果为空：

1. 确认手机已开启「开发者选项」和「USB 调试」
2. 更换 USB 线（数据线，非仅充电线）
3. 安装手机厂商 USB 驱动（小米/华为/OPPO 需要各自驱动）
4. 如果仍然不行，重启 adb 服务：
   ```cmd
   adb kill-server
   adb start-server
   adb devices
   ```

### 6.6 Java 版本不兼容

**症状**：`flutter doctor` 显示 Java 警告或 Gradle 构建失败

**解决**：推荐安装 **Temurin JDK 17**，设置 `JAVA_HOME` 指向它。

检查当前 Java 版本：
```cmd
java --version
```

如果需要切换版本，修改 `JAVA_HOME` 环境变量指向正确路径，重新打开 CMD。

---

## 7. 日常开发提示

### 快速启动（跳过重新构建）

首次运行后，可直接用 APK 安装：
```cmd
flutter install
```

### 查看日志

```cmd
flutter logs
```

### 清除构建缓存（解决奇怪问题）

```cmd
flutter clean
flutter pub get
```

---

> 本文档由 Hermes Agent 生成 — Last updated: 2026-05-10
