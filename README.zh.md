# ⛏️ 博斯科终端 (Bosco Terminal)

[ [English](./README.md) | [한국어](./README.ko.md) | **中文** ]

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![CI](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml)

**博斯科终端** 是专为 *深岩银河 (Deep Rock Galactic)* 玩家设计的非官方任务追踪应用。再也不会错过双倍经验任务——实时任务追踪、深潜信息、BOSCO主题推送通知，一应俱全。

---

## ✨ 主要功能

- **实时任务追踪** — 任务轮换每30分钟更新一次。双倍经验及黄金热潮任务以金色边框高亮显示并置顶。
- **深潜 & 精英深潜** — 提供各阶段主要目标、次要目标、生物群系及异常信息的完整详情。
- **Trivia 知识系统** — 点击任意生物群系、任务类型、增益或警告徽章，即可查看详细介绍和攻略建议。
- **BOSCO 推送通知** — 双倍经验任务出现时立即收到通知。可自定义提醒的星期、时间和任务类型。*(仅限 Android)*
- **离线缓存** — 即使没有网络连接，也能显示最后获取的数据。
- **三语言支持** — 한국어 · English · 中文

---

## 📱 平台支持

| 平台 | 支持情况 | 备注 |
|---|---|---|
| Android | ✅ | 支持全部功能，包括推送通知 |
| Web PWA | ✅ | 不支持推送通知（浏览器限制） |
| iOS | ❌ | 因 App Store 注册费用问题暂不支持 |

---

## 🔔 推送通知 *(仅限 Android)*

当双倍经验任务出现时，BOSCO 会亲自通知您。

- 自定义提醒的**星期**和**时间**
- 可排除不希望收到通知的任务类型（例如：护送任务）
- 即使应用关闭也能正常工作
- 以您选择的语言发送充满 BOSCO 风格的消息

*Web PWA 版本因浏览器限制不支持推送通知。*

---

## 🙏 特别鸣谢

本项目的实现离不开 **[rolfosian](https://github.com/rolfosian)** 的杰출贡献。

- 所有实时任务数据均来源于 **[doublexp.net](https://doublexp.net)**。
- **数据政策**: 为避免对原始服务器造成负担（防止滥用），GitHub Actions 工作流每日 00:05 UTC 仅获取一次数据，并将其缓存为本仓库中的 JSON。应用仅读取缓存的 JSON，不会直接访问 doublexp.net。
- 衷心感谢 `rolfosian` 为社区提供数据抓取工作，以及 **[Deep Rock Galactic Wiki](https://deeprockgalactic.wiki.gg/)** 社区提供高质量的游戏资产。**岩石与泥土！** ⛏️

---

## 👨‍💻 开发者

<table>
  <tr>
    <td align="center" width="100">
      <a href="https://steamcommunity.com/id/VonVon93/">
        <img src="https://shared.fastly.steamstatic.com/community_assets/images/items/3331000/4ef70f99c425ae03163495f923c5d452f83ba978.gif"
             width="80" alt="Pinyo Steam Profile"/>
      </a>
    </td>
    <td valign="middle">
      <b>Pinyo</b><br/>
      <a href="https://steamcommunity.com/id/VonVon93/">🎮 Steam 个人资料</a><br/>
      <sub>欢迎通过 GitHub Issues 提交错误报告和反馈。</sub>
    </td>
  </tr>
</table>

---

## 🔨 从源码构建

如果您想自行构建并安装 APK，请按照以下步骤操作。

### 前置要求

| 工具 | 所需版本 | 安装指南 |
|------|---------|---------|
| Flutter SDK | **3.41.x** (Dart ≥ 3.11.0) | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Android Studio | 最新稳定版 | [developer.android.com](https://developer.android.com/studio) |
| Android SDK | API 36（通过 SDK Manager 安装） | 包含在 Android Studio 中 |
| Java (JDK) | **17** | 已包含在 Android Studio 中 |
| Git | 任意最新版本 | [git-scm.com](https://git-scm.com/) |

> **提示**: Gradle 8.14、AGP 8.11.1 和 Kotlin 2.2.20 已在项目中配置，首次构建时会自动下载。

### 1. 验证环境

```bash
flutter doctor
```

确保以下项目**无 ❌ 错误**：
- `Flutter` — stable 频道, 3.41.x
- `Android toolchain` — Android SDK API 36
- `Android Studio` — 已安装 Dart、Flutter 插件

### 2. 克隆并安装依赖

```bash
git clone https://github.com/SongMalkang/DRG_MissionTracker_Mobile.git
cd DRG_MissionTracker_Mobile
flutter pub get
```

### 3. 构建 APK

**Debug 构建**（用于测试）：
```bash
flutter build apk --debug
```

**Release 构建**（已优化，体积更小）：
```bash
flutter build apk --release
```

> ⚠️ Release 构建启用了 `minifyEnabled` 和 `shrinkResources`。如遇资源缺失错误，请检查 `android/app/proguard-rules.pro`。

### 4. APK 输出位置

| 构建类型 | 输出路径 |
|---------|---------|
| Debug | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release | `build/app/outputs/flutter-apk/app-release.apk` |

### 5. 安装到设备

```bash
# 通过 ADB 安装（需启用 USB 调试）
flutter install

# 或手动将 APK 文件传输到设备
```

### 构建 Web (PWA)

```bash
flutter build web
# 输出: build/web/
```

### 故障排除

| 问题 | 解决方案 |
|------|---------|
| `Gradle build failed` | 执行 `cd android && ./gradlew clean` 后重试 |
| `SDK version mismatch` | 打开 Android Studio → SDK Manager → 安装 API 36 |
| `flutter doctor` 显示 Java 错误 | 确保 `JAVA_HOME` 指向 JDK 17 |
| `Kotlin version conflict` | 删除 `.gradle` 缓存: `rm -rf ~/.gradle/caches` |

---

## ⚖️ 免责声明

1. **零收益与非商业性**: 这是一个**完全非营利性的粉丝项目**，不产生任何收益。应用内不含广告、不含应用内购买，也不含任何付费功能。
2. **版权声明**: *深岩银河 (Deep Rock Galactic)* 的所有游戏资产（图像、图标、音效等）的版权均归 **Ghost Ship Games ApS** 及 **Coffee Stain Publishing** 所有。这些资产是在权利持有者的单独许可下使用的，**不在** MIT 许可证范围内。未经 Ghost Ship Games 明确许可，禁止重新分发这些资产。
3. **无官方关联**: 本应用与 Ghost Ship Games 没有任何官方关联，仅作为社区辅助工具使用。

---

## 📄 许可证

本项目的**源代码**使用 [MIT 许可证](LICENSE)。

游戏资产（图像、图标、音效等）**不在**此许可证范围内，仍归 Ghost Ship Games ApS / Coffee Stain Publishing 所有。详情请参阅 [LICENSE](LICENSE) 文件和 [ASSETS.md](ASSETS.md) 资产清单。
