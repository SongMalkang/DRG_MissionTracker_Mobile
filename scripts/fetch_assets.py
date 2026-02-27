#!/usr/bin/env python3
"""
scripts/fetch_assets.py
DRG Bosco Terminal — 게임 에셋 자동 다운로더

소스: Deep Rock Galactic Wiki (deeprockgalactic.fandom.com)
      MediaWiki API를 통해 이미지를 검색 후 다운로드합니다.

사용법:
  python scripts/fetch_assets.py                          # 전체 다운로드
  python scripts/fetch_assets.py --dry-run               # URL만 확인 (다운로드 안 함)
  python scripts/fetch_assets.py --missing               # 누락된 파일만 다운로드
  python scripts/fetch_assets.py --category biomes       # 특정 카테고리만
  python scripts/fetch_assets.py --category missions
  python scripts/fetch_assets.py --category mutators
  python scripts/fetch_assets.py --category warnings
"""

import io
import re
import sys
import time
import argparse
import requests
from pathlib import Path

# Windows 터미널 UTF-8 출력 강제
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ── 설정 ─────────────────────────────────────────────────────────────────────
WIKI_API = "https://deeprockgalactic.fandom.com/api.php"
REQUEST_DELAY = 0.6   # API 요청 간격 (초) — 과부하 방지, 너무 낮추지 마세요

SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "DRG-BoscoTerminal-AssetFetcher/1.0 (fan app, non-commercial)",
    "Accept": "application/json",
})

# 프로젝트 루트 기준 출력 경로
BASE_DIR = Path(__file__).parent.parent
OUTPUT_DIRS = {
    "biomes":   BASE_DIR / "assets" / "images" / "biomes",
    "missions": BASE_DIR / "assets" / "images" / "missions",
    "mutators": BASE_DIR / "assets" / "icons"  / "mutators",
    "warnings": BASE_DIR / "assets" / "icons"  / "warnings",
}

# ── 이미지 목록 (strings.dart 기준) ──────────────────────────────────────────
BIOMES: list[str] = [
    "Azure Weald",
    "Crystalline Caverns",
    "Dense Biozone",
    "Fungus Bogs",
    "Glacial Strata",
    "Hollow Bough",
    "Magma Core",
    "Radioactive Exclusion Zone",
    "Salt Pits",
    "Sandblasted Corridors",
    "Ossuary Depths",
]

MISSIONS: list[str] = [
    "Mining Expedition",
    "Egg Hunt",
    "On-Site Refining",
    "Point Extraction",
    "Salvage Operation",
    "Escort Duty",
    "Elimination",
    "Industrial Sabotage",
    "Deep Scan",
    "Heavy Excavation",
]

MUTATORS: list[str] = [
    "Double XP",
    "Gold Rush",
    "Mineral Mania",
    "Low Gravity",
    "Rich Atmosphere",
    "Critical Weakness",
    "Golden Bugs",
    "Volatile Guts",
    "Shield Disruption",
]

WARNINGS: list[str] = [
    "Mactera Plague",
    "Cave Leech Cluster",
    "Parasites",
    "Exploder Infestation",
    "Lethal Enemies",
    "Low Oxygen",
    "Haunted Cave",
    "Elite Threat",
    "Swarmageddon",
    "Rival Presence",
    "Lithophage Outbreak",
]

# ── Wiki 파일명 직접 지정 ─────────────────────────────────────────────────────
# 퍼지 검색보다 정확한 파일명을 알고 있을 때 사용합니다.
# 검색 전에 이 파일명으로 먼저 시도합니다.
DIRECT_WIKI_FILES: dict[str, str] = {
    # Mission icons (API 검증 완료)
    "Egg Hunt":                  "Egg Hunt icon u7.png",
    "On-Site Refining":          "Refining icon.png",
    "Salvage Operation":         "Salvage icon.png",
    "Escort Duty":               "Escort icon.png",
    "Industrial Sabotage":       "Sabotage icon.png",
    # 아래 항목은 wiki에 파일 없음 → MANUAL_URLS에 직접 추가하거나 나중에 수동 저장
    # "Deep Scan":               ???   (위키 미등록, Season 3+ 신규 미션)
    # "Heavy Excavation":        ???   (위키 미등록, Season 5+ 신규 미션)
    # "Ossuary Depths":          ???   (위키 미등록, Season 5 바이옴)
}

# ── 수동 지정 URL ─────────────────────────────────────────────────────────────
# DIRECT_WIKI_FILES로도 못 찾을 때 URL을 직접 지정합니다.
# Wiki 파일 URL 확인: https://deeprockgalactic.fandom.com/wiki/Special:FilePath/파일명.png
MANUAL_URLS: dict[str, str] = {
    # 예시:
    # "Ossuary Depths": "https://static.wikia.nocookie.net/.../OssuaryDepths.jpg",
}

# ── 유틸리티 ──────────────────────────────────────────────────────────────────
def to_snake(name: str) -> str:
    """'Azure Weald' → 'azure_weald'  /  'On-Site Refining' → 'on_site_refining'"""
    s = name.strip().lower()
    s = re.sub(r"[\s\-]+", "_", s)
    s = re.sub(r"[^\w]", "", s)
    return s


def wiki_search(query: str, limit: int = 8) -> list[str]:
    """
    DRG Wiki File 네임스페이스(ns=6)에서 이미지 파일명 목록을 반환합니다.
    반환값: ["FileName.png", "AnotherFile.jpg", ...]
    """
    params = {
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srnamespace": "6",
        "srlimit": str(limit),
        "format": "json",
    }
    try:
        r = SESSION.get(WIKI_API, params=params, timeout=15)
        r.raise_for_status()
        results = r.json().get("query", {}).get("search", [])
        return [x["title"].removeprefix("File:") for x in results]
    except Exception as e:
        print(f"    ⚠ 검색 오류: {e}")
        return []


def wiki_file_url(filename: str) -> str | None:
    """
    파일명 → wikia CDN 실제 다운로드 URL
    예: "SaltPits.jpg" → "https://static.wikia.nocookie.net/..."
    """
    params = {
        "action": "query",
        "titles": f"File:{filename}",
        "prop": "imageinfo",
        "iiprop": "url",
        "format": "json",
    }
    try:
        r = SESSION.get(WIKI_API, params=params, timeout=15)
        r.raise_for_status()
        pages = r.json().get("query", {}).get("pages", {})
        for page in pages.values():
            info = page.get("imageinfo", [])
            if info:
                return info[0].get("url")
    except Exception as e:
        print(f"    ⚠ URL 조회 오류: {e}")
    return None


def pick_best(
    candidates: list[str],
    name: str,
    prefer_ext: tuple[str, ...],
    exclude_keywords: tuple[str, ...] = ("icon", "thumbnail", "thumb", "logo"),
    require_keywords: tuple[str, ...] = (),
) -> str | None:
    """
    후보 파일 목록에서 가장 관련성 높은 파일을 선택합니다.
    1) require_keywords 중 하나라도 포함된 것 우선
    2) 이름이 포함된 것 우선
    3) 선호 확장자 우선
    """
    name_lower = name.lower()
    pool = candidates[:]

    # 필수 키워드가 있으면 필터
    if require_keywords:
        filtered = [f for f in pool if any(kw in f.lower() for kw in require_keywords)]
        if filtered:
            pool = filtered

    # 이름이 포함된 것 우선
    name_matched = [f for f in pool if name_lower in f.lower().replace("_", " ")]
    if name_matched:
        pool = name_matched

    # 선호 확장자 우선 적용
    for ext in prefer_ext:
        for f in pool:
            if f.lower().split("?")[0].endswith(ext):
                return f

    return pool[0] if pool else None


def download_file(url: str, dest: Path) -> bool:
    """URL에서 dest 경로로 바이너리 다운로드"""
    try:
        r = SESSION.get(url, timeout=30, stream=True)
        r.raise_for_status()
        dest.parent.mkdir(parents=True, exist_ok=True)
        with open(dest, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        size_kb = dest.stat().st_size // 1024
        print(f"    ✓ 저장: {dest.relative_to(BASE_DIR)}  ({size_kb} KB)")
        return True
    except Exception as e:
        print(f"    ✗ 다운로드 실패: {e}")
        return False


# ── 카테고리별 다운로드 전략 ──────────────────────────────────────────────────
CATEGORY_CONFIG: dict[str, dict] = {
    "biomes": {
        "names": BIOMES,
        # 바이옴 배경 이미지: 로딩화면 스타일 고해상도 이미지 원함
        "search_suffixes": ["{name}", "{name} biome", "{name} cave"],
        "prefer_ext": (".jpg", ".png", ".webp"),
        "require_keywords": (),           # 특별한 키워드 필터 없음
        "exclude_icon": False,
    },
    "missions": {
        "names": MISSIONS,
        # 미션 타입 아이콘
        "search_suffixes": ["{name}", "{name} mission", "{name} icon"],
        "prefer_ext": (".png", ".webp", ".jpg"),
        "require_keywords": (),
        "exclude_icon": False,
    },
    "mutators": {
        "names": MUTATORS,
        # 변이 아이콘 — 작은 PNG 아이콘 선호
        "search_suffixes": ["{name}", "{name} mutator", "{name} icon"],
        "prefer_ext": (".png", ".webp"),
        "require_keywords": (),
        "exclude_icon": False,
    },
    "warnings": {
        "names": WARNINGS,
        # 경고 아이콘
        "search_suffixes": ["{name}", "{name} warning", "{name} anomaly"],
        "prefer_ext": (".png", ".webp"),
        "require_keywords": (),
        "exclude_icon": False,
    },
}


def fetch_category(
    category: str,
    dry_run: bool = False,
    missing_only: bool = False,
) -> dict[str, list[str]]:
    """
    한 카테고리의 모든 이미지를 순서대로 다운로드합니다.
    반환: {"ok": [...], "fail": [...], "skip": [...]}
    """
    cfg = CATEGORY_CONFIG[category]
    names: list[str] = cfg["names"]
    out_dir: Path = OUTPUT_DIRS[category]
    out_dir.mkdir(parents=True, exist_ok=True)

    stats: dict[str, list[str]] = {"ok": [], "fail": [], "skip": []}

    for name in names:
        snake = to_snake(name)
        print(f"\n  [{name}]")

        # ① 수동 URL이 있으면 즉시 사용 (최우선)
        if name in MANUAL_URLS:
            url = MANUAL_URLS[name]
            ext = Path(url.split("?")[0]).suffix or ".png"
            dest = out_dir / f"{snake}{ext}"
            if dry_run:
                print(f"    [dry-run] MANUAL: {url}")
                stats["ok"].append(name)
            elif download_file(url, dest):
                stats["ok"].append(name)
            else:
                stats["fail"].append(name)
            continue

        # ② missing_only 모드: 이미 파일이 있으면 스킵
        if missing_only:
            existing = list(out_dir.glob(f"{snake}.*"))
            if existing:
                print(f"    → 스킵 (기존 파일: {existing[0].name})")
                stats["skip"].append(name)
                continue

        # ③ DIRECT_WIKI_FILES: 알려진 파일명 직접 조회 (검색보다 정확)
        chosen_file: str | None = None
        cached_url: str | None = None   # 직접 조회 시 URL 재사용

        if name in DIRECT_WIKI_FILES:
            direct_name = DIRECT_WIKI_FILES[name]
            cached_url = wiki_file_url(direct_name)
            time.sleep(REQUEST_DELAY)
            if cached_url:
                chosen_file = direct_name
                print(f"    → 직접 지정: {chosen_file}")
            else:
                print(f"    ⚠ 직접 지정 파일 없음 ({direct_name}), 검색으로 전환...")

        # ④ Wiki 검색 (직접 지정 실패 시 폴백)
        if not chosen_file:
            for suffix_tmpl in cfg["search_suffixes"]:
                query = suffix_tmpl.format(name=name)
                candidates = wiki_search(query)
                time.sleep(REQUEST_DELAY)

                if candidates:
                    chosen_file = pick_best(
                        candidates,
                        name,
                        prefer_ext=cfg["prefer_ext"],
                        require_keywords=cfg["require_keywords"],
                    )
                    if chosen_file:
                        print(f"    → 검색 결과: {chosen_file}")
                        break

        if not chosen_file:
            print(f"    ✗ 찾기 실패 — MANUAL_URLS 또는 DIRECT_WIKI_FILES에 추가 필요")
            stats["fail"].append(name)
            continue

        # ⑤ CDN URL 획득 (직접 조회 시 재사용, 검색 결과는 신규 조회)
        url = cached_url or wiki_file_url(chosen_file)
        if not cached_url:
            time.sleep(REQUEST_DELAY)

        if not url:
            print(f"    ✗ URL 획득 실패")
            stats["fail"].append(name)
            continue

        # 확장자 추출 (쿼리스트링 제거)
        ext = Path(url.split("?")[0]).suffix or ".png"
        dest = out_dir / f"{snake}{ext}"

        if dry_run:
            print(f"    [dry-run] {url}")
            print(f"           → {dest.relative_to(BASE_DIR)}")
            stats["ok"].append(name)
        else:
            if download_file(url, dest):
                stats["ok"].append(name)
            else:
                stats["fail"].append(name)

    return stats


# ── 결과 리포트 ───────────────────────────────────────────────────────────────
def print_report(all_stats: dict[str, dict[str, list[str]]]) -> None:
    total_ok = total_fail = total_skip = 0
    failed_items: list[tuple[str, str]] = []

    print(f"\n{'='*60}")
    print("  결과 요약")
    print(f"{'='*60}")

    for cat, stats in all_stats.items():
        ok    = len(stats["ok"])
        fail  = len(stats["fail"])
        skip  = len(stats["skip"])
        total_ok   += ok
        total_fail += fail
        total_skip += skip
        print(f"  {cat:12} ✓{ok:3}  ✗{fail:3}  스킵{skip:3}")
        for name in stats["fail"]:
            failed_items.append((cat, name))

    print(f"{'─'*60}")
    print(f"  합계          ✓{total_ok:3}  ✗{total_fail:3}  스킵{total_skip:3}")
    print(f"{'='*60}")

    if failed_items:
        print("\n⚠ 수동 처리가 필요한 항목:")
        print("  아래 파일을 Wiki에서 직접 찾아 MANUAL_URLS에 추가하거나,")
        print("  파일을 직접 다운로드한 후 해당 경로에 저장하세요.\n")
        for cat, name in failed_items:
            snake = to_snake(name)
            out_path = OUTPUT_DIRS[cat] / f"{snake}.png"
            wiki_search_url = (
                "https://deeprockgalactic.fandom.com/wiki/Special:Search"
                f"?query={requests.utils.quote(name)}&scope=internal&contentType=file"
            )
            print(f"  • [{cat}] {name}")
            print(f"      저장 위치: {out_path.relative_to(BASE_DIR)}")
            print(f"      Wiki 검색: {wiki_search_url}")


# ── 진입점 ────────────────────────────────────────────────────────────────────
def main() -> None:
    parser = argparse.ArgumentParser(
        description="DRG Bosco Terminal 에셋 다운로더 — Wiki에서 이미지를 자동으로 수집합니다."
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="실제 다운로드 없이 URL만 확인합니다.",
    )
    parser.add_argument(
        "--missing", action="store_true",
        help="이미 존재하는 파일은 건너뛰고 누락된 것만 다운로드합니다.",
    )
    parser.add_argument(
        "--category",
        choices=list(CATEGORY_CONFIG.keys()),
        help="특정 카테고리만 처리합니다.",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("  DRG Bosco Terminal — 에셋 다운로더")
    print("  소스: deeprockgalactic.fandom.com (MediaWiki API)")
    if args.dry_run:
        print("  모드: DRY-RUN (다운로드 없음)")
    if args.missing:
        print("  모드: MISSING ONLY (누락 파일만)")
    print("=" * 60)

    categories = [args.category] if args.category else list(CATEGORY_CONFIG.keys())
    all_stats: dict[str, dict[str, list[str]]] = {}

    for cat in categories:
        names_count = len(CATEGORY_CONFIG[cat]["names"])
        print(f"\n{'─'*60}")
        print(f"  📁 {cat.upper()} — {names_count}개")
        print(f"{'─'*60}")

        all_stats[cat] = fetch_category(
            cat,
            dry_run=args.dry_run,
            missing_only=args.missing,
        )

    print_report(all_stats)

    if args.dry_run:
        print("\n💡 실제 다운로드하려면 --dry-run 옵션을 제거하고 실행하세요.")


if __name__ == "__main__":
    main()
