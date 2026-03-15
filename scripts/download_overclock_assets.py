"""
DRG Overclock Asset Downloader
위키에서 무기/오버클럭 이미지를 다운로드하고 webp로 변환

의존성: pip install requests beautifulsoup4 Pillow
실행: python scripts/download_overclock_assets.py
"""

import os
import re
import time
from pathlib import Path

try:
    import requests
    from bs4 import BeautifulSoup
    from PIL import Image
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install with: pip install requests beautifulsoup4 Pillow")
    exit(1)

# ─── 설정 ───────────────────────────────────────────────
BASE_URL = "https://deeprockgalactic.wiki.gg"
WIKI_PAGE = f"{BASE_URL}/wiki/Weapon_Overclocks"
PROJECT_ROOT = Path(__file__).parent.parent  # scripts/ 상위 = 프로젝트 루트

OUTPUT_DIRS = {
    "weapons": PROJECT_ROOT / "assets" / "images" / "weapons",
    "overclocks": PROJECT_ROOT / "assets" / "images" / "overclocks",
    "frames": PROJECT_ROOT / "assets" / "images" / "overclocks" / "frames",
}

HEADERS = {
    "User-Agent": "DRG-MissionTracker-AssetDownloader/1.0 (fan project)"
}

# ─── 무기 ID → 위키 이미지 파일명 매핑 (24개) ──────────
WEAPON_IMAGES = {
    # Driller Primary
    "crspr_flamethrower": "CRSPR_Flamethrower",
    "cryo_cannon": "Cryo_Cannon",
    "corrosive_sludge_pump": "Corrosive_Sludge_Pump",
    # Driller Secondary
    "subata_120": "Subata_120",
    "experimental_plasma_charger": "Experimental_Plasma_Charger",
    "colette_wave_cooker": "Colette_Wave_Cooker",
    # Engineer Primary
    "warthog_auto_210": "%22Warthog%22_Auto_210",
    "stubby_voltaic_smg": "%22Stubby%22_Voltaic_SMG",
    "lok1_smart_rifle": "LOK-1_Smart_Rifle",
    # Engineer Secondary
    "deepcore_40mm_pgl": "Deepcore_40mm_PGL",
    "breach_cutter": "Breach_Cutter",
    "shard_diffractor": "Shard_Diffractor",
    # Gunner Primary
    "lead_storm_minigun": "%22Lead_Storm%22_Powered_Minigun",
    "thunderhead_autocannon": "%22Thunderhead%22_Heavy_Autocannon",
    "hurricane_rocket_system": "%22Hurricane%22_Guided_Rocket_System",
    # Gunner Secondary
    "bulldog_revolver": "%22Bulldog%22_Heavy_Revolver",
    "brt7_burst_fire": "BRT7_Burst_Fire_Gun",
    "armskore_coil_gun": "ArmsKore_Coil_Gun",
    # Scout Primary
    "deepcore_gk2": "Deepcore_GK2",
    "m1000_classic": "M1000_Classic",
    "drak25_plasma_carbine": "DRAK-25_Plasma_Carbine",
    # Scout Secondary
    "jury_rigged_boomstick": "Jury-Rigged_Boomstick",
    "zhukov_nuk17": "Zhukov_NUK17",
    "nishanka_boltshark_x80": "Nishanka_Boltshark_X-80",
}

# ─── OC 프레임 이미지 ──────────────────────────────────
FRAME_IMAGES = {
    "frame_clean": "Frame_Overclock_Clean.png",
    "frame_balanced": "Frame_Overclock_Balanced.png",
    "frame_unstable": "Frame_Overclock_Unstable.png",
}

# ─── 통계 ──────────────────────────────────────────────
stats = {"success": 0, "failed": 0, "skipped": 0, "failures": []}


def to_snake_case(text):
    """CamelCase → snake_case (AssetHelper._toSnakeCase와 동일)"""
    s = re.sub(r'([a-z])([A-Z])', r'\1_\2', text)
    return s.lower().replace(' ', '_').replace('-', '_').replace("'", "")


def download_image(url, output_path, max_retries=3):
    """이미지 다운로드 (재시도 포함)"""
    if output_path.exists():
        print(f"  [SKIP] {output_path.name} (already exists)")
        stats["skipped"] += 1
        return True

    for attempt in range(max_retries):
        try:
            resp = requests.get(url, headers=HEADERS, timeout=30)
            if resp.status_code == 200:
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_bytes(resp.content)
                print(f"  [OK] {output_path.name}")
                stats["success"] += 1
                return True
            elif resp.status_code == 404:
                print(f"  [404] {url}")
                stats["failed"] += 1
                stats["failures"].append(f"404: {url}")
                return False
            else:
                print(f"  [HTTP {resp.status_code}] {url} (attempt {attempt + 1})")
        except requests.RequestException as e:
            print(f"  [ERR] {e} (attempt {attempt + 1})")

        if attempt < max_retries - 1:
            time.sleep(2 ** attempt)  # 지수 백오프

    stats["failed"] += 1
    stats["failures"].append(f"Failed after {max_retries} attempts: {url}")
    return False


def convert_to_webp(png_path, quality=85):
    """PNG → WebP 변환"""
    webp_path = png_path.with_suffix('.webp')
    try:
        with Image.open(png_path) as img:
            img = img.convert('RGBA')
            img.save(webp_path, 'WEBP', quality=quality)
        png_path.unlink()  # 원본 PNG 삭제
        print(f"  [WEBP] {webp_path.name}")
        return webp_path
    except Exception as e:
        print(f"  [WARN] WebP conversion failed for {png_path.name}: {e}")
        return png_path  # PNG 유지


def download_weapons():
    """무기 이미지 다운로드 (24개)"""
    print("\n=== Downloading Weapon Images ===")
    output_dir = OUTPUT_DIRS["weapons"]
    output_dir.mkdir(parents=True, exist_ok=True)

    for weapon_id, wiki_name in WEAPON_IMAGES.items():
        webp_path = output_dir / f"{weapon_id}.webp"
        if webp_path.exists():
            print(f"  [SKIP] {webp_path.name} (already exists)")
            stats["skipped"] += 1
            continue

        # 위키 weapon 페이지에서 이미지 URL 추출 시도
        png_path = output_dir / f"{weapon_id}.png"

        # 썸네일 URL 패턴으로 시도
        thumb_url = f"{BASE_URL}/images/thumb/{wiki_name}.png/300px-{wiki_name}.png"
        if not download_image(thumb_url, png_path):
            # 원본 URL 폴백
            original_url = f"{BASE_URL}/images/{wiki_name}.png"
            if not download_image(original_url, png_path):
                # 개별 무기 위키 페이지에서 이미지 검색
                print(f"  [INFO] Trying to scrape image for {weapon_id}...")
                try:
                    weapon_page_url = f"{BASE_URL}/wiki/{wiki_name}"
                    resp = requests.get(weapon_page_url, headers=HEADERS, timeout=30)
                    if resp.status_code == 200:
                        soup = BeautifulSoup(resp.text, 'html.parser')
                        infobox_img = soup.select_one('.infobox img, .portable-infobox img')
                        if infobox_img and infobox_img.get('src'):
                            img_url = infobox_img['src']
                            if not img_url.startswith('http'):
                                img_url = BASE_URL + img_url
                            download_image(img_url, png_path)
                except Exception as e:
                    print(f"  [ERR] Scrape failed for {weapon_id}: {e}")

        if png_path.exists():
            convert_to_webp(png_path)


def scrape_overclock_icons():
    """위키 OC 페이지에서 아이콘 이미지 추출 및 다운로드"""
    print("\n=== Scraping Overclock Icons ===")
    output_dir = OUTPUT_DIRS["overclocks"]
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        resp = requests.get(WIKI_PAGE, headers=HEADERS, timeout=30)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"  [ERR] Failed to fetch OC page: {e}")
        return

    soup = BeautifulSoup(resp.text, 'html.parser')

    # 모든 OC 관련 아이콘 이미지 추출
    icon_files = set()
    for img in soup.find_all('img'):
        src = img.get('src', '')
        alt = img.get('alt', '')

        # Icon_Upgrade_* 또는 Icon_Overclock_* 패턴 매칭
        filename = None
        if 'Icon_Upgrade_' in src or 'Icon_Overclock_' in src:
            # src에서 파일명 추출
            match = re.search(r'(Icon_(?:Upgrade|Overclock)_[^/]+\.png)', src)
            if match:
                filename = match.group(1)
        elif 'Icon_Upgrade_' in alt or 'Icon_Overclock_' in alt:
            filename = alt if alt.endswith('.png') else f"{alt}.png"

        if filename:
            # 썸네일 크기 접두사 제거 (예: "64px-Icon_Upgrade_Ammo.png" → "Icon_Upgrade_Ammo.png")
            filename = re.sub(r'^\d+px-', '', filename)
            icon_files.add(filename)

    print(f"  Found {len(icon_files)} unique OC icons")

    for filename in sorted(icon_files):
        snake_name = to_snake_case(filename.replace('.png', ''))
        webp_path = output_dir / f"{snake_name}.webp"
        if webp_path.exists():
            print(f"  [SKIP] {webp_path.name}")
            stats["skipped"] += 1
            continue

        png_path = output_dir / f"{snake_name}.png"

        # 썸네일 URL
        thumb_url = f"{BASE_URL}/images/thumb/{filename}/64px-{filename}"
        if not download_image(thumb_url, png_path):
            # 원본 URL 폴백
            original_url = f"{BASE_URL}/images/{filename}"
            download_image(original_url, png_path)

        if png_path.exists():
            convert_to_webp(png_path)


def download_frames():
    """OC 프레임(등급) 이미지 다운로드"""
    print("\n=== Downloading Frame Images ===")
    output_dir = OUTPUT_DIRS["frames"]
    output_dir.mkdir(parents=True, exist_ok=True)

    for frame_id, filename in FRAME_IMAGES.items():
        webp_path = output_dir / f"{frame_id}.webp"
        if webp_path.exists():
            print(f"  [SKIP] {webp_path.name}")
            stats["skipped"] += 1
            continue

        png_path = output_dir / f"{frame_id}.png"

        thumb_url = f"{BASE_URL}/images/thumb/{filename}/100px-{filename}"
        if not download_image(thumb_url, png_path):
            original_url = f"{BASE_URL}/images/{filename}"
            download_image(original_url, png_path)

        if png_path.exists():
            convert_to_webp(png_path)


def print_report():
    """최종 결과 리포트"""
    print("\n" + "=" * 50)
    print("DOWNLOAD REPORT")
    print("=" * 50)
    print(f"  Success:  {stats['success']}")
    print(f"  Skipped:  {stats['skipped']}")
    print(f"  Failed:   {stats['failed']}")

    if stats["failures"]:
        print("\n  Failures:")
        for f in stats["failures"]:
            print(f"    - {f}")

    # 총 파일 크기 계산
    total_size = 0
    for dir_path in OUTPUT_DIRS.values():
        if dir_path.exists():
            for file in dir_path.iterdir():
                if file.is_file():
                    total_size += file.stat().st_size
    print(f"\n  Total asset size: {total_size / 1024:.1f} KB")
    print("=" * 50)


def main():
    print("DRG Overclock Asset Downloader")
    print(f"Project root: {PROJECT_ROOT}")

    # 출력 디렉토리 생성
    for dir_path in OUTPUT_DIRS.values():
        dir_path.mkdir(parents=True, exist_ok=True)

    download_weapons()
    scrape_overclock_icons()
    download_frames()
    print_report()


if __name__ == "__main__":
    main()
