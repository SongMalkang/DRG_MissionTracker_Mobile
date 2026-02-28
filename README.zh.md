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

本项目的实现离不开 **[rolfosian](https://github.com/rolfosian)** 的杰出贡献。

- 所有实时任务数据均来源于 **[doublexp.net](https://doublexp.net)**。
- **数据政策**: 为避免对原始服务器造成负担（防止滥用），本应用每日 00:05 UTC 仅更新一次数据，并使用本仓库中的缓存 JSON。应用不会直接访问 doublexp.net。
- 衷心感谢 `rolfosian` 为社区提供数据抓取与分享工作。**岩石与泥土！** ⛏️

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

## ⚖️ 免责声明

1. **非商业项目**: 这是一个非营利性的粉丝项目。
2. **版权声明**: *深岩银河* 的所有游戏资产、图像及角色的版权归 **Ghost Ship Games** 及 **Coffee Stain Publishing** 所有。
3. **无官方关联**: 本应用与 Ghost Ship Games 没有任何官方关联，仅作为官方服务的辅助工具使用。

---

## 📄 许可证

本项目使用 [MIT 许可证](LICENSE)。
