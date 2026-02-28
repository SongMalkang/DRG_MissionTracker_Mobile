# ⛏️ Bosco Terminal

[ **English** | [한국어](./README.ko.md) | [中文](./README.zh.md) ]

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![CI](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml)

**Bosco Terminal** is an unofficial companion app for *Deep Rock Galactic (DRG)*. Never miss a Double XP mission again — get real-time mission tracking, Deep Dive info, and BOSCO-themed push notifications, all in one place.

---

## ✨ Features

- **Real-Time Mission Tracker** — Mission rotation refreshes every 30 minutes. Double XP and Gold Rush missions are highlighted with a golden border and pinned to the top.
- **Deep Dive & Elite Deep Dive** — Full stage-by-stage breakdown including primary objectives, secondary objectives, biome, and anomaly info.
- **Trivia System** — Tap any biome, mission type, buff, or warning badge for detailed tips and descriptions.
- **BOSCO Push Notifications** — Get alerted when Double XP missions appear. Customize which days, time, and mission types trigger notifications. *(Android only)*
- **Offline Cache** — Displays the last fetched data even without a network connection.
- **3 Languages** — Korean (한국어) · English · Chinese (中文)

---

## 📱 Platform Support

| Platform | Support | Notes |
|---|---|---|
| Android | ✅ | Full support including Push Notifications |
| Web PWA | ✅ | Push Notifications unavailable (browser limitation) |
| iOS | ❌ | Not available due to App Store registration costs |

---

## 🔔 Push Notifications *(Android only)*

Bosco will personally alert you when a Double XP mission appears.

- Set your preferred **days of the week** and **time** for alerts
- Filter out mission types you don't want to be notified about (e.g. Escort Duty)
- Works even when the app is closed
- Delivered in your selected language with BOSCO-flavored messages

*Push notifications are not supported on the Web PWA version due to browser limitations.*

---

## 🙏 Special Thanks

This project would not be possible without **[rolfosian](https://github.com/rolfosian)**.

- All real-time mission data originates from **[doublexp.net](https://doublexp.net)**.
- **Data Policy**: To avoid server overload (leeching), this app fetches data once per day at 00:05 UTC and serves it from this repository's cached JSON. The app never contacts doublexp.net directly.
- Huge respect to `rolfosian` for scraping and sharing Hoxxes' data with the community. **Rock and Stone!** ⛏️

---

## 👨‍💻 Developer

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
      <a href="https://steamcommunity.com/id/VonVon93/">🎮 Steam Profile</a><br/>
      <sub>Bug reports and feedback are welcome via GitHub Issues.</sub>
    </td>
  </tr>
</table>

---

## ⚖️ Disclaimer

1. **Non-Commercial**: This is a non-profit fan project.
2. **Intellectual Property**: All game assets, images, and characters are property of **Ghost Ship Games**.
3. **No Affiliation**: This app is not affiliated with Ghost Ship Games and is only used as a supplementary tool for official services.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
