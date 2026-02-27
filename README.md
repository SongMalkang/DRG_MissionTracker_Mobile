# ⛏️ Bosco Terminal (Unofficial DRG Mission Tracker)

[ **English** | [한국어](./README.ko.md) | [中文](./README.zh.md) ]

**Bosco Terminal** is an unofficial companion app for *Deep Rock Galactic (DRG)*. It provides real-time mission tracking, Double XP highlights, and Deep Dive information.

## 🙏 Special Thanks

This project would not be possible without the incredible work of **[rolfosian](https://github.com/rolfosian)**.
* All real-time data is sourced from **[doublexp.net](https://doublexp.net)**.
* **Data Policy**: To prevent server overload (leeching), this app fetches data once a day at 00:05 UTC and uses the cached JSON from this repository.
* Deep respect to `rolfosian` for scraping and sharing Hoxxes' data with the community. **Rock and Stone!** ⛏️

## ⚖️ Disclaimer

1. **Non-Commercial**: This is a non-profit fan project.
2. **Intellectual Property**: All game assets, images, and characters are property of **Ghost Ship Games**.
3. **No Affiliation**: This app is not affiliated with Ghost Ship Games and is only used as a supplementary tool for official services.
4. **Donation Usage**: Any support is strictly used for Apple App Store fees ($99/yr) and maintenance.

---
## 🛠️ Tech Stack

* **Frontend**: Flutter (Dart)
* **Data Pipeline**: Python (Data Scraping) + GitHub Actions (Automation)
* **Storage**: Shared Preferences (Local Settings)
* **Architecture**: Modular UI Components
