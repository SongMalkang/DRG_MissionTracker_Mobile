"""Deep Dive JSON 게시 시점 확인 (1회성 스크립트)

다음 목요일 11:00 UTC(KST 20:00) 직전에 실행하면,
doublexp.net이 새 DD JSON을 언제 게시하는지 확인할 수 있다.

사용법: python scripts/check_dd_availability.py
종료:   Ctrl+C

HEAD 요청만 사용하며, 200 감지 시 GET으로 1회 검증.
"""

import requests
from datetime import datetime, timedelta, timezone
import time

# ── 다음 리셋 목요일 계산 ──
now = datetime.now(timezone.utc)
days_since = (now.weekday() - 3) % 7
thursday = (now - timedelta(days=days_since)).replace(
    hour=11, minute=0, second=0, microsecond=0
)
if now >= thursday:
    thursday += timedelta(days=7)

date_str = thursday.strftime('%Y-%m-%d')
url = f"https://doublexp.net/static/json/DD_{date_str}T11-00-00Z.json"

print(f"대상 URL: {url}")
print(f"대상 시각: {date_str} 11:00 UTC (KST 20:00)")
print(f"현재 시각: {now.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"{'─' * 50}")


# ── 적응형 폴링 간격 ──
def get_interval(remaining_sec: float) -> int:
    """리셋까지 남은 시간에 따라 폴링 간격 결정."""
    if remaining_sec > 3600:      # 1시간 이상
        return 300                # 5분
    elif remaining_sec > 600:     # 10분 이상
        return 60                 # 1분
    elif remaining_sec > 0:       # 10분 이내
        return 15                 # 15초
    else:                         # 리셋 이후
        return 10                 # 10초


def format_remaining(sec: float) -> str:
    """남은/경과 시간을 읽기 좋게 포맷."""
    sign = "-" if sec > 0 else "+"
    s = abs(int(sec))
    h, m, sc = s // 3600, (s % 3600) // 60, s % 60
    return f"{sign}{h}h {m:02d}m {sc:02d}s"


start_time = datetime.now(timezone.utc)
interval = get_interval((thursday - start_time).total_seconds())
print(f"폴링 간격: {interval}초 (리셋 근접 시 자동 단축)\n")

check_count = 0
while True:
    check_count += 1
    t = datetime.now(timezone.utc)
    remaining = (thursday - t).total_seconds()
    elapsed = (t - start_time).total_seconds()
    remaining_str = format_remaining(remaining)
    elapsed_str = format_remaining(-elapsed)  # 항상 +

    try:
        res = requests.head(url, timeout=10)
        status = res.status_code
        size = res.headers.get('Content-Length', '?')
        symbol = "✅" if status == 200 else "⏳"
        print(
            f"{symbol} [{t.strftime('%H:%M:%S')} UTC] "
            f"#{check_count:<4d} → {status}  "
            f"(size: {size})  "
            f"리셋{remaining_str}  경과{elapsed_str}"
        )

        if status == 200:
            # GET으로 실제 데이터 검증
            print(f"\n{'─' * 50}")
            print(f"🔍 GET 요청으로 데이터 검증 중...")
            data = requests.get(url, timeout=15).json()
            dd = data.get("Deep Dives", {})
            normal = dd.get("Deep Dive Normal", {})
            elite = dd.get("Deep Dive Elite", {})
            print(f"   Normal: {normal.get('CodeName', '?')} ({normal.get('Biome', '?')})")
            print(f"   Elite:  {elite.get('CodeName', '?')} ({elite.get('Biome', '?')})")
            print(f"\n🎯 게시 확인! {t.strftime('%Y-%m-%d %H:%M:%S')} UTC")
            print(f"   리셋(11:00 UTC) 대비: {remaining_str}")
            print(f"   총 대기 시간: {elapsed_str}")
            print("\a")  # 터미널 벨 알림
            break

    except requests.exceptions.RequestException as e:
        print(
            f"⚠️ [{t.strftime('%H:%M:%S')} UTC] "
            f"#{check_count:<4d} → 오류: {e}  "
            f"리셋{remaining_str}"
        )

    # 다음 체크 전 간격 재계산
    interval = get_interval(remaining)
    time.sleep(interval)
